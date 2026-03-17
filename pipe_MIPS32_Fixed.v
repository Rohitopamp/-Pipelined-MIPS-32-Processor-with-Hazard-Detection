module pipe_MIPS32_Fixed (
    input clk1, 
    input clk2,
    output [31:0] debug_out
);

reg [31:0] PC, IF_ID_IR, IF_ID_NPC;
reg [31:0] ID_EX_IR, ID_EX_NPC, ID_EX_A, ID_EX_B, ID_EX_Imm;
reg [2:0]  ID_EX_type, EX_MEM_type, MEM_WB_type;
reg [31:0] EX_MEM_IR, EX_MEM_ALUOut, EX_MEM_B;
reg        EX_MEM_cond;
reg [31:0] MEM_WB_IR, MEM_WB_ALUOut, MEM_WB_LMD;

reg [31:0] Reg [0:31];
reg [31:0] Mem [0:1023];

// Parameters
parameter ADD=6'b000000, SUB=6'b000001, AND=6'b000010, OR=6'b000011,
          SLT=6'b000100, MUL=6'b000101, HLT=6'b111111, LW=6'b001000,
          SW=6'b001001, ADDI=6'b001010, SUBI=6'b001011, SLTI=6'b001100,
          BNEQZ=6'b001101, BEQZ=6'b001110;

parameter RR_ALU=3'b000, RM_ALU=3'b001, LOAD=3'b010, STORE=3'b011,
          BRANCH=3'b100, HALT=3'b101, NOP_TYPE=3'b110; 
parameter NOP_INSTR = 32'h00000000; 

reg HALTED;
reg TAKEN_BRANCH;
reg STALL_PIPELINE;         
reg [1:0] ForwardA, ForwardB; 

reg [31:0] ALU_InA, ALU_InB; 
reg [4:0]  ID_EX_Rs, ID_EX_Rt, EX_MEM_DestReg, MEM_WB_DestReg;
reg [31:0] WB_Result; 

assign debug_out = Reg[1]; 

integer i;
initial begin
    for (i = 0; i < 32; i = i + 1) Reg[i] = 0;
    HALTED = 0; TAKEN_BRANCH = 0; STALL_PIPELINE = 0;
    PC = 0;
    IF_ID_IR = 0; IF_ID_NPC = 0;
    ID_EX_IR = 0; ID_EX_NPC = 0; ID_EX_A = 0; ID_EX_B = 0; ID_EX_Imm = 0;
    ID_EX_type = 0; ID_EX_Rs = 0; ID_EX_Rt = 0; // Added init
    EX_MEM_IR = 0; EX_MEM_ALUOut = 0; EX_MEM_B = 0; EX_MEM_type = 0;
    MEM_WB_IR = 0; MEM_WB_ALUOut = 0; MEM_WB_LMD = 0; MEM_WB_type = 0;
end

// IF Stage
always @(posedge clk1) begin
    if (!HALTED && !STALL_PIPELINE) begin
        if (((EX_MEM_IR[31:26] == BEQZ) && (EX_MEM_cond == 1)) ||
            ((EX_MEM_IR[31:26] == BNEQZ) && (EX_MEM_cond == 0))) begin
            IF_ID_IR <= Mem[EX_MEM_ALUOut];
            TAKEN_BRANCH <= 1'b1;
            IF_ID_NPC <= EX_MEM_ALUOut + 1;
            PC <= EX_MEM_ALUOut + 1;
        end else begin
            IF_ID_IR <= Mem[PC];
            IF_ID_NPC <= PC + 1;
            PC <= PC + 1;
        end
    end
end

// ID Stage
always @(posedge clk2) begin
    if (!HALTED) begin
        if ((ID_EX_type == LOAD) && ((ID_EX_Rt == IF_ID_IR[25:21]) || (ID_EX_Rt == IF_ID_IR[20:16]))) begin
            STALL_PIPELINE <= 1; 
            ID_EX_type <= NOP_TYPE; 
            ID_EX_IR <= NOP_INSTR; 
        end else begin
            STALL_PIPELINE <= 0; 
            if (IF_ID_IR[25:21] == 0) ID_EX_A <= 0; else ID_EX_A <= Reg[IF_ID_IR[25:21]]; 
            if (IF_ID_IR[20:16] == 0) ID_EX_B <= 0; else ID_EX_B <= Reg[IF_ID_IR[20:16]]; 
            ID_EX_NPC <= IF_ID_NPC;
            ID_EX_IR <= IF_ID_IR;
            ID_EX_Imm <= {{16{IF_ID_IR[15]}}, {IF_ID_IR[15:0]}};
            ID_EX_Rs <= IF_ID_IR[25:21];
            ID_EX_Rt <= IF_ID_IR[20:16];
            case (IF_ID_IR[31:26])
                ADD, SUB, AND, OR, SLT, MUL: ID_EX_type <= RR_ALU;
                ADDI, SUBI, SLTI:            ID_EX_type <= RM_ALU;
                LW:                          ID_EX_type <= LOAD;
                SW:                          ID_EX_type <= STORE;
                BNEQZ, BEQZ:                 ID_EX_type <= BRANCH;
                HLT:                         ID_EX_type <= HALT;
                default:                     ID_EX_type <= NOP_TYPE; 
            endcase
        end
    end
