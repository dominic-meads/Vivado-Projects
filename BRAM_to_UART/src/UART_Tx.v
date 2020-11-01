`timescale 1ns / 1ps

/////////////////////////////////////////////////////////////////////////
//
//   BASIC UART transmitter
//   
//   Serial Terminal Settings:
//		115200 baud
//		1 stop bit
//		No Parity
//		8 data bits
//
//	 Written by Dominic Meads 
//	 11/1/2020
//	 ver 1.0
//
/////////////////////////////////////////////////////////////////////////

module UART_Tx 
	# (parameter CPB = 1085)      // CPB = clocks per bit (clocks that occur during one bit transmission) :  125 MHz / 115200 Baud = 1085 (1085.069)
	(
	input clk,               	  // 125 MHz
	input [7:0] i_data,        	  // input data to be serialized
	input nTx_EN,             	  // transmit enable (ACTIVE LOW)
	output o_Tx,               	  // Serial transmit line
	output o_RFN,              	  // RFN = ready for next (data) -- high pulse
	output [3:0] o_sample_count,  // outputs the bit we are transmitting
	output [10:0] o_CPB_count     // outputs how close we are to transmitting a new bit
	);
	
	// states
	localparam IDLE = 1'b0;       // do nothing (wait for nTx_EN to go LOW)
	localparam TRANSMIT = 1'b1;   // serialize and transmit data
	
	// Registers
	reg STATE = IDLE;             // state machine reg initialized to IDLE
	reg [9:0] temp = 0;           // data reg with start and stop bits
	reg r_Tx = 1;                 // output register for o_Tx
	reg r_RFN = 1;                // output register for o_RFN
	reg [10:0] CPB_count = 0;     // CPB_count for the clocks per bit (CPB)
	reg nCPB_count_E = 1;         // CPB_count enable (ACTIVE LOW)
	reg [3:0] sample_count = 0;   // to keep track of which bit we are transmitting
	reg nsample_count_E = 1;      // sample_count enable (ACTIVE LOW)
	
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// counters 
	always @ (posedge clk)
		begin 
			if (!nCPB_count_E)  // active low
				begin 
					if (CPB_count < CPB - 1)
						CPB_count <= CPB_count + 1;
					else 
						CPB_count <= 0;
				end // if (!nCPB_count_E)
			else 
				CPB_count <= 0;  // if nCPB_count_E low, CPB_count is reset to 0
		end // always
  
	always @ (posedge clk)
		begin
			if (!nsample_count_E)
				begin 
					if (CPB_count == CPB - 1)  
						begin 
							if (sample_count <= 9)  // counter counts up to 10 (11 counts) to ensure full stop bit is sent      
								sample_count <= sample_count + 1;
							else
								sample_count <= 0;
						end  // if (CPB_count...
				end      // if (!nsample_count_E)
			else     // if nsample_count_E is high
				sample_count <= 0;  // disable counter
		end // always
	
	assign o_CPB_count = CPB_count;        // output assignments
	assign o_sample_count = sample_count;
	// end counters 
	
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// FSM
	always @ (posedge clk)
		begin
			case (STATE)
			
				IDLE : 
					begin
						r_Tx <= 1;      // Transmit line held high
						r_RFN <= 0;     // not ready for new data (with the exception of the first transmission)
						if (!nTx_EN)
							begin
								nCPB_count_E <= 0;                  // activate CPB_count
								nsample_count_E <= 0;               // activate sample_count
								temp <= {1'b1, i_data[7:0], 1'b0};  // concatenate the stop bit (high), data, and start bit (low)
								STATE <= TRANSMIT;                  // move to transmit state
							end  // if (!nTx_EN)
						else     // if nTx_EN
							begin 
								nCPB_count_E <= 1;     // CPB_count disabled
								nsample_count_E <= 1;  // sample_count disabled
								STATE <= IDLE;         // stay in IDLE
							end  // else
					end  // IDLE
				
				TRANSMIT :
					begin
						if (sample_count < 10)
							begin 
								r_Tx <= temp[sample_count];  // serialize data
								r_RFN <= 0;                  // dont send new data
								nCPB_count_E <= 0;           // keep CPB_count enabled
								nsample_count_E <= 0;        // keep sample_count enabled
								STATE <= TRANSMIT;           // Keep transmitting
							end  // if (sample_count < 10)
						else     // if sample_count == 10
							begin 
								r_Tx <= 1;            // hold line high (should already be high)
								r_RFN <= 1;           // send a single high pulse indicating ready for next input data
								nCPB_count_E <= 1;    // disable CPB_count
								nsample_count_E <= 1; // disable nsample_count_E
								STATE <= IDLE;        // wait for the next nTx_EN
							end  // else 
					end  // TRANSMIT
					
				default :
					begin 
						r_Tx <= 1;             // hold Tx line high
						r_RFN <= 0;            // RFN low
						nCPB_count_E <= 1;     // disable CPB_count
						nsample_count_E <= 1;  // disable sample_count
						STATE <= IDLE;         // state is IDLE
					end  // default
			endcase
		end  // always
		// end FSM
		
		///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		// output assignments			
		assign o_Tx = r_Tx;
	    assign o_RFN = r_RFN;
	    assign o_sample_count = sample_count;
	    assign o_CPB_count = CPB_count;
		// end output assignments
		
endmodule  // UART_Tx
		
