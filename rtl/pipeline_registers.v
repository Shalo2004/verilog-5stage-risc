// pipeline_registers.v - Corrected version
`timescale 1ns/1ps

module pipeline_registers(
    input clk,
    input rst,

    // IF/ID inputs
    input [31:0] if_pc_plus4,
    input [31:0] if_instr,
    input        if_id_write,

    // IF/ID outputs
    output reg [31:0] id_pc_plus4,
    output reg [31:0] id_instr,

    // ID/EX inputs
    input [31:0] id_pc4_in,
    input [31:0] id_rs1_in,
    input [31:0] id_rs2_in,
    input [31:0] id_imm_in,
    input [4:0]  id_rs1_addr_in,
    input [4:0]  id_rs2_addr_in,
    input [4:0]  id_rd_addr_in,
    input        id_regwrite_in,
    input        id_alu_src_in,
    input        id_mem_read_in,
    input        id_mem_write_in,
    input        id_mem_to_reg_in,
    input        id_branch_in,
    input [3:0]  id_alu_op_in,
    input        control_stall,

    // ID/EX outputs
    output reg [31:0] ex_pc4,
    output reg [31:0] ex_rs1,
    output reg [31:0] ex_rs2,
    output reg [31:0] ex_imm,
    output reg [4:0]  ex_rs1_addr,
    output reg [4:0]  ex_rs2_addr,
    output reg [4:0]  ex_rd_addr,
    output reg        ex_regwrite,
    output reg        ex_alu_src,
    output reg        ex_mem_read,
    output reg        ex_mem_write,
    output reg        ex_mem_to_reg,
    output reg        ex_branch,
    output reg [3:0]  ex_alu_op,

    // EX/MEM inputs
    input [31:0] ex_alu_result_in,
    input [31:0] ex_write_data_in,
    input [4:0]  ex_rd_in,
    input        ex_regwrite_in,
    input        ex_mem_read_in,
    input        ex_mem_write_in,
    input        ex_mem_to_reg_in,
    input        ex_branch_in,

    // EX/MEM outputs
    output reg [31:0] mem_alu_result,
    output reg [31:0] mem_write_data,
    output reg [4:0]  mem_rd,
    output reg        mem_regwrite,
    output reg        mem_mem_read,
    output reg        mem_mem_write,
    output reg        mem_mem_to_reg,
    output reg        mem_branch
);

    // IF/ID stage
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            id_pc_plus4 <= 0;
            id_instr <= 0;
        end else if (if_id_write) begin
            id_pc_plus4 <= if_pc_plus4;
            id_instr    <= if_instr;
        end
    end

    // ID/EX stage
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ex_pc4 <= 0; ex_rs1 <= 0; ex_rs2 <= 0; ex_imm <= 0;
            ex_rs1_addr <= 0; ex_rs2_addr <= 0; ex_rd_addr <= 0;
            ex_regwrite <= 0; ex_alu_src <= 0; ex_mem_read <= 0;
            ex_mem_write <= 0; ex_mem_to_reg <= 0; ex_branch <= 0;
            ex_alu_op <= 0;
        end else begin
            ex_pc4 <= id_pc4_in;
            ex_rs1 <= id_rs1_in;
            ex_rs2 <= id_rs2_in;
            ex_imm <= id_imm_in;
            ex_rs1_addr <= id_rs1_addr_in;
            ex_rs2_addr <= id_rs2_addr_in;
            ex_rd_addr <= id_rd_addr_in;

            if (control_stall) begin
                ex_regwrite <= 0;
                ex_alu_src <= 0;
                ex_mem_read <= 0;
                ex_mem_write <= 0;
                ex_mem_to_reg <= 0;
                ex_branch <= 0;
                ex_alu_op <= 0;
            end else begin
                ex_regwrite <= id_regwrite_in;
                ex_alu_src <= id_alu_src_in;
                ex_mem_read <= id_mem_read_in;
                ex_mem_write <= id_mem_write_in;
                ex_mem_to_reg <= id_mem_to_reg_in;
                ex_branch <= id_branch_in;
                ex_alu_op <= id_alu_op_in;
            end
        end
    end

    // EX/MEM stage
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mem_alu_result <= 0;
            mem_write_data <= 0;
            mem_rd <= 0;
            mem_regwrite <= 0;
            mem_mem_read <= 0;
            mem_mem_write <= 0;
            mem_mem_to_reg <= 0;
            mem_branch <= 0;
        end else begin
            mem_alu_result <= ex_alu_result_in;
            mem_write_data <= ex_write_data_in;
            mem_rd <= ex_rd_in;
            mem_regwrite <= ex_regwrite_in;
            mem_mem_read <= ex_mem_read_in;
            mem_mem_write <= ex_mem_write_in;
            mem_mem_to_reg <= ex_mem_to_reg_in;
            mem_branch <= ex_branch_in;
        end
    end

endmodule
