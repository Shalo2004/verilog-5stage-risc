# 🔥 32-bit 5-Stage Pipelined RISC Processor (Verilog HDL)

![verilog](https://img.shields.io/badge/HDL-Verilog-blue)
![simulation](https://img.shields.io/badge/Sim-Icarus%20Verilog-green)
![pipeline](https://img.shields.io/badge/Type-Pipelined%20CPU-orange)
![status](https://img.shields.io/badge/Build-Passed-brightgreen)

---

## 📌 Project Overview

This project implements a **32-bit 5-stage pipelined RISC CPU** in Verilog HDL.  
It supports instruction fetch, decode, execute, memory access, and write-back stages — just like a real processor core used in embedded systems.

This design includes:
- Full pipelining (IF → ID → EX → MEM → WB)
- Forwarding & hazard detection
- Memory load/store
- Branch execution
- Self-checking simulation testbench

The CPU is verified using **Icarus Verilog** and produces correct results for all test programs.

---

## 🚀 Features

### ✔ CPU Architecture
- 32-bit datapath  
- 5 pipeline stages  
- Harvard-style memory separation  
- Word-addressable instruction & data memory  

### ✔ Functional Units
- **32-bit ALU** (ADD, SUB, AND, OR, XOR, SLT)
- **32×32 Register File**
- **Control Unit** (opcode + funct decoding)

### ✔ Pipeline Support
- Pipeline registers for each stage
- Forwarding (EX/MEM → EX and MEM/WB → EX)
- Hazard detection for LW-use stalls
- Branch handling (BEQ)

### ✔ Verification
- Fully automated testbench
- Reference output checking
- Waveform generation (`cpu_tb.vcd`)

---

## 🧠 CPU Pipeline Architecture

### Pipeline Stages

```
IF → ID → EX → MEM → WB
```

### ASCII Diagram

```
                 ┌──────────┐
                 │ Instr Mem│
                 └─────┬────┘
                       ▼
        ┌───────┐  ┌────────┐  ┌────────┐   ┌────────┐  ┌────────┐
IF ---> │  PC   │→ │  IF/ID │→ │ ID/EX  │→  │ EX/MEM │→ │ MEM/WB  │ → WB
        └───────┘  └────────┘  └────────┘   └────────┘  └────────┘
                       │           │             │           │
                       ▼           ▼             ▼           ▼
                      Decode     Execute       Memory      Writeback
```

### Hazard Handling Diagram

```
LW R6, 0(R0)
ADD R7, R6, R5   ← stall needed

Hazard Unit -> Stall 1 cycle
Forwarding Unit -> Resolves further dependencies
```

---

## 📦 Repository Structure

```
rtl/               → Verilog source files
tb/                → Testbench
docs/              → Diagrams, screenshots
cpu_tb.vcd         → Waveform (generated after running)
README.md          → Project documentation
```

---

## ▶️ How to Run the Simulation

### **1. Install Icarus Verilog**
Download from: https://bleyer.org/icarus/

### **2. Compile the project**
```bash
iverilog -o cpu_tb tb/cpu_tb.v rtl/*.v
```

### **3. Run the testbench**
```bash
vvp cpu_tb
```

### **4. View waveforms (optional)**
```bash
gtkwave cpu_tb.vcd
```

---

## 🎯 Expected Output

```
R1=30, expected 30
R4=35, expected 35
R6=100, expected 100
R7=105, expected 105
R8=20, expected 20
R9=15, expected 15
TEST PASSED
```

This means:
- Forwarding works  
- Hazard detection works  
- Load-use stall inserted correctly  
- Branch not taken  
- All instructions executed successfully  

---

## 🧪 Test Program Used

The testbench loads:

```
ADD  R1, R2, R3       -> 30
ADD  R4, R1, R5       -> forwarding
LW   R6, 0(R0)        -> 100
ADD  R7, R6, R5       -> stall + forward
BEQ  R2, R3, +2       -> not taken
ADD  R8, R2, R2       -> 20
SUB  R9, R3, R5       -> 15
```

---

## 🔧 RTL Modules

| Module | Description |
|--------|-------------|
| `alu.v` | 32-bit ALU operations |
| `reg_file.v` | 32×32 register file |
| `control_unit.v` | Decodes opcode + funct |
| `forwarding_unit.v` | Fixes EX and MEM hazards |
| `hazard_unit.v` | Inserts stall on load-use |
| `instr_memory.v` | Program memory |
| `data_memory.v` | Data RAM |
| `pipeline_registers.v` | Pipeline stage registers |
| `cpu_top.v` | CPU integration module |

---

## 📘 Future Improvements

- Add **JUMP**, **JR**, **BNE**, **ANDI**, **ORI** instructions  
- Add **multiply / divide unit**  
- Add **instruction and data cache**  
- Support **$readmemh** program loading  
- Add **branch prediction**  

---

## 📝 License

This project is released under the **MIT License**.

---

## ✨ Author

**Shalo Sharjan**  
Verilog / Embedded / System Design Developer  
