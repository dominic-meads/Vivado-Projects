`timescale 1ns / 1ps

/////////////////////////////////////////////////////////////////////////////////////////
//
//   PROJECT DESCRIPTION:	A basic sequence detector of which buttons are pressed. If the 
//							correct sequence is detected and the unlock switch goes high,
// 							a blue LED will light, and a 362 Hz tone will sound. If not, 
//					        the red LED will light, and a 110 Hz tone will sound. There
//                          is no overlap. The buttons I am using are 4 buttons built into
//                          the Arty z7-10 board.
//
//                          The enter sequence is BTN2, BTN3, BTN1, BTN3
//
//	            FILENAME:   button_detect.v
//	             VERSION:   1.0  10/08/2020
//                AUTHOR:   Dominic Meads
//
/////////////////////////////////////////////////////////////////////////////////////////

// uncomment the toneout wire for use with the speaker
module button_detect_tb;
	reg clk;         // 125 MHz
	reg [3:1] BTN;   // 4 buttons on Arty Z7-10: BTN3; BTN2; BTN1; BTN0. The first 3 are the sequence regs
	reg clr_n;       // ACTIVE LOW clear/reset
	reg enter;       // press to see if sequence is correct (BTN0)
	wire blue;       // sequence correct
	wire red;        // sequnce incorrect
	wire toneout;    // output to speaker
	
	always #4 clk = ~clk;  // 8 ns period
	
	// MUST add toneout to port list if simulating speaker
	button_detect uut(clk,BTN,clr_n,enter,blue,red,toneout);
	
	/* IMPORTANT: to reduce simulation time, take counter values of rLED_time and bLED_time in uut and reduce by a factor 
	   of 100. Also reduce the comparison factors from 125000000 to 1250000 in the INDICATEr and INDICATEb blocks 
	   
	   MAKE SURE TO CHANGE BACK BEFORE GENERATING BITSTREAM!!!!!!!!!!!!*/
	
	
	/* task for button pressing, in the constraints file, buttons 3, 2, and 1 will be mapped to their respective buttons on the arty board.
	   Button 0 will be mapped to the "enter" input so a button_press task on button 0 will manipulated the global register "enter" */
	task button_press;  // note (no bounce simulated on button)
		input integer i;
			begin
				if (i == 0)
					begin 
						enter = 1'b1;
						#2500000 // 2.5 ms pulse simulating a single button press
						enter = 1'b0;
					end  // if (i == 0)
				else  // if i = 1, 2, or 3
					begin 
						BTN[i] = 1'b1;
						#2500000   
						BTN[i] = 1'b0;
					end  // else
			end 
	endtask
	
	
	/* start sim (NOTE, to reduce sim time, all times are reduced by a factor of 100, i.e. a 250 ms 
	   pulse is simulated as a 2.5 ms pulse */
	initial 
		begin 
			clk = 0;
			BTN = 3'b000;
			clr_n = 0;     // reset active
			enter = 0;
			#5000000    // 0.05 seconds
			clr_n = 1;  // ready to recieve sequence
			#8000000    // 0.08 seconds
			
			// input correct sequence
			button_press(2);
			#8000000
			button_press(3);
			#8000000
			button_press(1);
			#8000000
			button_press(3);
			#8000000
			button_press(0);  // check if correct, "blue" should be high
			#8000000
			clr_n = 0; // reset
			#50000000  // .05 sec
			clr_n = 1;
			#8000000
			
			// input an incorrect sequence
			button_press(3);
			#8000000
			button_press(3);
			#8000000
			button_press(2);
			#8000000
			button_press(1);
			#8000000
			button_press(0);  // check if correct, "red" should be high
			#8000000
			clr_n = 0; // reset
			#50000000  // .05 sec
			clr_n = 1;
			#8000000
			
			// input another correct sequence
			button_press(2);
			#8000000
			button_press(3);
			#8000000
			button_press(1);
			#8000000
			button_press(3);
			#8000000
			button_press(0);  // check if correct, "blue" should be high
			#8000000
			clr_n = 0; // reset
			#50000000  // .05 sec
			clr_n = 1;
			#8000000
			
			// check clr_n partway through sequence
			#50000000  // .05 sec
			button_press(2);
			#8000000
			button_press(3);
			#8000000
			clr_n = 0;  // "STATE" should be in "RESET"
			#20000000  

			$finish;
		end  // sim
endmodule  // tb



