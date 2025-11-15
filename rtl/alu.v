// alu.v
`timescale 1ns/1ps
module alu(
    input  [31:0] a,
    input  [31:0] b,
    input  [3:0]  alu_ctrl,
    output reg [31:0] result,
    output zero
);
    assign zero = (result == 32'd0);
    always @(*) begin
        case (alu_ctrl)
            4'h0: result = a + b;          // ADD
            4'h1: result = a - b;          // SUB
            4'h2: result = a & b;          // AND
            4'h3: result = a | b;          // OR
            4'h4: result = (a < b) ? 32'd1 : 32'd0; // SLT
            4'h5: result = a ^ b;          // XOR
            default: result = 32'd0;
        endcase
    end
endmodule
