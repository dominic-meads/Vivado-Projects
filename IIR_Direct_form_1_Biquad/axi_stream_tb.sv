`timescale 1ns / 1 ps

module axi_stream_tb;
  reg clk;
  reg signed [15:0] r_s_axis_tdata;
  reg rst_n; 
  reg r_s_axis_tvalid;
  wire signed [15:0] m_axis_tdata;
  wire m_axis_tvalid;
  wire m_axis_tready;

  always #10 clk = ~clk;  // 50 MHz clk

  integer fid;
  integer status;
  integer sample; 
  integer i;
  integer j = 0;
  
  localparam num_samples = 1000;
  
  reg signed [15:0] r_wave_sample [num_samples - 1:0];

  iir_DF1_Biquad_AXIS #(
    .a1_int_coeff(-31880),
    .a2_int_coeff(15531),
    .bo_int_coeff(167),
    .b1_int_coeff(-302),
    .b2_int_coeff(167)
  ) uut (
    .clk(clk),
    .rst_n(rst_n),
    .s_axis_tvalid(r_s_axis_tvalid),
    .s_axis_tdata(r_s_axis_tdata),
    .m_axis_tdata(m_axis_tdata),
    .m_axis_tvalid(m_axis_tvalid),
    .m_axis_tready(m_axis_tready)
  );

  initial 
    begin
    clk = 1'b0;
    rst_n = 1'b0; 
    r_s_axis_tdata = 0;
    r_s_axis_tvalid = 1'b0; 

    // load samples into register
    fid = $fopen("50kHz_sine_wave_with_noise.txt","r");
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
        r_s_axis_tdata = r_wave_sample[j];
        j = j + 1;
        wait (clk == 1'b0) wait (clk == 1'b1) // wait for rising edge of clock
        r_s_axis_tvalid = 1'b1;
        #20
        r_s_axis_tvalid = 1'b0; // tvalid only high for 1 clock cycle
      end
      #50000
      $finish;
    end

endmodule