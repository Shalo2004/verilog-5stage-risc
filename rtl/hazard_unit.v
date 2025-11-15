// hazard_unit.v
`timescale 1ns/1ps
module hazard_unit(
    input id_ex_memread,
    input [4:0] id_ex_rt,
    input [4:0] if_id_rs,
    input [4:0] if_id_rt,
    output reg pc_write,
    output reg if_id_write,
    output reg control_stall
);
    // If next instr depends on a load in EX stage -> stall one cycle
    always @(*) begin
        pc_write = 1;
        if_id_write = 1;
        control_stall = 0;
        if (id_ex_memread && ( (id_ex_rt == if_id_rs) || (id_ex_rt == if_id_rt) )) begin
            // stall
            pc_write = 0;
            if_id_write = 0;
            control_stall = 1; // zero control signals in ID/EX
        end
    end
endmodule