end

// EX Stage
always @(*) begin
    if (EX_MEM_type == RR_ALU) EX_MEM_DestReg = EX_MEM_IR[15:11];
    else if (EX_MEM_type == RM_ALU || EX_MEM_type == LOAD) EX_MEM_DestReg = EX_MEM_IR[20:16];
    else EX_MEM_DestReg = 0; 

    if (MEM_WB_type == RR_ALU) MEM_WB_DestReg = MEM_WB_IR[15:11];
    else if (MEM_WB_type == RM_ALU || MEM_WB_type == LOAD) MEM_WB_DestReg = MEM_WB_IR[20:16];
    else MEM_WB_DestReg = 0;

    if (MEM_WB_type == LOAD) WB_Result = MEM_WB_LMD;
    else WB_Result = MEM_WB_ALUOut;

    ForwardA = 2'b00; ForwardB = 2'b00;
    if (EX_MEM_DestReg != 0 && EX_MEM_DestReg == ID_EX_Rs) ForwardA = 2'b10;
    if (EX_MEM_DestReg != 0 && EX_MEM_DestReg == ID_EX_Rt) ForwardB = 2'b10;
    if (MEM_WB_DestReg != 0 && MEM_WB_DestReg == ID_EX_Rs && ForwardA != 2'b10) ForwardA = 2'b01;
    if (MEM_WB_DestReg != 0 && MEM_WB_DestReg == ID_EX_Rt && ForwardB != 2'b10) ForwardB = 2'b01;

    case (ForwardA) 2'b00: ALU_InA = ID_EX_A; 2'b10: ALU_InA = EX_MEM_ALUOut; 2'b01: ALU_InA = WB_Result; endcase
    case (ForwardB) 2'b00: ALU_InB = ID_EX_B; 2'b10: ALU_InB = EX_MEM_ALUOut; 2'b01: ALU_InB = WB_Result; endcase
end

always @(posedge clk1) begin
    if (!HALTED) begin
        EX_MEM_type <= ID_EX_type;
        EX_MEM_IR <= ID_EX_IR;
        TAKEN_BRANCH <= 0;
        case (ID_EX_type)
            RR_ALU: case (ID_EX_IR[31:26])
                ADD: EX_MEM_ALUOut <= ALU_InA + ALU_InB;
                SUB: EX_MEM_ALUOut <= ALU_InA - ALU_InB;
                MUL: EX_MEM_ALUOut <= ALU_InA * ALU_InB;
                default: EX_MEM_ALUOut <= 0;
            endcase
            RM_ALU: case (ID_EX_IR[31:26])
                ADDI: EX_MEM_ALUOut <= ALU_InA + ID_EX_Imm;
                SUBI: EX_MEM_ALUOut <= ALU_InA - ID_EX_Imm;
                default: EX_MEM_ALUOut <= 0;
            endcase
            LOAD, STORE: begin EX_MEM_ALUOut <= ALU_InA + ID_EX_Imm; EX_MEM_B <= ALU_InB; end
            BRANCH: begin EX_MEM_ALUOut <= ID_EX_NPC + ID_EX_Imm; EX_MEM_cond <= (ALU_InA == 0); end
            NOP_TYPE: EX_MEM_ALUOut <= 0;
        endcase
    end
end

// MEM Stage
always @(posedge clk2) begin
    if (!HALTED) begin
        MEM_WB_type <= EX_MEM_type;
        MEM_WB_IR <= EX_MEM_IR;
        case (EX_MEM_type)
            RR_ALU, RM_ALU: MEM_WB_ALUOut <= EX_MEM_ALUOut;
            LOAD: MEM_WB_LMD <= Mem[EX_MEM_ALUOut];
            STORE: if (!TAKEN_BRANCH) Mem[EX_MEM_ALUOut] <= EX_MEM_B;
        endcase
    end
end

// WB Stage
always @(posedge clk1) begin
    if (!TAKEN_BRANCH) begin
        case (MEM_WB_type)
            RR_ALU: Reg[MEM_WB_IR[15:11]] <= MEM_WB_ALUOut;
            RM_ALU: Reg[MEM_WB_IR[20:16]] <= MEM_WB_ALUOut;
            LOAD: Reg[MEM_WB_IR[20:16]] <= MEM_WB_LMD;
            HALT: HALTED <= 1'b1;
        endcase
    end
end
endmodule
