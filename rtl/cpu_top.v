// cpu_top.v
`timescale 1ns/1ps
module cpu_top(
    input clk,
    input rst
);
    // Program Counter
    reg [31:0] pc;
    wire [31:0] instr;
    wire [31:0] pc_plus4 = pc + 4;

    instr_memory imem(.pc(pc), .instr(instr));
    // instantiate regfile
    wire [31:0] rf_rs1, rf_rs2;
    reg [4:0] rf_rd_addr;
    reg [31:0] rf_rd_data;
    reg rf_we;

    reg_file rf(.clk(clk), .we(rf_we), .rd_addr(rf_rd_addr), .rd_data(rf_rd_data),
                .rs1_addr(id_rs1_addr), .rs2_addr(id_rs2_addr),
                .rs1_data(rf_rs1), .rs2_data(rf_rs2));

    // control signals produced in ID stage
    wire cu_reg_write, cu_alu_src, cu_mem_read, cu_mem_write, cu_mem_to_reg, cu_branch;
    wire [3:0] cu_alu_op;

    // decode fields in ID stage
    wire [5:0] id_opcode = if_id_instr[31:26];
    wire [4:0] id_rs     = if_id_instr[25:21];
    wire [4:0] id_rt     = if_id_instr[20:16];
    wire [4:0] id_rd     = if_id_instr[15:11];
    wire [5:0] id_funct  = if_id_instr[5:0];
    wire [15:0] id_imm16 = if_id_instr[15:0];
    wire [31:0] id_imm   = {{16{id_imm16[15]}}, id_imm16};


    // control unit
    control_unit cu(.opcode(id_opcode), .funct(id_funct), .reg_write(cu_reg_write),
                    .alu_src(cu_alu_src), .mem_read(cu_mem_read), .mem_write(cu_mem_write),
                    .mem_to_reg(cu_mem_to_reg), .branch(cu_branch), .alu_op(cu_alu_op));

    // pipeline registers signals (IDs)
    // IF/ID
    reg [31:0] if_id_pc4;
    reg [31:0] if_id_instr;
    // ID/EX
    reg [31:0] id_ex_pc4, id_ex_rs1_val, id_ex_rs2_val, id_ex_imm;
    reg [4:0] id_ex_rs1_addr_wire, id_ex_rs2_addr_wire, id_ex_rd_addr_wire;
    reg id_ex_regwrite, id_ex_alu_src, id_ex_mem_read, id_ex_mem_write, id_ex_mem_to_reg, id_ex_branch;
    reg [3:0] id_ex_alu_op;

    // EX/MEM
    reg [31:0] ex_mem_alu_result, ex_mem_write_data;
    reg [4:0] ex_mem_rd;
    reg ex_mem_regwrite, ex_mem_mem_read, ex_mem_mem_write, ex_mem_mem_to_reg, ex_mem_branch;

    // MEM/WB
    reg [31:0] mem_wb_read_data, mem_wb_alu_result;
    reg [4:0] mem_wb_rd;
    reg mem_wb_regwrite, mem_wb_mem_to_reg;

    // forwarding unit
    wire [1:0] forwardA, forwardB;
    forwarding_unit fwd(
        .id_ex_rs(id_ex_rs1_addr_wire), .id_ex_rt(id_ex_rs2_addr_wire),
        .ex_mem_rd(ex_mem_rd), .ex_mem_regwrite(ex_mem_regwrite),
        .mem_wb_rd(mem_wb_rd), .mem_wb_regwrite(mem_wb_regwrite),
        .forwardA(forwardA), .forwardB(forwardB)
    );

    // hazard unit
    wire pc_write, if_id_write, control_stall;
    hazard_unit hzd(.id_ex_memread(id_ex_mem_read), .id_ex_rt(id_ex_rs2_addr_wire),
                    .if_id_rs(if_id_instr[25:21]), .if_id_rt(if_id_instr[20:16]),
                    .pc_write(pc_write), .if_id_write(if_id_write), .control_stall(control_stall));

    // ALU wires
    reg [31:0] alu_a, alu_b;
    wire [31:0] alu_result;
    wire alu_zero;
    alu ALU(.a(alu_a), .b(alu_b), .alu_ctrl(id_ex_alu_op), .result(alu_result), .zero(alu_zero));

    // data memory
    wire [31:0] data_read;
    data_memory dmem(.clk(clk), .mem_write(ex_mem_mem_write), .mem_read(ex_mem_mem_read),
                     .addr(ex_mem_alu_result), .write_data(ex_mem_write_data), .read_data(data_read));

    // IF stage
    always @(posedge clk or posedge rst) begin
        if (rst) pc <= 0;
        else if (pc_write) begin
            pc <= pc_next;
        end
    end

    wire [31:0] pc_next;
    // branch decision from EX stage (we use ex stage info)
    wire ex_branch_taken = ex_mem_branch & (ex_mem_alu_result == 0); // for BEQ: alu_result zero -> equal
    assign pc_next = ex_branch_taken ? ex_mem_alu_result /*we store branch target in alu_result?*/ : pc_plus4;
    // Note: For simplicity we use branch target in ALU result. In production you'd add calculation.

    // instruction fetch registers
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            if_id_pc4 <= 0; if_id_instr <= 0;
        end else begin
            if (if_id_write) begin
                if_id_pc4 <= pc_plus4;
                if_id_instr <= instr;
            end
        end
    end

    // ID stage: read register file
    wire [4:0] id_rs1_addr = if_id_instr[25:21];
    wire [4:0] id_rs2_addr = if_id_instr[20:16];
    reg [31:0] id_rs1_val, id_rs2_val;

    always @(*) begin
        id_rs1_val = rf_rs1;
        id_rs2_val = rf_rs2;
    end

    // ID/EX register update (on clk)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            id_ex_pc4 <=0; id_ex_rs1_val<=0; id_ex_rs2_val<=0; id_ex_imm<=0;
            id_ex_rs1_addr_wire<=0; id_ex_rs2_addr_wire<=0; id_ex_rd_addr_wire<=0;
            id_ex_regwrite<=0; id_ex_alu_src<=0; id_ex_mem_read<=0; id_ex_mem_write<=0; id_ex_mem_to_reg<=0; id_ex_branch<=0;
            id_ex_alu_op<=0;
        end else begin
            id_ex_pc4 <= if_id_pc4;
            id_ex_rs1_val <= id_rs1_val;
            id_ex_rs2_val <= id_rs2_val;
            id_ex_imm <= id_imm;
            id_ex_rs1_addr_wire <= id_rs1_addr;
            id_ex_rs2_addr_wire <= id_rs2_addr;
            id_ex_rd_addr_wire <= (id_opcode==6'd0) ? id_rd : id_rt; // R-type rd else I-type rt
            if (control_stall) begin
                id_ex_regwrite <= 0;
                id_ex_alu_src <= 0;
                id_ex_mem_read <= 0;
                id_ex_mem_write <= 0;
                id_ex_mem_to_reg <= 0;
                id_ex_branch <= 0;
                id_ex_alu_op <= 0;
            end else begin
                id_ex_regwrite <= cu_reg_write;
                id_ex_alu_src <= cu_alu_src;
                id_ex_mem_read <= cu_mem_read;
                id_ex_mem_write <= cu_mem_write;
                id_ex_mem_to_reg <= cu_mem_to_reg;
                id_ex_branch <= cu_branch;
                id_ex_alu_op <= cu_alu_op;
            end
        end
    end

    // EX stage: ALU inputs with forwarding
    reg [31:0] alu_input1, alu_input2;
    always @(*) begin
        // forwardA
        case (forwardA)
            2'b00: alu_input1 = id_ex_rs1_val;
            2'b10: alu_input1 = ex_mem_alu_result;
            2'b01: alu_input1 = mem_wb_regwrite ? (mem_wb_mem_to_reg ? mem_wb_read_data : mem_wb_alu_result) : 0;
            default: alu_input1 = id_ex_rs1_val;
        endcase

        // forwardB
        case (forwardB)
            2'b00: alu_input2 = id_ex_rs2_val;
            2'b10: alu_input2 = ex_mem_alu_result;
            2'b01: alu_input2 = mem_wb_regwrite ? (mem_wb_mem_to_reg ? mem_wb_read_data : mem_wb_alu_result) : 0;
            default: alu_input2 = id_ex_rs2_val;
        endcase

        alu_a = alu_input1;
        alu_b = id_ex_alu_src ? id_ex_imm : alu_input2;
    end

    // update EX/MEM pipeline register on clk
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ex_mem_alu_result <=0; ex_mem_write_data<=0; ex_mem_rd<=0;
            ex_mem_regwrite<=0; ex_mem_mem_read<=0; ex_mem_mem_write<=0; ex_mem_mem_to_reg<=0; ex_mem_branch<=0;
        end else begin
            ex_mem_alu_result <= alu_result;
            ex_mem_write_data <= alu_input2;
            ex_mem_rd <= id_ex_rd_addr_wire;
            ex_mem_regwrite <= id_ex_regwrite;
            ex_mem_mem_read <= id_ex_mem_read;
            ex_mem_mem_write <= id_ex_mem_write;
            ex_mem_mem_to_reg <= id_ex_mem_to_reg;
            ex_mem_branch <= id_ex_branch;
        end
    end

    // MEM stage -> perform load/store
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mem_wb_read_data <= 0; mem_wb_alu_result <= 0; mem_wb_rd <= 0; mem_wb_regwrite <=0; mem_wb_mem_to_reg<=0;
        end else begin
            // read_data provided by data_memory combinatorial read_data
            mem_wb_read_data <= data_read;
            mem_wb_alu_result <= ex_mem_alu_result;
            mem_wb_rd <= ex_mem_rd;
            mem_wb_regwrite <= ex_mem_regwrite;
            mem_wb_mem_to_reg <= ex_mem_mem_to_reg;
        end
    end

    // WB stage -> writeback to regfile
    always @(*) begin
        rf_we = mem_wb_regwrite;
        rf_rd_addr = mem_wb_rd;
        rf_rd_data = mem_wb_mem_to_reg ? mem_wb_read_data : mem_wb_alu_result;
    end

    // For testbench visibility, expose some signals via hierarchical refs (done in TB)
endmodule
