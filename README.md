# Pipelined MIPS-32 Processor with Hazard Detection

A high-performance 5-stage pipelined MIPS-32 processor core implemented in Verilog. This project focuses on efficient instruction execution by resolving structural, data, and control hazards through **Data Forwarding** and **Pipeline Stalling**.

## 🚀 Features
* [cite_start]**5-Stage Pipeline**: Instruction Fetch (IF), Instruction Decode (ID), Execute (EX), Memory Access (MEM), and Write Back (WB)[cite: 1, 13, 18, 39, 47, 49].
* [cite_start]**Comprehensive ISA**: Supports R-type (ADD, SUB, MUL, SLT), I-type (ADDI, LW, SW, BEQZ, BNEQZ), and J-type (HALT) instructions[cite: 4, 21, 22, 23, 24, 25, 26].
* [cite_start]**Data Forwarding Unit**: Resolves Read-After-Write (RAW) hazards by forwarding results from the EX and MEM stages directly to the ALU[cite: 31, 32, 33, 34, 35, 36, 37].
* [cite_start]**Hazard Detection & Stalling**: Automatically detects Load-Use hazards and stalls the pipeline to maintain data integrity[cite: 17, 18].
* [cite_start]**Branch Handling**: Implements branch logic in the EX stage with PC updates to manage control flow[cite: 13, 45].

---

## 🏗️ Architecture Overview

### Pipeline Stages
* [cite_start]**IF (Instruction Fetch)**: Fetches the instruction from memory based on the Program Counter (PC)[cite: 13, 15, 16].
* [cite_start]**ID (Instruction Decode)**: Decodes instructions, reads registers, and generates immediate values[cite: 19, 20, 21].
* [cite_start]**EX (Execute)**: Performs ALU operations, calculates branch targets, and manages data forwarding[cite: 39, 40, 41, 44, 45].
* [cite_start]**MEM (Memory Access)**: Handles Load (LW) and Store (SW) operations with the data memory[cite: 48].
* [cite_start]**WB (Write Back)**: Writes the final result or loaded data back into the register file[cite: 49, 50].

### Hazard Management
* [cite_start]**Forwarding**: The `ForwardA` and `ForwardB` signals detect if a source register matches a destination register in the pipeline and bypasses the register file[cite: 32, 33, 34, 35].
* [cite_start]**Load-Use Stalling**: If an instruction requires data from a `LW` instruction currently in the pipeline, the `STALL_PIPELINE` signal is asserted, and a `NOP` (No-Operation) is inserted[cite: 17, 18].

---

## 💻 Instruction Set Architecture (ISA)

| Instruction | Type | Opcode | Description |
| :--- | :--- | :--- | :--- |
| **ADD / SUB** | R | `000000` / `000001` | [cite_start]Arithmetic operations between registers[cite: 4, 21]. |
| **ADDI** | I | `001010` | [cite_start]Add immediate value to a register[cite: 4, 22]. |
| **LW / SW** | I | `001000` / `001001` | [cite_start]Load word from / Store word to memory[cite: 4, 23, 24]. |
| **BEQZ / BNEQZ**| I | `001110` / `001101` | [cite_start]Branch if register is zero or not zero[cite: 4, 25]. |
| **HALT** | J | `111111` | [cite_start]Terminate program execution[cite: 4, 26]. |

---

## 🧪 Simulation & Testing

[cite_start]The provided testbench (`tb_mips_fixed.v`) verifies the processor's ability to handle complex instruction sequences[cite: 51, 62].

### Sample Test Case Execution
* [cite_start]**Initialize**: Set R1=10, R2=20[cite: 53, 54].
* **RAW Hazard**: `ADD R3, R1, R2` followed by `ADD R4, R3, R1`. [cite_start]The Forwarding Unit passes R3's value directly to the next instruction[cite: 55, 56, 57].
* **Load-Use Hazard**: `LW R5, 0(R1)` followed by `ADD R6, R5, R1`. [cite_start]The pipeline stalls for one cycle to allow the load to complete[cite: 58, 60, 61].

### Expected Output
```text
FINAL REGISTER STATES
R1 (Init): 10
R2 (Init): 20
R3 (Add) : 30
R4 (Fwd) : 40
R5 (Load): 99
R6 (Stall):109
