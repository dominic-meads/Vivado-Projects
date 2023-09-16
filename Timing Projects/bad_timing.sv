`timescale 1ns/1ps

module badtiming (
    input logic clk,
    input logic rst_n,
    input logic [3:0] switches,
    input logic [3:0] buttons,
    output logic [7:0] result
);

    logic [7:0] reg_a = 4'h0;
    logic [7:0] reg_b = 4'h0;

    always_ff @( posedge clk ) begin
        if (negedge rst_n)
            begin 
                result <= 4'h0;
                reg_a <= 4'h0;
                reg_b <= 4'h0;
            end 
        else 
            begin 
                reg_a <= switches;
                reg_b <= reg_a;
                result <= reg_b;  
            end       
    end

    always_comb begin 

        reg_a = switches[3:0] * buttons [1:0] & switches[1] ^ switches[2] | switches [3] + switches[2:0] * buttons[2:0] ^ buttons[2:1] + switches[3:0];
        
        
    end
    
endmodule
