`timescale 1ns / 1ps

module tone_tb;
  reg clk;
  reg EN392;
  reg EN110;
  wire out392;
  wire out110;
  
  always #4 clk = ~clk;  // 125 MHz
  
  tone uut(clk,EN392,EN110,out392,out110);
  
  initial 
    begin
      clk = 0;
      EN392 = 0;
      EN110 = 0;
      #20 
      EN392 = 1;
      EN110 = 1;
      #1000000000
      $finish;
    end
endmodule
