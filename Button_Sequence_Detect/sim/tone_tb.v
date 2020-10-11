`timescale 1ns / 1ps

module tone_tb;
  reg clk;
  reg EN392;
  reg EN110;
  wire tone_out;
  
  always #4 clk = ~clk;  // 125 MHz
  
  tone uut(clk,EN392,EN110,tone_out);
  
  initial 
    begin
      //$dumpfile("dump.vcd");
      //$dumpvars(0,uut);
      clk = 0;
      EN392 = 0;
      EN110 = 0;
      #20 
      EN392 = 1;
      EN110 = 0;
      #100000000  // .1 second
      EN392 = 0;
      EN110 = 0;
      #10000000
      EN392 = 0;
      EN110 = 1;
      #100000000 // .1 sec
      $finish;
    end
endmodule
