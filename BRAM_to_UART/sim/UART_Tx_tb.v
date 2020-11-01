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

module UART_Tx_tb; 
	reg clk;               	      // 125 MHz
	reg [7:0] i_data;        	  // input data to be serialized
	reg nTx_EN;             	  // transmit enable (ACTIVE LOW)
	wire o_Tx;               	  // Serial transmit line
	wire o_RFN;              	  // RFN = ready for next (data) -- high pulse
	wire [3:0] o_sample_count;    // outputs the bit we are transmitting
	wire [10:0] o_CPB_count;      // outputs how close we are to transmitting a new bit
	
	always #4 clk = ~clk;  // create clk
	
	UART_Tx #(1085) uut (clk,i_data,
						 nTx_EN,
						 o_Tx,
						 o_RFN,
						 o_sample_count,
						 o_CPB_count);
						
	initial 
		begin 
			clk = 0;         // init clk
			i_data = 8'h44;  // "D" (ASCII)
			nTx_EN = 1;      // Tx disabled, STATE should be IDLE or 1'b0
			#500
			nTx_EN = 0;      // enable transmit, STATE should be TRANSMIT
			#16              // 2 clock cycles
			nTx_EN = 1;
			#100000
			i_data = 8'h5A;  // "Z" (ASCII)
			#5000
			nTx_EN = 0;
			#16
			nTx_EN = 1;
			#100000
			$finish;
		end 
	endmodule
