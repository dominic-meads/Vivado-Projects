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

module button_detect(
	input clk,              // 125 MHz
	input [3:1] BTN,        // 4 buttons on Arty Z7-10: BTN3, BTN2, BTN1, BTN0. The first 3 are the sequence inputs
	input clr_n,            // ACTIVE LOW clear/reset
	input enter,            // press to see if sequence is correct(BTN0)
	output blue,            // sequence entry correct
	output red,             // sequnce entry incorrect
	output reg tone_EN362,  // enables 362 Hz tone
	output reg tone_EN110   // enables 110 Hz tone
	);
	
	// states
	localparam RESET     = 3'b000;  
	localparam got2      = 3'b001;  // BTN2 high
	localparam got23     = 3'b010;  // BTN3 high
	localparam got231    = 3'b011;  // BTN1 high
	localparam got2313   = 3'b100;  // BTN3 high
	localparam INDICATEb = 3'b101;  // keeps the blue LED lit for 500 ms, indicating the correct sequence
	localparam INDICATEr = 3'b110;  // keeps the red LED lit for 500 ms, indicating the INCORRECT sequence
	
	// registers
	reg [2:0] STATE = 0;       // current state
	reg [26:0] rLED_time = 0;  // keeps the red LED lit for 500 ms
	reg rLED_time_EN = 0;      // enable for red LED_time
	reg [26:0] bLED_time = 0;  // keeps the blue LED lit for 500 ms
	reg bLED_time_EN = 0;      // enable for blue LED_time
	
	// Next-state logic of Moore machine with part of output logic integrated in ////////////////////////////////////////////////////
	always @ (posedge clk)  // current state and inputs in sensitivity list
		begin 
			if (!clr_n)  // active low  
				STATE <= RESET;    // revert back to RESET
			case (STATE)
				
				RESET : begin 
							if (BTN[2])
								STATE <= got2;
							else if (enter)
								begin 
									rLED_time_EN <= 1;   // incorrect sequence light ON
									bLED_time_EN <= 0;   // correct sequence indicator OFF
									STATE <= INDICATEr;  // indicate the correct sequence HAS NOT been entered
								end  // else if
							else 
								begin
									STATE <= RESET;
									rLED_time_EN <= 0;
									bLED_time_EN <= 0;
								end  // else
						end  // RESET
				
				got2  : begin 
							if (BTN[3])
								STATE <= got23;
							else if (enter)
								begin 
									rLED_time_EN <= 1;    // incorrect sequence light ON
									bLED_time_EN <= 0;    // correct sequence indicator OFF
									STATE <= INDICATEr;   // indicate the correct sequence HAS NOT been entered
								end  // else if
							else 
								begin
									STATE <= got2;        // stay in same state
									rLED_time_EN <= 0;    // dont switch any indicator lights ON
									bLED_time_EN <= 0;
								end  // else
						end  // got2
							
				got23  : begin 
							if (BTN[1])
								STATE <= got231;
							else if (enter)
								begin 
									rLED_time_EN <= 1;    // incorrect sequence light ON
									bLED_time_EN <= 0;    // correct sequence indicator OFF
									STATE <= INDICATEr;   // indicate the correct sequence HAS NOT been entered
								end  // else if
							else 
								begin
									STATE <= got23;       // stay in same state
									rLED_time_EN <= 0;    // dont switch any indicator lights ON
									bLED_time_EN <= 0;
								end  // else
						 end  // got23
							
				got231 : begin
							if (BTN[3])
								STATE <= got2313;
							else if (enter)
								begin 
									rLED_time_EN <= 1;    // incorrect sequence light ON
									bLED_time_EN <= 0;    // correct sequence indicator OFF
									STATE <= INDICATEr;   // indicate the correct sequence HAS NOT been entered
								end  // else if
							else 
								begin
									STATE <= got231;      // stay in same state
									rLED_time_EN <= 0;    // dont switch any indicator lights ON
									bLED_time_EN <= 0;
								end  // else
						  end  // got231
							
				got2313 : begin						
						    if (enter)
								begin 
									rLED_time_EN <= 0;    // incorrect sequence light OFF
									bLED_time_EN <= 1;    // correct sequence indicator ON 
									STATE <= INDICATEb;   // indicate the correct sequence HAS been entered
								end  // else if
							else  // wait for "enter" button to go high
								begin
									STATE <= got2313;     // stay in same state
									rLED_time_EN <= 0;    // dont switch any indicator lights ON
									bLED_time_EN <= 0;
								end  // else
						  end  // got2313
								
				INDICATEb : begin
								if (bLED_time == 125000000)   // stay in "INDICATE" state for 500 ms, THEN return to "RESET"
									begin 
										rLED_time_EN <= 0;  // incorrect sequence light OFF
										bLED_time_EN <= 0;  // correct sequence indicator OFF 
										STATE <= RESET;     // reset back to first state
									end  // if (bLED_time...
								else  // keep the blue LED lit
									begin 
										rLED_time_EN <= 0;  // incorrect sequence light OFF
										bLED_time_EN <= 1;  // keep the correct sequence indicator ON 
										STATE <= INDICATEb;
									end  // else
						    end  // INDICATEb
							
				INDICATEr : begin
								if (rLED_time == 125000000)   // stay in "INDICATE" state for 500 ms, THEN return to "RESET"
									begin 
										rLED_time_EN <= 0;  // incorrect sequence light OFF
										bLED_time_EN <= 0;  // correct sequence indicator OFF 
										STATE <= RESET;     // reset back to first state
									end  // if (rLED_time...
								else  // keep the red LED lit
									begin 
										rLED_time_EN <= 1;  // incorrect sequence light ON
										bLED_time_EN <= 0;  // keep the correct sequence indicator OFF 
										STATE <= INDICATEr;
									end  // else
						    end  // INDICATEr
						   
				default : begin   // default state is "RESET" and no indicator lights are on
							STATE <= RESET;
							rLED_time_EN <= 0;
							bLED_time_EN <= 0;
						  end  // default 
			endcase  // case (STATE)
		end  // always @ (STATE, BTN...
	// end Next-state logic of Moore machine with part of output logic integrated in ////////////////////////////////////////////////
		
		
	// 2nd part of output logic (relies on the enables of the LEDs) ////////////////////////////////////////////////////////////////
	// red
	always @ (posedge clk)
		begin 
			if (rLED_time_EN)
				begin 
					if (rLED_time <= 124999999)  // led will be high for 125 million counts (low for 1 count @ rLED_time <=0) @ 125 MHz is 1 sec of total counting time
						begin 
							rLED_time <= rLED_time + 1;
							tone_EN110 <= 1;  // enable the 110 Hz tone generation for 1 second
						end  // if (rLED_time...
					else 
						begin 
							rLED_time <= 0;
							tone_EN110 <= 0;  // disable the 110 Hz tone generation
						end  // else 
				end  // if (rLED_time_EN)
			else
				begin 
					rLED_time <= 0;
					tone_EN110 <= 0;
				end  // else 
		end  // always 
	// end red
	// blue 
	always @ (posedge clk)
		begin 
			if (bLED_time_EN)
				begin 
					if (bLED_time <= 124999999)  // led will be high for 125 million counts (low for 1 count @ rLED_time <=0) @ 125 MHz is 1 sec of total counting time
						begin 
							bLED_time <= bLED_time + 1;
							tone_EN362 <= 1;  // enable the 362 Hz tone generation for 1 second
						end  // if (bLED_time...
					else
						begin 
							bLED_time <= 0;
							tone_EN362 <= 0;  // enable the 362 Hz tone generation
						end  // else 
				end  // if (bLED_time_EN)
			else 
				begin 
					bLED_time <= 0;
					tone_EN362 <= 0;
				end  // else
		end  // always
	// end blue 
	
	// output assignments (if the LED enables are low, the LED will be low, otherwise they will be lit for 125 million counts @125 MHz (0.5 seconds)
	assign red = (rLED_time > 0) ? 1:0;
	assign blue = (bLED_time > 0) ? 1:0;
	// end 2nd part of output logic (relies on the enables of the LEDs) //////////////////////////////////////////////////////////////
	
endmodule  // button_detect

					
