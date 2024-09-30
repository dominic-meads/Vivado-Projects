`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Dominic Meads
// 
// Create Date: 09/2/2024 10:44:56 PM
// Design Name: 
// Module Name: ADC_behav
// Project Name: 
// Target Devices: 7 Series
// Tool Versions: 
// Description: Behavioral model of MCP3202 ADC chip. Verfies timing, and sends out 40 samples of data @ fs = 500 Hz 
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

module ADC_behav #(
  parameter FCLK  = 100e6, // clk frequency
  parameter FSMPL = 500,   // sampling freqeuncy 
  parameter SGL   = 1,     // sets ADC to single-ended
  parameter ODD   = 0      // sets ADC sample input to channel 0 
)(
  input cs,
  input sck,
  input mosi,
  output reg miso
);

  reg [11:0] r_tst_smpl = 12'h000; // miso test sample word 
  
  integer TCSH_start = 0;
  integer TCSH = 0;
  integer TSUCS_start = 0;
  integer TSUCS = 0;
  integer sck_period_start = 0;
  integer sck_period = 0;

  task tx_sample ();  // waits for cs to be active (low), and transmits sample
    begin
      wait (~cs) // cs low, start conversion. Check TCSH timing
        begin
          $display("Initiating new sample transmission");
          TCSH = $time - TCSH_start;
          TSUCS_start = $time;
          sck_period_start = $time;
          if (TCSH >= 500)
            $display("TCSH timing statisifed");
          else 
            $fatal(1,"TCSH timing failed. Must be >= 500 ns");

          wait(sck) // first sck rising edge after cs enable, ADC will check start bit. TSCUS min timing must be satisfied. 
            begin
              TSUCS = $time - TSUCS_start;
              if (TSUCS >= 100)
                $display("TSUCS timing statisifed");
              else 
                $fatal(1,"TSUCS timing failed. Must be >= 100 ns");
              if (mosi == 1'b1)
                $display("START bit received");
              else 
                $display("START bit not received in time");
            end

          wait(~sck)  // wait for sck to go back to low (one full period), check freqeuncy. 10 kHz <= SCLK <= 900 kHz @ Vcc = 3.3 V. See "6.2 Maintaining Minimum Clock Speed"
            begin
              sck_period = $time - sck_period_start;
              if (sck_period <= 100000 && sck_period >= 1112)
                $display("sck frequency ok");
              else if (sck_period > 100000)
                $fatal(1,"sck frequency too low. Must be >= 10 kHz");
              else if (sck_period < 1112)
                $fatal(1,"sck frequency too low. Must be <= 900 kHz");
            end 

          wait(sck)  // Check SGL/DIFF bit on rising edge of SCK
            begin
              if (mosi == 1'b1)
                $display("set to single-ended mode");
              else
                $display("set to differential mode");
            end

          wait(~sck) wait(sck)  // check ODD/SIGN bit on posedge SCK
            begin
              if (mosi == 1'b1)
                $display("sampling on channel 1");
              else
                $display("sampling on channel 0");
            end
          
          wait(~sck) wait(sck)  // check MSBF bit on posedge SCK
            begin 
              if (mosi == 1'b1)
                $display("set to MSBF mode");
              else
                $display("set to LSBF mode");
            end

          wait(~sck)  // TX null bit on negedge SCK after enable time = 200 ns (max)
            begin 
              #200 // TEN max (SCK falling edge to DOUT enable)
              miso = 0; 
            end

          wait(sck) wait(~sck)  // TX MSB of sample on negedge SCK
            miso = r_tst_smpl[11];

          wait(sck) wait(~sck)  // TX bit 10 of sample on negedge SCK
            miso = r_tst_smpl[10];

          wait(sck) wait(~sck)  // TX bit 9 of sample on negedge SCK
            miso = r_tst_smpl[9];

          wait(sck) wait(~sck)  // TX bit 8 of sample on negedge SCK
            miso = r_tst_smpl[8];

          wait(sck) wait(~sck)  // TX bit 7 of sample on negedge SCK
            miso = r_tst_smpl[7];

          wait(sck) wait(~sck)  // TX bit 6 of sample on negedge SCK
            miso = r_tst_smpl[6];

          wait(sck) wait(~sck)  // TX bit 5 of sample on negedge SCK
            miso = r_tst_smpl[5];

          wait(sck) wait(~sck)  // TX bit 4 of sample on negedge SCK
            miso = r_tst_smpl[4];

          wait(sck) wait(~sck)  // TX bit 3 of sample on negedge SCK
            miso = r_tst_smpl[3];

          wait(sck) wait(~sck)  // TX bit 2 of sample on negedge SCK
            miso = r_tst_smpl[2];

          wait(sck) wait(~sck)  // TX bit 1 of sample on negedge SCK
            miso = r_tst_smpl[1];

          wait(sck) wait(~sck)  // TX bit 0 of sample on negedge SCK
            miso = r_tst_smpl[0];

          wait(cs)
            begin 
              miso  = 1'bz;
              r_tst_smpl = r_tst_smpl + 1; 
            end   
        end
    end 
  endtask

  initial 
    begin 
      repeat(70)
        begin 
          TCSH_start = $time;
          tx_sample();
          
        end
    end

endmodule 
