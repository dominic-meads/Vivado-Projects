`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Dominic Meads
// 
// Create Date: 10/2/2024 10:37:57 PM
// Design Name: 
// Module Name: AXIS_packetizer_intrpt
// Project Name: 
// Target Devices: 7 series
// Tool Versions: 
// Description: AXI4 Stream packetizer and interrupt generator. Gets data from AXI-Stream ADC IP. 
//              After a specified number of samples, the module generates an interrupt (high for a 
//              predefined number of clock cycles), and outputs the samples for a Microblaze processor 
//              to read. 
// 
// Dependencies: Input clk frequency 10 MHz - 200 MHz
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module AXIS_packetizer_intrpt #(
	parameter ACLK         = 100e6,   // axi clk freqeuncy
	parameter SMPLS        = 30,      // samples per packet
	parameter FSMPL        = 200,     // sampling frequency
	parameter DATA_WIDTH   = 16,      // axis_tdata width in bits
  parameter TDATA_CLKS   = 4        // period in clock cycles that m_axis_tdata is held in the same state
	)(
	input  aclk,
	input  aresetn,
	input  s_axis_tvalid,
	input  [DATA_WIDTH-1:0] s_axis_tdata,
	input  m_axis_tready,
	output s_axis_tready,
	output m_axis_tvalid,
	output [DATA_WIDTH-1:0] m_axis_tdata,
	output m_axis_tlast,
	output m_axis_interrupt
	);

	// RX sample counter signals (input from slave)
  reg [$clog2(SMPLS)-1:0] r_rx_cntr = 0;
  reg r_rx_cntr_en = 1'b1;

	// TDATA_CLKS counter signals
  reg [$clog2(TDATA_CLKS)-1:0] r_tdata_clk_cntr = 0;
  reg r_tdata_clk_cntr_en = 1'b0;

	// TX sample counter signals (output to master)
  reg [$clog2(SMPLS)-1:0] r_tx_cntr = 0;
  reg r_tx_cntr_en = 1'b0;

	// input register to hold samples
	reg [DATA_WIDTH-1:0] r_samples [0:SMPLS-1];

	// integer for the "for" loop to assign all registers in vector to 0
	integer i; 

	// output registers
  reg r_s_axis_tready = 1'b1;
	reg r_m_axis_interrupt = 1'b0;
	reg [DATA_WIDTH-1:0] r_m_axis_tdata = 0;

	// states and state register
	localparam RX = 1'b0;
	localparam TX = 1'b1;
	reg r_current_state, r_next_state;

  // RX sample counter. Counts incoming samples from slave
	always @ (posedge aclk or negedge aresetn)
		begin
			if (~aresetn || ~r_rx_cntr_en)
				begin
					r_rx_cntr <= 0;
				end
			else
				begin
					if (s_axis_tvalid && r_rx_cntr < SMPLS - 1)
						begin
							r_rx_cntr <= r_rx_cntr + 1;
						end
					else if (s_axis_tvalid && r_rx_cntr == SMPLS - 1)
						begin
							r_rx_cntr <= 0;
						end
				end
			end

	// TDATA_CLKS counter. Microblaze takes 2 clock cycles to get data from AXI-stream.
	// Must hold data in same state for >= 2 clock cycles. Specified in module to hold for 4 cycles
	always @ (posedge aclk or negedge aresetn)
		begin
			if (~aresetn || ~r_tdata_clk_cntr_en)
				begin
					r_tdata_clk_cntr <= 0;
				end
			else
				begin
					if (r_tdata_clk_cntr < TDATA_CLKS - 1)
						begin
							r_tdata_clk_cntr <= r_tdata_clk_cntr + 1;
						end
					else
						begin
							r_tdata_clk_cntr <= 0;
						end
				end
			end

	// TX sample counter. Keeps track of outgoing samples to master
	always @ (posedge aclk or negedge aresetn)
		begin
			if (~aresetn || ~r_tx_cntr_en)
				begin
					r_tx_cntr <= 0;
				end
			else
				begin // allow tdata to be on bus for specified # of clk cycles before counting out a new sample
					if (r_tdata_clk_cntr == TDATA_CLKS - 1 && r_tx_cntr < SMPLS - 1)   
						begin
							r_tx_cntr <= r_tx_cntr + 1;
						end
					else if (r_tdata_clk_cntr == TDATA_CLKS - 1 && r_tx_cntr == SMPLS - 1)
						begin
							r_tx_cntr <= 0;
						end
				end
			end

	// next state logic
	always @ (*)
		begin 
			case (r_current_state)
				RX : 
					begin 
						if (r_rx_cntr == SMPLS - 1 && s_axis_tvalid)  // wait for last incoming sample to be valid
							begin 
								r_next_state = TX;
							end
						else	
							begin 
								r_next_state = r_current_state;
							end
					end

				TX :
					begin 
						if (r_tx_cntr == SMPLS - 1 && r_tdata_clk_cntr == TDATA_CLKS - 1)  // wait for last outgoing sample
							begin 
								r_next_state = RX;
							end
						else	
							begin 
								r_next_state = r_current_state;
							end
					end
				
				default : r_next_state = RX;
			endcase
		end

	// state update
	always @ (posedge aclk or negedge aresetn)
			begin
					if (~aresetn)
							r_current_state <= RX;
					else 
							r_current_state <= r_next_state;
			end

	// output logic 
	always @ (*)
			begin
					if (r_current_state == RX)
							begin 
									r_s_axis_tready     = 1'b1;  // inform slave module is ready to accept data
									r_m_axis_interrupt  = 1'b0;  // interrupt is low
									r_rx_cntr_en        = 1'b1;  // start counting input samples
									r_tdata_clk_cntr_en = 1'b0;  
									r_tx_cntr_en        = 1'b0;
									r_m_axis_tdata      = 0;     // dont output anything to master in this state
							end

					else if (r_current_state == TX)
							begin 
									r_s_axis_tready     = 1'b0;  // inform slave module is ready to accept data
									r_m_axis_interrupt  = 1'b1;  // interrupt is high (configure PS for interrupt edge detection)
									r_rx_cntr_en        = 1'b0;  // stop counting input samples
									r_tdata_clk_cntr_en = 1'b1;  // start output timing for data on bus (each sample for specified # of clks)
									r_tx_cntr_en        = 1'b1;  // start counting output samples
									r_m_axis_tdata      = r_samples[r_tx_cntr];  // output data FIFO style
							end
						else
							begin 
									r_s_axis_tready     = 1'b0;
									r_m_axis_interrupt  = 1'b0;  
									r_rx_cntr_en        = 1'b0;
									r_tdata_clk_cntr_en = 1'b0;  
									r_tx_cntr_en        = 1'b0;
							end
			end

	// register input samples
	always @ (posedge aclk or negedge aresetn)
		begin
			if (~aresetn)
				begin
				    for (i = 0; i < SMPLS; i = i + 1)
				      begin 
					      r_samples[i] <= 0;
					    end
				end
			else if (r_current_state == RX && s_axis_tvalid)
				begin
					r_samples[r_rx_cntr] <= s_axis_tdata;
				end
		end
					
  assign s_axis_tready    = r_s_axis_tready;
	assign m_axis_tvalid    = (r_tdata_clk_cntr == 1) ? 1:0;   // TVALID only high for one clock cycle
	assign m_axis_tdata     = r_m_axis_tdata;
	assign m_axis_tlast     = (r_tx_cntr == SMPLS - 1) ? 1:0;  // TLAST high on last output sample
	assign m_axis_interrupt = r_m_axis_interrupt;

endmodule

