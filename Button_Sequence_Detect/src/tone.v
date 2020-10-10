`timescale 1ns / 1ps

/* This module creates two tones, one for when the sequence is correct, and 
   one for when the sequence is not correct. They will output to a piezo 
   speaker from an arduino kit */


module tone(
  input clk,
  input EN392,  // 392 hz enable
  input EN110,  // 110 hz enable
  output out392,
  output out110
);
  
  reg [18:0] counter392 = 0;  
  reg [21:0] counter110 = 0;  
  
  always @ (posedge clk)
    begin 
      if (EN392)
        begin 
          if (counter392 <= 318877)
            counter392 <= counter392 + 1;
          else 
            counter392 <= 0;
        end
      else
        counter392 <= 0;
    end
      
  always @ (posedge clk)
    begin 
      if (EN110)
        begin 
          if (counter110 <= 1136363)
            counter110 <= counter110 + 1;
          else 
            counter110 <= 0;
        end
      else
        counter110 <= 0;
    end
      
  assign out392 = (counter392 < 159434) ? 1:0;  // 392 Hz 50% duty PWM
  assign out110 = (counter110 < 568181) ? 1:0;  // 110 Hz 50% duty PWM
      
endmodule
