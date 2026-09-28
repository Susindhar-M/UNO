`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.09.2026 17:00:17
// Design Name: 
// Module Name: reg_en
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


module reg_en #(
        parameter WIDTH = 8
    )(
        input  wire [WIDTH-1:0] D,
        input  wire             clk,
        input  wire             rst_n,
        input  wire             en,
        output reg  [WIDTH-1:0] Q
    );
    
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Q <= {WIDTH{1'b0}};
        end else if (en) begin
            Q <= D;
        end
    end
    
endmodule
