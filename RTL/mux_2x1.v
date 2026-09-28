`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.08.2026 13:23:59
// Design Name: 
// Module Name: mux_2x1
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


module mux_2x1 #(
        parameter WIDTH = 15
    )(
        input  wire [WIDTH-1:0] A, B,
        input  wire             sel,
        output wire [WIDTH-1:0] Y
    );
    
    assign Y = sel ? B : A; 
    
endmodule
