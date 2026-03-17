module tb_mips_fixed;

    reg clk1, clk2;
    wire [31:0] debug_out;

    pipe_MIPS32_Fixed uut (
        .clk1(clk1), 
        .clk2(clk2),
        .debug_out(debug_out)
    );

    initial begin
        // Initialize Clocks
        clk1 = 0;
        clk2 = 0;

        // 1. ADDI R1, R0, 10   (R1 = 10) 
        // Op:001010, Rs:00000, Rt:00001, Imm:10
        uut.Mem[0] = 32'b001010_00000_00001_0000000000001010; 

        // 2. ADDI R2, R0, 20   (R2 = 20)
        // Op:001010, Rs:00000, Rt:00010, Imm:20
        uut.Mem[1] = 32'b001010_00000_00010_0000000000010100;

        // 3. ADD  R3, R1, R2   (R3 = 10 + 20 = 30)
        // Op:000000, Rs:00001, Rt:00010, Rd:00011 
        uut.Mem[2] = 32'b000000_00001_00010_00011_00000_000000;

        // 4. ADD  R4, R3, R1   (R4 = 30 + 10 = 40) - RAW HAZARD
        // R3 is currently in EX stage. R4 needs it in ID stage
        // Op:000000, Rs:00011(R3), Rt:00001(R1), Rd:00100(R4)
        uut.Mem[3] = 32'b000000_00011_00001_00100_00000_000000;

        // 5. LW   R5, 0(R1)    (Load Mem[10] into R5)
        // Op:LW(001000), Rs:00001(R1), Rt:00101(R5), Imm:0
        uut.Mem[4] = 32'b001000_00001_00101_0000000000000000;
        // Pre-load memory for this test
        uut.Mem[10] = 32'd99; 

        // 6. ADD  R6, R5, R1   (R6 = 99 + 10 = 109) -- LOAD-USE HAZARD!
        // Op:000000, Rs:00101(R5), Rt:00001(R1), Rd:00110(R6)...
        uut.Mem[5] = 32'b000000_00101_00001_00110_00000_000000;

        // 7. HALT
        uut.Mem[6] = 32'b111111_00000_00000_0000000000000000;
        
        $display("Simulation Started...");
    end

    // Clock Generation
    always #5 clk1 = ~clk1;      
    always @(posedge clk1) #2 clk2 = 1; 
    always @(negedge clk1) #2 clk2 = 0; 

    initial begin
        #600;
        $display("------------------------------------------------");
        $display("FINAL REGISTER STATES (The Truth Table)");
        $display("------------------------------------------------");
        $display("R1 (Init): %d (Expected: 10)", uut.Reg[1]);
        $display("R2 (Init): %d (Expected: 20)", uut.Reg[2]);
        $display("R3 (Add) : %d (Expected: 30)", uut.Reg[3]);
        $display("R4 (Fwd) : %d (Expected: 40)", uut.Reg[4]);
        $display("R5 (Load): %d (Expected: 99)", uut.Reg[5]);
        $display("R6 (Stall):%d (Expected: 109)", uut.Reg[6]);
        $display("------------------------------------------------");
        $stop;
    end
endmodule
