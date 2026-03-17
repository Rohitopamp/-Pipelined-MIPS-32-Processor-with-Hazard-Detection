# -Pipelined-MIPS-32-Processor-with-Hazard-Detection
A high-performance 5-stage pipelined MIPS-32 processor core implemented in Verilog. This project focuses on efficient instruction execution by resolving structural, data, and control hazards through Data Forwarding and Pipeline Stalling.
🚀 Features
5-Stage Pipeline: Instruction Fetch (IF), Instruction Decode (ID), Execute (EX), Memory Access (MEM), and Write Back (WB).
Comprehensive ISA: Supports R-type (ADD, SUB, MUL, SLT), I-type (ADDI, LW, SW, BEQZ, BNEQZ), and J-type (HALT) instructions.
Data Forwarding Unit: Resolves Read-After-Write (RAW) hazards by forwarding results from the EX and MEM stages directly to the ALU.
Hazard Detection & Stalling: Automatically detects Load-Use hazards and stalls the pipeline to maintain data integrity.
Branch Handling: Implements branch logic in the EX stage with PC updates to manage control flow.
🛠 Architecture Overview
Pipeline Stages
IF (Instruction Fetch): Fetches the instruction from memory based on the Program Counter (PC).
ID (Instruction Decode): Decodes instructions, reads registers, and generates immediate values.
EX (Execute): Performs ALU operations, calculates branch targets, and manages data forwarding.
MEM (Memory Access): Handles Load (LW) and Store (SW) operations with the data memory.
WB (Write Back): Writes the final result or loaded data back into the register file.
Hazard Management
Forwarding: The ForwardA and ForwardB signals detect if a source register matches a destination register in the pipeline and bypasses the register file.
Load-Use Stalling: If an instruction requires data from a LW instruction currently in the pipeline, the STALL_PIPELINE signal is asserted, and a NOP (No-Operation) is inserted.
💻 Instruction Set Architecture (ISA)
Instruction          Type          Opcode          Description
ADD / SUB             R         000000 / 000001    Arithmetic operations between registers.
ADDI                  I            001010          Add immediate value to a register.
LW / SW               I         001000 / 001001    Load word from / Store word to memory.
BEQZ / BNEQZ          I         001110 / 001101    Branch if register is zero or not zero.
HALT                  J            111111          Terminate program execution.
🧪 Simulation & Testing
The provided testbench (tb_mips_fixed.v) verifies the processor's ability to handle complex instruction sequences, including back-to-back operations that trigger the forwarding unit and load-use stalls.
Sample Test Case Execution:
Initialize: Set R1=10, R2=20.
RAW Hazard: ADD R3, R1, R2 followed by ADD R4, R3, R1. The Forwarding Unit passes R3's value directly to the next instruction.
Load-Use Hazard: LW R5, 0(R1) followed by ADD R6, R5, R1. The pipeline stalls for one cycle to allow the load to complete.
Expected Output:
FINAL REGISTER STATES
R1 (Init): 10
R2 (Init): 20
R3 (Add) : 30
R4 (Fwd) : 40
R5 (Load): 99
R6 (Stall):109
