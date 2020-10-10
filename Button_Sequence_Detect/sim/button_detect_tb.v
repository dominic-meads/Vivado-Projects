`timescale 1ns / 1ps

/////////////////////////////////////////////////////////////////////////////////////////
//
//  SIMULATION DESCRIPTION:	A basic sequence detector of which buttons are pressed. If the 
//							correct sequence is detected and the unlock switch goes high,
// 							a blue LED will light, if not, the red LED will light. There
//                          is no overlap. The buttons I am using are 4 buttons built into
//                          the Arty z7-10 board.
//
//                          The correct sequence is BTN2, BTN3, BTN1, BTN1
//
//	            FILENAME:   button_detect_tb.v
//	             VERSION:   1.0  10/08/2020
//                AUTHOR:   Dominic Meads
//
/////////////////////////////////////////////////////////////////////////////////////////

module tb;
	reg clk;         // 125 MHz
	reg [3:1] BTN;   // 4 buttons on Arty Z7-10: BTN3; BTN2; BTN1; BTN0. The first 3 are the sequence regs
	reg clr_n;       // ACTIVE LOW clear/reset
	reg correct;     // press to see if sequence is correct (BTN0)
	wire blue;       // sequence correct
	wire red;        // sequnce incorrect
	
	always #4 clk = ~clk;  // 8 ns period
	
	button_detect uut(clk,BTN,clr_n,correct,blue,red);
	
	
	/* task for button pressing, in the constraints file, buttons 3, 2, and 1 will be mapped to their respective buttons on the arty board.
	   Button 0 will be mapped to the "correct" input so a button_press task on button 0 will manipulated the global register "correct" */
	task button_press;  // note (no bounce simulated on button)
		input integer i;
			begin
				if (i == 0)
					begin 
						correct = 1'b1;
						#20 // 20 ns is very short, just for simulation purposes, make longer for a more accurrate simulation
						correct = 1'b0;
					end  // if (i == 0)
				else  // if i = 1, 2, or 3
					begin 
						BTN[i] = 1'b1;
						#20  
						BTN[i] = 1'b0;
					end  // else
			end 
	endtask
	
	
	// start sim
	initial 
		begin 
			clk = 0;
			BTN = 3'b000;
			clr_n = 0;     // reset active
			correct = 0;
			#200
			clr_n = 1;  // ready to recieve sequence
			#200
			
			// input correct sequence
			button_press(2);
			#200
			button_press(3);
			#200
			button_press(1);
			#200
			button_press(3);
			#200
			button_press(0);  // check if correct, "blue" should be high
			#200
			clr_n = 0; // reset
			#10000
			clr_n = 1;
			#200
			
			// input an incorrect sequence
			button_press(3);
			#200
			button_press(3);
			#200
			button_press(2);
			#200
			button_press(1);
			#200
			button_press(0);  // check if correct, "red" should be high
			#200
			clr_n = 0; // reset
			#10000
			clr_n = 1;
			#200
			
			// input another correct sequence
			button_press(2);
			#200
			button_press(3);
			#200
			button_press(1);
			#200
			button_press(3);
			#200
			button_press(0);  // check if correct, "blue" should be high
			#200
			clr_n = 0; // reset
			#10000
			clr_n = 1;
			#200
			
			// check clr_n partway through sequence
			#10000
			button_press(2);
			#200
			button_press(3);
			#200
			clr_n = 0;  // "STATE" should be in "RESET"
			#5000

			$finish;
		end  // sim
endmodule  // tb
