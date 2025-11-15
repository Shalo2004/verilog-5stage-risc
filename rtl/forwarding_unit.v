// forwarding_unit.v
`timescale 1ns/1ps
module forwarding_unit(
    input [4:0] id_ex_rs, id_ex_rt,
    input [4:0] ex_mem_rd,
    input ex_mem_regwrite,
    input [4:0] mem_wb_rd,
    input mem_wb_regwrite,
    output reg [1:0] forwardA,
    output reg [1:0] forwardB
);
    // 00 = from regfile, 10 = from EX/MEM (ALU result), 01 = from MEM/WB
    always @(*) begin
        forwardA = 2'b00;
        forwardB = 2'b00;
        // EX hazard
        if (ex_mem_regwrite && (ex_mem_rd != 0) && (ex_mem_rd == id_ex_rs)) forwardA = 2'b10;
        if (ex_mem_regwrite && (ex_mem_rd != 0) && (ex_mem_rd == id_ex_rt)) forwardB = 2'b10;
        // MEM hazard (lower priority)
        if (mem_wb_regwrite && (mem_wb_rd != 0) && (mem_wb_rd == id_ex_rs) && !(ex_mem_regwrite && (ex_mem_rd !=0) && (ex_mem_rd == id_ex_rs))) forwardA = 2'b01;
        if (mem_wb_regwrite && (mem_wb_rd != 0) && (mem_wb_rd == id_ex_rt) && !(ex_mem_regwrite && (ex_mem_rd !=0) && (ex_mem_rd == id_ex_rt))) forwardB = 2'b01;
    end
endmodule
