`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.08.2026 18:30:57
// Design Name: 
// Module Name: ctrl
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


module ctrl(
        // global signal
        input wire  clk,
        input wire  rst_n,
        
        // instr_signals
        output reg pc_en,
        output reg instr_req,
        input wire instr_gnt, 
        input wire instr_valid,
        output reg instr_reg_en,
        
        // data_signals
        input wire data_gnt,
        output reg data_req,
        input wire data_valid,
        output reg data_we,
        output reg operand_mux_sel,
        output reg rdwt_mux_sel,
        output reg op1_reg_en,
        output reg op2_reg_en
    );   
    
    localparam instr_adr  = 4'b0000;
    localparam instr_data = 4'b0001;
    localparam op1_adr    = 4'b0010;
    localparam op1_data   = 4'b0011;
    localparam op2_adr    = 4'b0100;
    localparam op2_data   = 4'b0101;
    localparam str_adr    = 4'b0110;
    localparam str_data   = 4'b0111;
    reg [3:0] cur_state, nxt_state;
    
    always@(posedge(clk) or negedge(rst_n)) begin
        if(~rst_n) begin
            cur_state <= instr_adr;
        end
        else begin
            cur_state <= nxt_state;        
        end      
    end            
    
    always@(*) begin
        nxt_state = cur_state;        
        
        case(cur_state)
        
            instr_adr  : begin
                    if(instr_gnt) begin
                        nxt_state = instr_data;
                    end
                end
                
            instr_data : begin
                if(instr_valid) begin
                        nxt_state = op1_adr;
                    end
                end
                
            op1_adr: begin
                if (data_gnt) begin
                        nxt_state = op1_data;
                    end
                end
            
            op1_data: begin
                if (data_valid) begin
                        nxt_state = op2_adr;
                    end
                end
                
            op2_adr: begin
                if (data_gnt) begin
                        nxt_state = op2_data;
                    end
                end
                
            op2_data: begin
                if (data_valid) begin
                        nxt_state = str_adr; 
                    end
                end                 
                
            str_adr: begin
                if (data_gnt) begin
                        nxt_state = str_data;
                    end
                end
                
            str_data: nxt_state = instr_adr;
            
            default: nxt_state = instr_adr;
                    
        endcase    
    end
    
    always@(*) begin
    
        pc_en           = 1'b0;
        instr_req       = 1'b0;
        data_req        = 1'b0;
        data_we      = 1'b0;
        operand_mux_sel = 1'b0;
        rdwt_mux_sel    = 1'b0;
        op1_reg_en      = 1'b0;
        op2_reg_en      = 1'b0;
        instr_reg_en    = 1'b0;
        
        
        case(cur_state)
            instr_adr  : begin
                    
                    instr_req = 1'b1;
                end
            
            instr_data : begin
                    instr_reg_en = 1'b1;
            end
            
            op1_adr: begin
            data_req        = 1'b1;
            rdwt_mux_sel    = 1'b0; // Select read address path
            operand_mux_sel = 1'b0; // Select addr_1
        end

        op1_data: begin
            rdwt_mux_sel    = 1'b0;
            operand_mux_sel = 1'b0;
            op1_reg_en      = 1'b1; // Latch data_in into op1_reg
        end

        op2_adr: begin
            data_req        = 1'b1;
            rdwt_mux_sel    = 1'b0; // Select read address path
            operand_mux_sel = 1'b1; // Select addr_2
        end

        op2_data: begin
            rdwt_mux_sel    = 1'b0;
            operand_mux_sel = 1'b1;
            op2_reg_en      = 1'b1; // Latch data_in into op2_reg
        end

        str_adr: begin
            data_req     = 1'b1;
            rdwt_mux_sel = 1'b1;    // Select addr_3 (write destination)
        end

        str_data: begin
            rdwt_mux_sel = 1'b1;
            data_we      = 1'b1;
            pc_en     = 1'b1;
        end

        default: begin
            pc_en           = 1'b0;
            instr_req       = 1'b0;
            data_req        = 1'b0;
            data_we         = 1'b0;
            operand_mux_sel = 1'b0;
            rdwt_mux_sel    = 1'b0;
            op1_reg_en      = 1'b0;
            op2_reg_en      = 1'b0;
            instr_reg_en    = 1'b0;
        end
                    
        endcase    
    end
    
    
    
    
     
endmodule
