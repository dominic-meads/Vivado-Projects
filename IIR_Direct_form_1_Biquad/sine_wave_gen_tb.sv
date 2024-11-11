`timescale 1ns / 1 ps

module sine_wave_gen_tb;
  reg clk;
  reg signed [15:0] r_din;
  wire signed [15:0] dout_v;
  wire signed [15:0] dout_vhd;

  always #50 clk = ~clk;  // 10 MHz clk

  integer fid;
  integer status;
  integer sample; 
  integer i;
  integer j = 0;
  
  localparam num_samples = 1000;
  
  reg signed [15:0] r_wave_sample [0:num_samples - 1];

  iir_DF1_Biquad uut (
    .clk(clk),
    .din(r_din),
    .dout(dout_v)
  );

  iir_biquad_df1 vhd (
    .clk(clk),
    .din(r_din),
    .dout(dout_vhd)
  );
  
  initial 
    begin
      clk = 0;
      r_din = 0;
      //r_din = 1000;
      //#100
     fid = $fopen("50kHz_sine_wave_with_noise.txt","r");
     for (i = 0; i < num_samples; i = i + 1)
       begin
         status = $fscanf(fid,"%d\n",sample); 
         //$display("%d\n",sample);
         r_wave_sample[i] = 16'(sample);
         //$display("%d index is %d\n",i,r_wave_sample[i]);
       end
     $fclose(fid);

     repeat(num_samples)
       begin 
         wait (clk == 0) wait (clk == 1)
         r_din = r_wave_sample[j];
         j = j + 1;
       end
      #50000
      $finish;
    end

endmodule