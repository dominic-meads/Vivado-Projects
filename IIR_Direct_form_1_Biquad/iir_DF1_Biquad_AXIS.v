`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Dominic Meads
// 
// Create Date: 11/09/2024 10:05:43 PM
// Design Name: 
// Module Name: iir_DF1_Biquad_AXIS
// Project Name: 
// Target Devices: 7 Series
// Tool Versions: Vivado 2020.2
// Description: 
//      Lowpass elliptical filter
//      Cuttoff frequency of 60 kHz, with 40 dB stopband attenuation and 0.5 dB ripple in the passband
//      Direct-form I structure BiQuad
// 
//
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//      Source 1: https://ccrma.stanford.edu/~jos/filters/BiQuad_Section.html#:~:text=The%20term%20%60%60biquad%27%27%20is%20short%20for%20%60%60bi-quadratic%27%27%2C%20and,be%20called%20the%20overall%20gain%20of%20the%20biquad.
//
//////////////////////////////////////////////////////////////////////////////////


module iir_DF1_Biquad_AXIS(
  input  clk,
  input  rst_n,
  input  s_axis_tvalid,
  input  signed [15:0] s_axis_tdata,
  output signed [15:0] m_axis_tdata,
  output m_axis_tvalid,
  output m_axis_tready
);

  // filter coefficients (multiplied floating point coefficients by 2^14)
  // sos = {1.0000   -1.8057    1.0000    1.0000   -1.9459    0.9480}
  //         b0         b1        b2        a0        a1        a2
  //   g = 0.0102 
  reg signed [15:0] a1_fixed = -31881;
  reg signed [15:0] a2_fixed = 15531;
  reg signed [15:0] b0_fixed = 167;    // g * b0 * 2^14  (multiply denom coeffs by gain for DF1 [source 1])
  reg signed [15:0] b1_fixed = -302;   // g * b1 * 2^14 
  reg signed [15:0] b2_fixed = 167;    // g * b2 * 2^14

  // input register
  reg signed [15:0] r_x = 0;

  // output registers
  reg r_m_axis_tvalid = 1'b0; 
  reg r_m_axis_tready = 1'b0;

  // delay registers
  reg signed [15:0] r_x_z1 = 0;
  reg signed [15:0] r_x_z2 = 0;
  reg signed [15:0] r_y_z1 = 0;
  reg signed [15:0] r_y_z2 = 0;

  // multiplication wires
  wire signed [31:0] w_product_a1;
  wire signed [31:0] w_product_a2;
  wire signed [31:0] w_product_b0;
  wire signed [31:0] w_product_b1;
  wire signed [31:0] w_product_b2;

  // acummulate wire
  wire signed [31:0] w_sum; 

  // states
  localparam READY = 1'b0;
  localparam BUSY  = 1'b1;

  // state registers
  reg r_current_state = READY;
  reg r_next_state    = BUSY; 

  // control signals
  reg r_iir_en = 1'b0;  // enables iir filter

  // next state logic
  always @ (*)
    begin 
      case (r_current_state)
        READY : 
          begin 
            if (s_axis_tvalid == 1'b1)
              r_next_state <= BUSY;
            else 
              r_next_state <= r_current_state;
          end 

        BUSY : 
          begin 
            if (m_axis_tvalid == 1'b1)
              r_next_state <= READY;
            else 
              r_next_state <= r_current_state;
          end

        default : r_next_state <= READY;
      endcase
    end

  // output logic
  always @ (*)
    begin 
      if (r_current_state == READY)
        begin 
          r_m_axis_tvalid <= 1'b0;  // data not valid
          r_m_axis_tready <= 1'b1;  // set ready signal 
          r_iir_en        <= 1'b0;  // dont enable iir filter in this state (downstream data not valid yet)
        end 
      else if (r_current_state == BUSY)
        begin 
          r_m_axis_tvalid <= 1'b1;  // data valid
          r_m_axis_tready <= 1'b0;  // disable ready signal 
          r_iir_en        <= 1'b1;  // iir filter enabled (MAC happens in one clock cycle)
        end 
      else 
        begin 
          r_m_axis_tvalid <= 1'b0;  
          r_m_axis_tready <= 1'b0;  
          r_iir_en        <= 1'b0;      
        end   
    end 

  // state update
  always @ (posedge clk, negedge rst_n)
    begin
        if (~rst_n)
            r_current_state <= READY;
        else 
            r_current_state <= r_next_state;
    end 

  always @ (posedge clk, negedge rst_n)
    begin
        if (~rst_n)
          begin 
            r_x    <= 0; 
            r_x_z1 <= 0; 
            r_x_z2 <= 0;
            r_y_z1 <= 0;
            r_y_z2 <= 0;
          end 
        else 
          begin
            if (r_iir_en) 
              begin 
                r_x    <= s_axis_tdata;
                r_x_z1 <= r_x;
                r_x_z2 <= r_x_z1;
                r_y_z1 <= w_sum >>> 14;  // divide by the same 2^14 value the coefficients were multiplied by
                r_y_z2 <= r_y_z1;
              end 
          end 
    end

  // multiply
  assign w_product_a1 = r_y_z1 * -a1_fixed;
  assign w_product_a2 = r_y_z2 * -a2_fixed;
  assign w_product_b0 = r_x    * b0_fixed;
  assign w_product_b1 = r_x_z1 * b1_fixed;
  assign w_product_b2 = r_x_z2 * b2_fixed;

  // accumulate
  assign w_sum = w_product_b0 + w_product_b1 + w_product_b2 + w_product_a1 + w_product_a2;

  // output assignments
  assign m_axis_tdata  = r_y_z1;
  assign m_axis_tvalid = r_m_axis_tvalid;
  assign m_axis_tready = r_m_axis_tready;

endmodule
