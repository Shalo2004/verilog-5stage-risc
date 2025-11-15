// cpu_tb.v - self-checking testbench
`timescale 1ns/1ps


module cpu_tb;
    reg clk, rst;
    integer cycle;

    // instantiate cpu_top
    cpu_top DUT(.clk(clk), .rst(rst));

    // helper tasks to assemble MIPS-like instructions
    function [31:0] instr_r;
        input [5:0] funct;
        input [4:0] rs, rt, rd;
        begin
            instr_r = {6'd0, rs, rt, rd, 5'd0, funct};
        end
    endfunction

    function [31:0] instr_i;
        input [5:0] opcode;
        input [4:0] rs, rt;
        input [15:0] imm;
        begin
            instr_i = {opcode, rs, rt, imm};
        end
    endfunction

    initial begin
        // waveform dump
        $dumpfile("cpu_tb.vcd");
        $dumpvars(0,cpu_tb);

        // clock
        clk = 0; rst = 1;
        #20 rst = 0;

        // Initialize register file values via hierarchical access
        // rf is instantiated inside cpu_top as rf
        DUT.rf.regs[2] = 32'd10; // R2 = 10
        DUT.rf.regs[3] = 32'd20; // R3 = 20
        DUT.rf.regs[5] = 32'd5;  // R5 = 5

        // Initialize data memory at address 0 (word 0)
        DUT.dmem.mem[0] = 32'd100;

        // Load instructions into instruction memory mem[]
        // Program (addresses 0,4,...):
        // ADD R1, R2, R3    -> R1 = 10 + 20 = 30
        // ADD R4, R1, R5    -> R4 = 30 + 5 = 35 (requires forwarding)
        // LW  R6, 0(R0)     -> R6 = mem[0] = 100
        // ADD R7, R6, R5    -> R7 = 100 + 5 = 105 (load-use -> hazard)
        // BEQ R2, R3, +2    -> not taken
        // ADD R8, R2, R2    -> R8 = 10 + 10 = 20
        // SUB R9, R3, R5    -> R9 = 20 - 5 = 15

        DUT.imem.mem[0] = instr_r(6'h20, 5'd2, 5'd3, 5'd1); // ADD R1,R2,R3 (funct=32)
        DUT.imem.mem[1] = instr_r(6'h20, 5'd1, 5'd5, 5'd4); // ADD R4,R1,R5
        DUT.imem.mem[2] = instr_i(6'd35, 5'd0, 5'd6, 16'd0); // LW R6,0(R0)
        DUT.imem.mem[3] = instr_r(6'h20, 5'd6, 5'd5, 5'd7); // ADD R7,R6,R5
        DUT.imem.mem[4] = instr_i(6'd4, 5'd2, 5'd3, 16'd2); // BEQ R2,R3, +2 (skip next if equal)
        DUT.imem.mem[5] = instr_r(6'h20, 5'd2, 5'd2, 5'd8); // ADD R8,R2,R2
        DUT.imem.mem[6] = instr_r(6'h22, 5'd3, 5'd5, 5'd9); // SUB R9,R3,R5 (funct=34)

        // run for enough cycles
        for (cycle=0; cycle<120; cycle=cycle+1) begin
            #5 clk = ~clk;
            #5 clk = ~clk;
        end

        // check expected registers
        $display("R1=%0d, expected 30", DUT.rf.read_reg(5'd1));
        $display("R4=%0d, expected 35", DUT.rf.read_reg(5'd4));
        $display("R6=%0d, expected 100", DUT.rf.read_reg(5'd6));
        $display("R7=%0d, expected 105", DUT.rf.read_reg(5'd7));
        $display("R8=%0d, expected 20", DUT.rf.read_reg(5'd8));
        $display("R9=%0d, expected 15", DUT.rf.read_reg(5'd9));

        if (DUT.rf.read_reg(5'd1) == 30 && DUT.rf.read_reg(5'd4) == 35 &&
            DUT.rf.read_reg(5'd6) == 100 && DUT.rf.read_reg(5'd7) == 105 &&
            DUT.rf.read_reg(5'd8) == 20 && DUT.rf.read_reg(5'd9) == 15) begin
            $display("TEST PASSED");
        end else begin
            $display("TEST FAILED");
        end
        $finish;
    end
endmodule
