`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/30/2024 01:07:27 PM
// Design Name: 
// Module Name: AXI_stream_SPI
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module AXI_stream_SPI #(
    parameter FCLK  = 100e6, // clk frequency
    parameter FSMPL = 500,   // sampling freqeuncy 
    parameter SGL   = 1,     // sets ADC to single-ended
    parameter ODD   = 0      // sets ADC sample input to channel 0
    )(
    input clk,
    input rst_n,
    input miso,
    input m_axis_tready,
    output mosi,
    output sck,
    output cs,
    output m_axis_tvalid,
    output [15:0] m_axis_tdata,
    output m_axis_tlast   
    );
    
    // interconnects from SPI to AXIS Subset
    wire [15:0] w_s_axis_spi_tdata;
    wire w_s_axis_spi_tvalid;
    wire w_s_axis_spi_tready;
    
    axis_subset_converter_0 sub0 (
        .aclk(clk),                    // input wire aclk
        .aresetn(rst_n),              // input wire aresetn
        .s_axis_tvalid(w_s_axis_spi_tvalid),  // input wire s_axis_tvalid
        .s_axis_tready(w_s_axis_spi_tready),  // output wire s_axis_tready
        .s_axis_tdata(w_s_axis_spi_tdata),    // input wire [15 : 0] s_axis_tdata
        .m_axis_tvalid(m_axis_tvalid),  // output wire m_axis_tvalid
        .m_axis_tready(m_axis_tready),  // input wire m_axis_tready
        .m_axis_tdata(m_axis_tdata),    // output wire [15 : 0] m_axis_tdata
        .m_axis_tlast(m_axis_tlast)    // output wire m_axis_tlast
    );
    
    MCP3202_SPI_S_AXIS #(
        .FCLK(FCLK),
        .FSMPL(FSMPL),
        .SGL(SGL),
        .ODD(ODD)
    ) 
    spi0 (
        .clk(clk), 
        .rst_n(rst_n), 
        .miso(miso), 
        .s_axis_spi_tready(w_s_axis_spi_tready), 
        .mosi(mosi), 
        .sck(sck), 
        .cs(cs), 
        .s_axis_spi_tdata(w_s_axis_spi_tdata), 
        .s_axis_spi_tvalid(w_s_axis_spi_tvalid)
    );
    
endmodule
