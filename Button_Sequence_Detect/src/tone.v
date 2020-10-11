`timescale 1ns / 1ps

/* This module creates two tones, one for when the sequence is correct, and 
   one for when the sequence is not correct. They will output to a piezo 
   speaker from an arduino kit */

module tone(  
  input clk,
  input EN392,
  input EN110,
  output tone_out
);
  
  // wires to tie outputs of tone_generate to inputs of tone_select
  wire w_out392;
  wire w_out110;
  
  // lower level instances
  tone_generate tg0(
    .clk(clk),
    .EN392(EN392),
    .EN110(EN110),
    .out392(w_out392),
    .out110(w_out110)
    );
  
  tone_select ts0(
    .EN392(EN392),
    .EN110(EN110),
    .i_392(w_out392),
    .i_110(w_out110),
    .tone_out(tone_out)
    );
  
endmodule
    

// responsible for generating both tones
module tone_generate(
  input clk,
  input EN392,  // 392 hz enable
  input EN110,  // 110 hz enable
  output out392,
  output out110
);
  
  reg [18:0] counter392 = 0;  
  reg [20:0] counter110 = 0;  
  
  always @ (posedge clk)
    begin 
      if (EN392)
        begin 
          if (counter392 <= 318856)  // 392 Hz wave has a period of ~2.551 ms, or 318857 counts @ 125 MHz counter (8 ns period)
            counter392 <= counter392 + 1;
          else 
            counter392 <= 0;
        end  // if (EN392)
      else
        counter392 <= 0;
    end  // always
      
  always @ (posedge clk)
    begin 
      if (EN110)
        begin 
          if (counter110 <= 1136363)  // 110 Hz wave has a period of ~9.091 ms, or 1136363 counts @ 125 MHz counter (8 ns period)
            counter110 <= counter110 + 1;
          else 
            counter110 <= 0;
        end  // if (EN110)
      else
        counter110 <= 0;
    end  // always
      
  assign out392 = (counter392 < 159428) ? 0:1;  // 392 Hz 50% duty PWM
  assign out110 = (counter110 < 568181) ? 0:1;  // 110 Hz 50% duty PWM
      
endmodule  // tone_generate


// module to select which tone to output
module tone_select(
  input EN392,  // 392 hz enable
  input EN110,  // 110 hz enable
  input i_392,
  input i_110,
  output tone_out
);
  
  // AND gates are high-enabled, so a tone will only output when its respective enable is high
  assign tone_out = (EN392 & i_392) | (EN110 & i_110);  
  
endmodule  // tone_select
