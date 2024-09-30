`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Dominic Meads
// 
// Create Date: 09/1/2024 10:44:56 PM
// Design Name: 
// Module Name: tb_MCP3202_SPI_S_AXIS
// Project Name: 
// Target Devices: 7 Series
// Tool Versions: 
// Description: TB acts as MCP3202 ADC chip. Simulates timing, and sends out sample data. 
//              Verifies "MCP3202_SPI.v"
//
//              Datasheet: https://ww1.microchip.com/downloads/aemDocuments/documents/APID/ProductDocuments/DataSheets/21034F.pdf
// 
// Dependencies: Input clk frequency 10 MHz - 200 MHz
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_MCP3202_SPI_S_AXIS;
  reg clk, rst_n, m_axis_tready;
  wire m_axis_tvalid, m_axis_tlast;
  wire [15:0] m_axis_tdata;
  
  localparam FCLK  = 100e6; // clk frequency
  localparam FSMPL = 500;   // sampling frequency
  localparam SGL   = 1;     // single-ended mode
  localparam ODD   = 0;     // Data Aquisition on Channel 0

  // intermediate signals
  wire w_cs, w_sck, w_mosi, w_miso;
  
  AXI_stream_SPI #(
    .FCLK(FCLK),
    .FSMPL(FSMPL),
    .SGL(SGL),
    .ODD(ODD)
    ) 
    uut (
    .clk(clk),
    .rst_n(rst_n),
    .miso(w_miso),
    .m_axis_tready(m_axis_tready),
    .mosi(w_mosi),
    .sck(w_sck),
    .cs(w_cs),
    .m_axis_tvalid(m_axis_tvalid),
    .m_axis_tdata(m_axis_tdata),
    .m_axis_tlast(m_axis_tlast) 
    );

  ADC_behav #(
    .FCLK(FCLK),
    .FSMPL(FSMPL),
    .SGL(SGL),
    .ODD(ODD)
    ) 
    ADC_0 (
    .cs(w_cs),
    .sck(w_sck),
    .mosi(w_mosi),
    .miso(w_miso)
    );

  real half_clk_period = 1e9/(2*FCLK);
  always #half_clk_period clk = ~clk;
  
  integer i_SBST_CNV_SMPLS = 64;
  integer i_PKT_TIME_ns; // time required for subset converter to hold one packet of ADC samples
      
  initial 
    begin
      i_PKT_TIME_ns = (1/FSMPL)*i_SBST_CNV_SMPLS; 
      clk   = 1'b0;
      rst_n = 1'b0;
      m_axis_tready = 1'b0; 
      #25
      rst_n = 1'b1;
      m_axis_tready = 1'b1;  
      //#i_PKT_TIME_ns
      #128000000
      #50000000
      m_axis_tready = 1'b0;
      $finish(2);
    end
endmodule
