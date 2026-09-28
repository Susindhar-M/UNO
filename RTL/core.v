`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.08.2026 13:13:52
// Design Name: 
// Module Name: core
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


`timescale 1ns / 1ps

module core(
    // Global signals
    input  wire        clk,
    input  wire        rst_n,
    
    // Instruction memory interface
    input  wire        instr_gnt,
    output wire        instr_req,
    input  wire [63:0] instr_in,
    output wire [13:0] instr_adr,    
    input  wire        instr_valid,
    
    
    // Data memory interface
    input  wire [7:0]  data_in,
    output wire [7:0]  data_out,
    output wire [14:0] data_adr,
    input  wire        data_gnt,
    output wire        data_req,
    input  wire        data_valid,
    output wire        data_we
);

    // Decoded instruction fields
    wire [14:0] addr_1;
    wire [14:0] addr_2;
    wire [14:0] addr_3;
    wire [10:0] jump;
    wire [7:0]  data;
    
    // Registered instruction signal
    wire [63:0] instr_reg_out;

    assign addr_1 = instr_reg_out[63:49];
    assign addr_2 = instr_reg_out[48:34];
    assign addr_3 = instr_reg_out[33:19];
    assign jump   = instr_reg_out[18:8];
    assign data   = instr_reg_out[7:0];

    // Control signals wires
    wire        pc_en;
    wire        op1_reg_en;
    wire        op2_reg_en;
    wire        operand_mux_sel;
    wire        rdwt_mux_sel;
    wire        instr_reg_en;

    // Internal datapath interconnects
    wire [10:0]  pc_mux_wire;
    wire        jmp_flg_wire;
    wire [14:0] adr_mux_interconnect;
    wire [7:0]  operand_1_wire;
    wire [7:0]  operand_2_wire;

//////////////////////////////////////////////////////////////////////////////////
    
    // Control Unit Path    
    ctrl control_unit(        
            .clk             (clk),
            .rst_n           (rst_n),        
            .pc_en           (pc_en),
            .instr_req       (instr_req),
            .instr_gnt       (instr_gnt),
            .instr_valid     (instr_valid),       
            .data_gnt        (data_gnt),
            .data_req        (data_req),
            .data_valid      (data_valid),
            .data_we         (data_we),
            .operand_mux_sel (operand_mux_sel),
            .rdwt_mux_sel    (rdwt_mux_sel),
            .op1_reg_en      (op1_reg_en),
            .op2_reg_en      (op2_reg_en),
            .instr_reg_en    (instr_reg_en)
        );


    // Program Counter Path   
    mux_2x1 #(.WIDTH(11)) pc_mux (
            .A   (11'h1),
            .B   (jump),
            .sel (jmp_flg_wire),
            .Y   (pc_mux_wire)
        );

    pc pc_inst (
            .D      (pc_mux_wire),
            .pc_out (instr_adr),
            .en     (pc_en),
            .clk    (clk),
            .rst_n  (rst_n)
        );
        
    reg_en #(.WIDTH(64)) instr_reg (
            .clk   (clk),
            .rst_n (rst_n),
            .en    (instr_reg_en),
            .D     (instr_in),
            .Q     (instr_reg_out)
        );

   
    // Memory Fetch / Address Selection Path   
    mux_2x1 #(.WIDTH(15)) operand_mux (
            .A   (addr_1),
            .B   (addr_2),
            .sel (operand_mux_sel),
            .Y   (adr_mux_interconnect)
        );

    mux_2x1 #(.WIDTH(15)) rdwt_mux (
            .A   (adr_mux_interconnect),
            .B   (addr_3),
            .sel (rdwt_mux_sel),
            .Y   (data_adr)
        );

    
    // Operand Registers
    
    reg_en #(.WIDTH(8)) op1_reg (
            .clk   (clk),
            .rst_n (rst_n),
            .en    (op1_reg_en),
            .D     (data_in),
            .Q     (operand_1_wire)
        );

    reg_en #(.WIDTH(8)) op2_reg (
            .clk   (clk),
            .rst_n (rst_n),
            .en    (op2_reg_en),
            .D     (data_in),
            .Q     (operand_2_wire)
        );

    // ALU
    alu alu_inst (
            .operand_1 (operand_1_wire),
            .operand_2 (operand_2_wire),
            .operand_3 (data),
            .alu_out   (data_out),
            .jmp_flg   (jmp_flg_wire)
        );

endmodule
