// instr_memory.v
`timescale 1ns/1ps
module instr_memory(
    input [31:0] pc,
    output [31:0] instr
);
    reg [31:0] mem [0:255];
    initial begin
        // default zero; testbench will overwrite contents or we can keep default sample
        // testbench writes instructions directly by poking mem[] via hierarchical reference
    end
    assign instr = mem[pc[9:2]]; // word aligned index
    // allow testbench to poke mem via hierarchical name
endmodule
