`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.08.2026 15:19:32
// Design Name: 
// Module Name: adder
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


module pc(
        input wire        clk,
        input wire        rst_n,
        input wire        en, 
        input wire [10:0]  D,
        output reg [13:0] pc_out  // 16kB assumed 
    );
    
    always@(posedge(clk) or negedge(rst_n))
    begin
        if(!rst_n) pc_out <= 14'b0;
        else
        begin
            if(en) pc_out <= pc_out + ($signed({{3{D[10]}}, D}) <<< 3);
            else pc_out <= pc_out;       
        end
    end
endmodule
