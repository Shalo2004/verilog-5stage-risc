// control_unit.v
`timescale 1ns/1ps
module control_unit(
    input [5:0] opcode,
    input [5:0] funct,
    output reg reg_write,
    output reg alu_src,    // 0 -> reg, 1 -> imm
    output reg mem_read,
    output reg mem_write,
    output reg mem_to_reg, // 1 -> load, 0 -> ALU
    output reg branch,
    output reg [3:0] alu_op
);
    // Opcodes (simple MIPS-like):
    localparam RTYPE = 6'd0;
    localparam LW    = 6'd35; // 100011
    localparam SW    = 6'd43; // 101011
    localparam BEQ   = 6'd4;  // 000100
    localparam ADDI  = 6'd8;  // 001000

    always @(*) begin
        // defaults
        reg_write = 0; alu_src = 0; mem_read = 0; mem_write = 0;
        mem_to_reg = 0; branch = 0; alu_op = 4'h0;

        case (opcode)
            RTYPE: begin
                reg_write = 1;
                alu_src = 0;
                mem_read = 0; mem_write = 0;
                mem_to_reg = 0;
                branch = 0;
                // decode funct for alu_op
                case(funct)
                    6'h20: alu_op = 4'h0; // add
                    6'h22: alu_op = 4'h1; // sub
                    6'h24: alu_op = 4'h2; // and
                    6'h25: alu_op = 4'h3; // or
                    6'h2A: alu_op = 4'h4; // slt
                    6'h26: alu_op = 4'h5; // xor
                    default: alu_op = 4'h0;
                endcase
            end
            LW: begin
                reg_write = 1;
                alu_src = 1;
                mem_read = 1;
                mem_write = 0;
                mem_to_reg = 1;
                branch = 0;
                alu_op = 4'h0; // add for address calc
            end
            SW: begin
                reg_write = 0;
                alu_src = 1;
                mem_read = 0;
                mem_write = 1;
                mem_to_reg = 0;
                branch = 0;
                alu_op = 4'h0;
            end
            BEQ: begin
                reg_write = 0;
                alu_src = 0;
                mem_read = 0;
                mem_write = 0;
                mem_to_reg = 0;
                branch = 1;
                alu_op = 4'h1; // sub for comparing
            end
            ADDI: begin
                reg_write = 1;
                alu_src = 1;
                mem_read = 0;
                mem_write = 0;
                mem_to_reg = 0;
                branch = 0;
                alu_op = 4'h0; // add
            end
            default: begin
            end
        endcase
    end
endmodule
