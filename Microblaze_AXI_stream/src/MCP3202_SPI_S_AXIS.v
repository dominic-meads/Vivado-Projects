`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Dominic Meads
// 
// Create Date: 09/1/2024 10:37:57 PM
// Design Name: 
// Module Name: MCP3202_SPI
// Project Name: 
// Target Devices: 7 series
// Tool Versions: 
// Description: An SPI master for an MCP3202 ADC. Compatible with AXI4 Stream. It has a configurable sample rate (set here to 
//              200 samples/sec for an ECG demo. The ADC is set to operate in single-ended sampling
//              "MSB first" mode on input channel 0. The ADC can be set to differential mode and 
//              channel can be changed (see "parameters"), but "MSB first" mode is always selected
//
// 
// Dependencies: Input clk frequency 10 MHz - 200 MHz
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module MCP3202_SPI_S_AXIS #(
    parameter FCLK  = 100e6, // clk frequency
    parameter FSMPL = 200,   // sampling freqeuncy 
    parameter SGL   = 1,     // sets ADC to single-ended
    parameter ODD   = 0      // sets ADC sample input to channel 0
    )(
    input clk,
    input rst_n,
    input miso,
    input s_axis_spi_tready,
    output mosi,
    output sck,
    output cs,
    output signed [15:0] s_axis_spi_tdata,
    output s_axis_spi_tvalid
    );

    localparam INIT = 3'b000;  // initialize the state machine
    localparam TX   = 3'b001;  // set the sample channel, sampling mode, etc...
    localparam RX   = 3'b010;  // convert the bitstream into parellel word
    localparam DV   = 3'b011;  // Data valid
    localparam IDLE = 3'b100;  // CS is high

    reg [2:0] r_current_state, r_next_state;

    // Calculates number of input clk cycle counts equal to TCSH time (depends on clk)
    localparam integer TCSH_CLK_CNTS_MAX = (FCLK/FSMPL) - 15300; 

    // additional MOSI data
    localparam START = 1'b1;           // start bit
    localparam	MSBF = 1'b1;           // sets ADC to transmit MSB first

    // DATA TO BE TX'ed VIA MOSI LINE
    reg [3:0] r_tx_data = {MSBF, ODD[0], SGL[0], START};
    
    // output registers
    reg r_mosi = 0; 
    reg [12:0] r_rx_data = 13'h0000; // 1 null bit and 12 data bits
    reg r_cs = 1;       	         // disable CS to start
    reg r_dv = 0;                    // DATA_VALID register
    
    reg[$clog2(TCSH_CLK_CNTS_MAX)-1:0] r_tcsh_clk_cnts = 0;
    reg r_tcsh_clk_cntr_en = 0;
    
    // input clk cycles per single spi clk cycle
    reg[9:0] r_clk_cnts_per_sck = 0;
    
    // spi clk cycle counter
    reg[4:0] r_sck_cntr = 0;
    reg r_sck_en = 0;
    
    // TCSH counter
    always @ (posedge clk or negedge rst_n)
        begin
            if (~rst_n || ~r_tcsh_clk_cntr_en)
                r_tcsh_clk_cnts <= 0;
            else 
                begin
                  if (r_tcsh_clk_cnts < TCSH_CLK_CNTS_MAX - 1) 

                        r_tcsh_clk_cnts <= r_tcsh_clk_cnts + 1;
                    else 
                        r_tcsh_clk_cnts <= 0;
                end 
        end

    // input clk divider for SCLK (divided by 900)
     always @ (posedge clk or negedge rst_n)
        begin
            if (~rst_n || ~r_sck_en)
                r_clk_cnts_per_sck <= 0;
            else 
                begin
                    if (r_clk_cnts_per_sck < 899)  // divide system clk by 900, input between 10 MHz to 200 MHz
                        r_clk_cnts_per_sck <= r_clk_cnts_per_sck + 1;
                    else
                        r_clk_cnts_per_sck <= 0;
                end
        end
        
    // SCLK cycle counter
     always @ (posedge clk or negedge rst_n)
        begin 
            if (~rst_n || ~r_sck_en)
                r_sck_cntr <= 0;
            else
                begin 
                    if (r_sck_cntr < 16 && r_clk_cnts_per_sck == 899)
                        r_sck_cntr <= r_sck_cntr + 1;
                    else if (r_sck_cntr == 16 && r_clk_cnts_per_sck == 899)
                        r_sck_cntr <= 0;
                end
        end

    // state machine
    always @ (*)
        begin 
            case (r_current_state) 
    
                INIT :
                    begin 
                        if (r_tcsh_clk_cnts == TCSH_CLK_CNTS_MAX - 1)  // only move to next state if the total disable time is met
                            r_next_state = TX;
                        else
                            r_next_state = r_current_state;
                    end
            
                TX : 
                    begin 
                        if (r_sck_cntr == 3 && r_clk_cnts_per_sck == 899)
                            r_next_state = RX;
                        else
                            r_next_state = r_current_state;
                    end 

                RX : 
                    begin 
                        if (r_sck_cntr == 16 && r_clk_cnts_per_sck == 898)
                            r_next_state = DV;
                        else
                            r_next_state = r_current_state;  
                    end

                DV :
                    begin
                        if (r_sck_cntr == 16 && r_clk_cnts_per_sck == 899)  // only in DV state for 1 clk cycle
                            r_next_state = IDLE;
                        else
                            r_next_state = r_current_state;
                    end

                IDLE : 
                    begin
                        if (r_tcsh_clk_cnts == TCSH_CLK_CNTS_MAX - 1)  // only move to next state if the total disable time is met
                            r_next_state = TX;
                        else
                            r_next_state = r_current_state;
                    end

                default : r_next_state = INIT;
            endcase
        end

    // register miso in RX state
    always @ (posedge clk or negedge rst_n)
        begin 
            if (~rst_n)
                r_rx_data <= 13'h0000;
            else if (r_current_state == RX)
                begin 
                    if (r_clk_cnts_per_sck == 449)  // Register miso bits at middle of sck period (most stable)
                        r_rx_data[12-(r_sck_cntr-4)] = miso;
                end
        end 

    // Output logic 
    always @ (*)
        begin
            if (r_current_state == INIT)
                begin 
                    r_cs      = 1'b1;
                    r_mosi    = 1'b0;
                    r_dv      = 1'b0;  // data is NOT valid in INIT state (no sample has occurred yet)
                    
                    r_tcsh_clk_cntr_en = 1'b1;  // count the time the ADC needs to be disabled to meet FSMPL
                    r_sck_en           = 1'b0;  // sck not active at this time
                end

            else if (r_current_state == TX)
                begin 
                    r_cs      = 1'b0;  // enable ADC
                    r_mosi    = r_tx_data[r_sck_cntr];  // ship out mosi bits
                    r_dv      = 1'b0;
                    
                    r_tcsh_clk_cntr_en = 1'b0;
                    r_sck_en           = 1'b1;  // start counting sck cycles (17 in total per sample conversion)
                end

            else if (r_current_state == RX)
                begin            
                    r_cs   = 1'b0;
                    r_mosi = 1'b0;
                    r_dv   = 1'b0;
                    
                    r_tcsh_clk_cntr_en = 1'b0;
                    r_sck_en           = 1'b1;
                end

            else if (r_current_state == DV)
                begin            
                    r_cs   = 1'b0;
                    r_mosi = 1'b0;
                    r_dv   = 1'b1;  // sample data is now valid
                    
                    r_tcsh_clk_cntr_en = 1'b0;
                    r_sck_en           = 1'b1;
                end

            else if (r_current_state == IDLE)
                begin
                    r_cs      = 1'b1;  // disable ADC
                    r_mosi    = 1'b0;
                    r_dv      = 1'b0;  
                    
                    r_tcsh_clk_cntr_en = 1'b1;  // start counting ADC disable time again
                    r_sck_en           = 1'b0;
                end

            else
                begin
                    r_cs      = 1'b1;
                    r_mosi    = 1'b0;
                    r_dv      = 1'b0;  
                                
                    r_tcsh_clk_cntr_en = 1'b0;
                    r_sck_en           = 1'b0;
                end 
        end

    always @ (posedge clk, negedge rst_n)
        begin
            if (~rst_n)
                r_current_state <= INIT;
            else 
                r_current_state <= r_next_state;
        end 

    assign cs = r_cs;
    assign mosi = r_mosi;
    assign s_axis_spi_tdata = {4'h0, r_rx_data[11:0]};    // data always postive sign (unipolar ADC)
    assign s_axis_spi_tvalid = s_axis_spi_tready & r_dv;  // dont send tvalid unless downstream device is ready. 
    assign sck = (r_clk_cnts_per_sck <= 449 && r_sck_en) ? 0:1;

endmodule
