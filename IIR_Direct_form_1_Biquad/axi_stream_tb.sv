`timescale 1ns / 1 ps

module axi_stream_tb;
  reg clk;
  reg signed [15:0] s_axis_tdata;
  reg rst_n; 
  reg s_axis_tvalid;
  reg m_axis_tready;  // upstream device ready
  wire signed [15:0] m_axis_tdata;
  wire m_axis_tvalid;
  wire s_axis_tready;

  // clk
  always #10 clk = ~clk;  // 50 MHz clk

  // constants for module instantiation
  localparam coeff_width  = 16;
  localparam inout_width  = 16;
  localparam scale_factor = 14;
  localparam b0_int_coeff = 2962;
  localparam b1_int_coeff = 5615;
  localparam b2_int_coeff = 2962;
  localparam a1_int_coeff = -9362;
  localparam a2_int_coeff = 5203;

  // uut instance
  iir_DF1_Biquad_AXIS #(
    .coeff_width(coeff_width),
    .inout_width(inout_width),
    .scale_factor(scale_factor),
    .b0_int_coeff(b0_int_coeff),
    .b1_int_coeff(b1_int_coeff),
    .b2_int_coeff(b2_int_coeff),
    .a1_int_coeff(a1_int_coeff),
    .a2_int_coeff(a2_int_coeff)
  ) uut (
    .clk(clk),
    .rst_n(rst_n),
    .s_axis_tvalid(s_axis_tvalid),
    .s_axis_tdata(s_axis_tdata),
    .m_axis_tready(m_axis_tready),
    .m_axis_tdata(m_axis_tdata),
    .m_axis_tvalid(m_axis_tvalid),
    .s_axis_tready(s_axis_tready)
  );
  
  // variables for tb stimulus
  integer i_impulse_max = 0;
  integer fid;
  integer status;
  integer sample; 
  integer i;
  integer j = 0;

  // global status flags to know which mode I am checking in the testbench
  bit checking_impulse_resp = 1'b0;  
  bit checking_wave_output = 1'b0;
  
  localparam num_samples = 250;
  
  reg signed [15:0] r_wave_sample [num_samples - 1:0];

  // generates an impulse
  task axis_impulse();
    begin
      checking_impulse_resp = 1'b1;
      i_impulse_max = 2**(inout_width-1)-1; // 2^(inout_width-1) because input is signed, so to make max positive number need MSB-1 (sign bit stays 0)
      wait (rst_n == 1'b1)                  // wait for reset release
      wait (clk == 1'b0) wait (clk == 1'b1) // wait for rising edge clk

      if (s_axis_tready == 1'b1)            // if uut is ready to accept data
        begin 
          s_axis_tdata  = i_impulse_max;    // send out impulse
          s_axis_tvalid = 1'b1;
          #20
          s_axis_tvalid = 1'b0;
        end

      #80
      wait (clk == 1'b0) wait (clk == 1'b1) // wait for rising edge clk 
      s_axis_tdata = 0;                     // data goes back to 0
      s_axis_tvalid = 1'b1;
      #20
      s_axis_tvalid = 1'b0;

      repeat(50)  // repeat for 50 samples @ fs = 10 MHz
        begin
          #80
          wait (clk == 1'b0) wait (clk == 1'b1) // wait for rising edge clk
          s_axis_tvalid = 1'b1;                 // valid flag every clock cycle
          #20
          s_axis_tvalid = 1'b0;
        end
      
      checking_impulse_resp = 1'b1;
    end
  endtask

  // file output for impulse response
  initial 
    begin
        wait (checking_impulse_resp == 1'b1) // indicates in the impulse response section of tb
        fid = $fopen("Impulse_response_output.txt","w");     // create or open file
        $display("file opened");
        while (checking_impulse_resp == 1'b1)
          begin 
            wait (m_axis_tvalid == 0) wait (m_axis_tvalid == 1); // wait for rising edge of master tvalid output
            $fdisplay(fid,"%d",m_axis_tdata);                    // write output data to file
          end 
        $fclose(fid);
    end

  // random upstream device tready deassertion
  // output should just stall while module internals continue. 
  // output will update with current output data when the ready is back high, since there is no fifo buffer to hold past unread axi data
  initial
    begin
      wait (checking_wave_output == 1'b1)  // indicates in the waveform output section of tb
      m_axis_tready = 1'b1; // upstream device ready
      #4630
      m_axis_tready = 1'b0;  // after some random time, upstream device is not ready
      #5570
      m_axis_tready = 1'b1;  // upstream device becomes ready again. 
    end 
         
  initial 
    begin
    clk = 1'b0;
    rst_n = 1'b0; 
    s_axis_tdata = 0;
    s_axis_tvalid = 1'b0;
    m_axis_tready = 1'b1; // upstream device ready
    #40
    rst_n = 1'b1;
    #40
    axis_impulse();
    #10000
    rst_n = 1'b0;  // reset to test an input signal
    checking_wave_output = 1'b1;

    // load samples into register
    fid = $fopen("500kHz_sine_wave_with_noise.txt","r");
    for (i = 0; i < num_samples; i = i + 1)
      begin
        status = $fscanf(fid,"%d\n",sample); 
        //$display("%d\n",sample);
        r_wave_sample[i] = 16'(sample);
        //$display("%d index is %d\n",i,r_wave_sample[i]);
      end
    $fclose(fid);
    
    #1000
    rst_n = 1'b1; // release reset
    
    repeat(num_samples)  // 10 MHz sampling
      begin 
        #80
        s_axis_tdata = r_wave_sample[j];
        j = j + 1;
        wait (clk == 1'b0) wait (clk == 1'b1) // wait for rising edge of clock
        s_axis_tvalid = 1'b1;
        #20
        s_axis_tvalid = 1'b0; // tvalid only high for 1 clock cycle
      end
      #50000
      $finish;
    $finish;
    end

endmodule
