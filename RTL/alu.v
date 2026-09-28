`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.08.2026 12:42:27
// Design Name: 
// Module Name: alu
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


    module alu(
        input  wire [7:0] operand_1,
        input  wire [7:0] operand_2,
        input  wire [7:0] operand_3,
        output reg        jmp_flg,
        output reg  [7:0] alu_out
    );
    
    always@* begin        
        alu_out = $signed(operand_1) - $signed(operand_2) - $signed(operand_3);        
        jmp_flg = $signed(operand_1) > $signed(operand_2) ? 1'b1 : 1'b0;  
    end    
    
endmodule
