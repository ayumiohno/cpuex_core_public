module execute_line (
    input logic clk,
    rstN,
    en,
    input logic [6:0] ALUControlE,
    input logic [226:0] FPUResults,
    output logic ready,
    output logic [31:0] Result
);

  typedef enum logic [2:0] {
    DEFAULT,
    FPU_END,
    FPU_WAIT4,
    FPU_WAIT3,
    FPU_WAIT2,
    FPU_WAIT1
  } fpustate_t;

  fpustate_t fpustate;

  initial begin
    fpustate = DEFAULT;
  end

  assign ready = fpustate == FPU_END;

  logic [6:0] ALUControlSave;

  parameter FADD = 7'b1000000;
  parameter FSUB = 7'b1000001;
  parameter FMUL = 7'b1000010;
  parameter FDIV = 7'b1000011;
  parameter FEQ = 7'b1000100;
  parameter FLT = 7'b1000101;
  parameter FLE = 7'b1000110;
  parameter FSQRT = 7'b1000111;
  parameter FCVTWS = 7'b1001111;
  parameter FCVTSW = 7'b1010111;

  always @(posedge clk) begin
    if (ALUControlE[6] & en) begin
      // $display("SrcAE: %h, SrcBE: %h, ALUControlE: %h", SrcAE, SrcBE, ALUControlE);
      case (ALUControlE)
        FADD: begin
          fpustate <= FPU_WAIT2;  //FADD
        end
        FSUB: begin
          fpustate <= FPU_WAIT2;  //FSUB
        end
        FMUL: begin
          fpustate <= FPU_WAIT1;  //FMUL
        end
        FDIV: begin
          fpustate <= FPU_WAIT3;  //FDIV
        end
        FSQRT: begin
          fpustate <= FPU_WAIT2;  //FSQRT
        end
        FCVTWS: begin
          fpustate <= FPU_WAIT1;  //fcvt.w.s
        end
        FCVTSW: begin
          fpustate <= FPU_WAIT1;  //fcvt.s.w
        end
        default: fpustate <= FPU_END;
      endcase
    end else begin
      case (fpustate)
        FPU_WAIT1: fpustate <= FPU_END;
        FPU_WAIT2: fpustate <= FPU_WAIT1;
        FPU_WAIT3: fpustate <= FPU_WAIT2;
        FPU_WAIT4: fpustate <= FPU_WAIT3;
        FPU_END:   fpustate <= DEFAULT;
        default:   fpustate <= DEFAULT;
      endcase
    end
    if (en) begin
      ALUControlSave <= ALUControlE;
    end
  end
  always_comb
    case (ALUControlSave)
      FADD: Result = FPUResults[31:0];
      FSUB: Result = FPUResults[63:32];
      FMUL: Result = FPUResults[95:64];
      FDIV: Result = FPUResults[127:96];
      FSQRT: Result = FPUResults[159:128];
      FEQ: Result = {31'b0, FPUResults[160]};
      FLE: Result = {31'b0, FPUResults[161]};
      FLT: Result = {31'b0, FPUResults[162]};
      FCVTWS: Result = FPUResults[194:163];
      FCVTSW: Result = FPUResults[226:195];
      default: Result = 32'bx;
    endcase

endmodule

module state_manager (
    input logic clk,
    rstN,
    input logic [31:0] ALUResultE,
    FPUResult,
    PCPlus4E,
    input logic [6:0] ALUControlE,
    input logic [1:0] BranchControlE,
    input logic [17:0] PCE,
    input logic [5:0] RdE,
    input logic ready,
    write_en,
    read_en,
    flash_en,
    output logic [31:0] Result,
    output logic [17:0] PC,
    output logic [5:0] Rd,
    valid_Rd,
    invalid_Rd,
    output logic valid,
    used
);
  always @(posedge clk) begin
    if (write_en) begin
      used <= 1;
      Rd   <= RdE;
      if (ALUControlE[6]) begin
        valid <= 0;
        valid_Rd <= 0;
        invalid_Rd <= RdE;
      end else begin
        valid <= 1;
        valid_Rd <= RdE;
        invalid_Rd <= 0;
        Result <= ALUResultE;
      end
      PC <= PCE;
    end else if (read_en) begin
      used <= 0;
      Rd <= 0;
      valid <= 0;
      valid_Rd <= 0;
      invalid_Rd <= 0;
    end else if (flash_en) begin
      used <= 0;
      Rd <= 0;
      valid <= 0;
      valid_Rd <= 0;
      invalid_Rd <= 0;
      // if (used)
      //   if (Rd[5]) $display("f%d: skip at %h", Rd[4:0], PC);
      //   else $display("r%d: skip at %h", Rd[4:0], PC);
    end else if (ready) begin
      valid <= 1;
      valid_Rd <= Rd;
      invalid_Rd <= 0;
      Result <= FPUResult;
    end
  end
endmodule

module alu_mem_reg (
    input logic clk,
    core_en,
    rstN,
    LwD1,
    LwE1,
    LwE2,
    MemWriteE1,
    MemWriteE2,
    JumpE1,
    JumpE2,
    stall_m,
    wb_valid,
    BranchE1,
    negE1,
    predictE1,
    BranchE2,
    negE2,
    predictE2,
    input logic [5:0] Rs1D1,
    Rs2D1,
    Rs1E1,
    Rs2E1,
    RdE1,
    Rs1D2,
    Rs2D2,
    Rs1E2,
    Rs2E2,
    RdE2,
    RdD1,
    RdW_mem,
    input logic [31:0] SrcAE1,
    SrcBE1,
    SrcAE2,
    SrcBE2,
    ImmExtE1,
    ImmExtE2,
    PCPlus4E1,
    PCPlus4E2,
    WriteDataE1,
    WriteDataE2,
    input logic [6:0] ALUControlE1,
    ALUControlE2,
    input logic [1:0] BranchControlE1,
    BranchControlE2,
    output logic [31:0] MemAddrM,
    ALUResultW1,
    ALUResultW2,
    WriteDataM,
    FWDataAE1,
    FWDataBE1,
    FWDataAE2,
    FWDataBE2,
    output logic [5:0] RdM,
    RdW1,
    RdW2,
    output logic StallE1,
    StallE2,
    lwStallE1,
    lwStallE2,
    MemWriteM,
    LwM,
    printM,
    scanM,
    ZeroE1,
    ZeroE2,
    matchA1,
    matchB1,
    matchA2,
    matchB2,
    flash_m,
    flash_w_mem,
    BranchFailE1,
    BranchFailE2,
    alu_read_en1,
    alu_read_en2,
    input logic [17:0] PCE1,
    PCE2,
    output logic [17:0] PCM,
    PCW1,
    PCW2
);

  logic valid1, valid2, valid3, valid4;
  logic used1, used2, used3, used4;
  logic [5:0] Rd1, Rd2, Rd3, Rd4;
  logic [31:0] ALUResultE1, ALUResultE2, ALUResultE3, ALUResultE4;
  logic [31:0] ALUResultE1_fpu, ALUResultE2_fpu, ALUResultE3_fpu, ALUResultE4_fpu;
  logic [31:0] WriteData1, WriteData2, WriteData3, WriteData4;
  logic ready1, ready2, ready3, ready4;
  logic [5:0] valid_Rd1, valid_Rd2, valid_Rd3, valid_Rd4;
  logic [5:0] invalid_Rd1, invalid_Rd2, invalid_Rd3, invalid_Rd4;

  // For Debug
  logic [17:0] PC1, PC2, PC3, PC4;

  logic [31:0] ALUResultE_1, ALUResultE_2, ALUResultE_1_tmp, ALUResultE_2_tmp;

  assign BranchFailE1 = BranchE1 & ~operand_invalid1 & ((negE1 ^ ZeroE1) ^ predictE1);
  assign BranchFailE2 = BranchE2 & ~operand_invalid2 & ((negE2 ^ ZeroE2) ^ predictE2);

  logic operand_invalid1, operand_invalid2;
  assign operand_invalid1 = (Rs1E1 != 0 & (Rs1E1 == invalid_Rd1 | Rs1E1 == invalid_Rd2 | Rs1E1 == invalid_Rd3 | Rs1E1 == invalid_Rd4))
            | (Rs2E1 != 0 & (Rs2E1 == invalid_Rd1 | Rs2E1 == invalid_Rd2 | Rs2E1 == invalid_Rd3 | Rs2E1 == invalid_Rd4));
  assign operand_invalid2 = (Rs1E2 != 0 & (Rs1E2 == invalid_Rd1 | Rs1E2 == invalid_Rd2 | Rs1E2 == invalid_Rd3 | Rs1E2 == invalid_Rd4 | Rs1E2 == RdE1))
            | (Rs2E2 != 0 & (Rs2E2 == invalid_Rd1 | Rs2E2 == invalid_Rd2 | Rs2E2 == invalid_Rd3 | Rs2E2 == invalid_Rd4 | Rs2E2 == RdE1))
            | (RdE1 != 0 & RdE1 == RdE2) | (BranchE1 & operand_invalid1);
  logic dst_invalid2;
  assign dst_invalid2 = (RdE2 != 0 & (Rs1E1 == RdE2 | Rs2E1 == RdE2)) & StallE1;

  logic mem_stall1, mem_stall2;
  assign mem_stall1 = mem_en1 & mem_full1;
  assign mem_stall2 = mem_en2 & ((mem_en1 & (mem_full2 | operand_invalid1)) | mem_full1);

  logic full1, full2;
  assign full1   = ~(empty1 | empty2 | alu_direct_read1);
  assign full2   = ~(empty3 | empty4 | alu_direct_read2);

  assign StallE1 = operand_invalid1 | mem_stall1 | full1;
  assign StallE2 = operand_invalid2 | mem_stall2 | dst_invalid2 | full2;

  logic alu_direct_read1, alu_direct_read2;
  assign alu_direct_read1 = alu_read_en1 & alu_en1 & ~(valid1 | ready1) & ~(valid2 | ready2) & ~ALUControlE1[6];// & ~operand_invalid1;
  assign alu_direct_read2 = alu_read_en2 & alu_en2 & ~(valid3 | ready3) & ~(valid4 | ready4) & ~ALUControlE2[6];// & ~operand_invalid2;

  logic matchA11, matchA21, matchA31, matchA41, matchA12, matchA22, matchA32, matchA42;
  assign matchA11 = Rs1E1 == valid_Rd1;
  assign matchA21 = Rs1E1 == valid_Rd2;
  assign matchA31 = Rs1E1 == valid_Rd3;
  assign matchA41 = Rs1E1 == valid_Rd4;
  assign matchA12 = Rs1E2 == valid_Rd1;
  assign matchA22 = Rs1E2 == valid_Rd2;
  assign matchA32 = Rs1E2 == valid_Rd3;
  assign matchA42 = Rs1E2 == valid_Rd4;
  assign matchA1  = Rs1E1 != 0 & ((matchA11 | matchA21) | (matchA31 | matchA41));
  assign matchA2  = Rs1E2 != 0 & ((matchA12 | matchA22) | (matchA32 | matchA42));

  logic matchB11, matchB21, matchB31, matchB41, matchB12, matchB22, matchB32, matchB42;
  assign matchB11 = Rs2E1 == valid_Rd1;
  assign matchB21 = Rs2E1 == valid_Rd2;
  assign matchB31 = Rs2E1 == valid_Rd3;
  assign matchB41 = Rs2E1 == valid_Rd4;
  assign matchB12 = Rs2E2 == valid_Rd1;
  assign matchB22 = Rs2E2 == valid_Rd2;
  assign matchB32 = Rs2E2 == valid_Rd3;
  assign matchB42 = Rs2E2 == valid_Rd4;
  assign matchB1 = Rs2E1 != 0 & ((matchB11 | matchB21) | (matchB31 | matchB41));
  assign matchB2 = Rs2E2 != 0 & ((matchB12 | matchB22) | (matchB32 | matchB42));

  assign FWDataAE1 = matchA11 ? ALUResultE1 : matchA21 ? ALUResultE2 : matchA31 ? ALUResultE3 : ALUResultE4;
  assign FWDataAE2 = matchA12 ? ALUResultE1 : matchA22 ? ALUResultE2 : matchA32 ? ALUResultE3 : ALUResultE4;
  assign FWDataBE1 = matchB11 ? ALUResultE1 : matchB21 ? ALUResultE2 : matchB31 ? ALUResultE3 : ALUResultE4;
  assign FWDataBE2 = matchB12 ? ALUResultE1 : matchB22 ? ALUResultE2 : matchB32 ? ALUResultE3 : ALUResultE4;

  logic alu_en1, alu_en2, mem_en1, mem_en2, wr_en1, wr_en2;
  logic mem_read_en;
  assign mem_en1 = LwE1 | MemWriteE1;
  assign mem_en2 = LwE2 | MemWriteE2;
  assign alu_en1 = ~mem_en1;
  assign alu_en2 = ~mem_en2;
  assign wr_en1 = ~LwE1 & RdE1 != 0 & ~operand_invalid1 & ~alu_direct_read1;
  assign wr_en2 = ~LwE2 & RdE2 != 0 & ~BranchFailE1 & ~operand_invalid2 & ~dst_invalid2 & ~alu_direct_read2;

  logic empty1, empty2, empty3, empty4;
  assign empty1 = ~used1 | (alu_read_en1 & (valid1 | ready1));
  assign empty2 = ~used2 | (alu_read_en1 & ~(valid1 | ready1) & (valid2 | ready2));
  assign empty3 = ~used3 | (alu_read_en2 & (valid3 | ready3));
  assign empty4 = ~used4 | (alu_read_en2 & ~(valid3 | ready3) & (valid4 | ready4));

  assign alu_read_en1 = 1;
  assign alu_read_en2 = ~wb_valid;
  assign mem_read_en = ~stall_m;

  assign flash_w_mem = RdW_mem != 0 & ((RdW_mem == RdE1 & ~operand_invalid1) | (RdW_mem == RdE2 & ~operand_invalid2));
  logic flash_w_alu1, flash_w_alu2;
  assign flash_w_alu1 = RdW1 != 0 & ((RdW1 == RdE1 & ~operand_invalid1) | (RdW1 == RdE2 & ~operand_invalid2));
  assign flash_w_alu2 = RdW2 != 0 & ((RdW2 == RdE1 & ~operand_invalid1) | (RdW2 == RdE2 & ~operand_invalid2));
  assign flash_m = RdM != 0 & ((RdM == RdE1 & ~operand_invalid1) | (RdM == RdE2 & ~operand_invalid2)) & ~scanM;

  alu alu1 (
      SrcAE1,
      SrcBE1,
      ALUControlE1,
      BranchControlE1,
      ALUResultE_1_tmp,
      ZeroE1
  );

  alu alu2 (
      SrcAE2,
      SrcBE2,
      ALUControlE2,
      BranchControlE2,
      ALUResultE_2_tmp,
      ZeroE2
  );

  assign ALUResultE_1 = JumpE1 ? PCPlus4E1 : ALUResultE_1_tmp;
  assign ALUResultE_2 = JumpE2 ? PCPlus4E2 : ALUResultE_2_tmp;

  logic [226:0] FPUResults_1, FPUResults_2;
  fpu fpu1 (
      clk,
      rstN,
      SrcAE1,
      SrcBE1,
      FPUResults_1
  );
  fpu fpu2 (
      clk,
      rstN,
      SrcAE2,
      SrcBE2,
      FPUResults_2
  );

  parameter [26:0] WRITE_ADR = 27'h8;
  parameter [26:0] READ_ADR = 27'hc;

  state_manager state_manager1 (
      .clk(clk),
      .rstN(rstN),
      .ALUResultE(ALUResultE_1),
      .FPUResult(ALUResultE1_fpu),
      .PCPlus4E(PCPlus4E1),
      .ALUControlE(ALUControlE1),
      .BranchControlE(BranchControlE1),
      .PCE(PCE1),
      .RdE(RdE1),
      .ready(ready1),
      .write_en(empty1 & wr_en1),
      .read_en((valid1 | ready1) & alu_read_en1),
      .flash_en((Rd1 == RdE1 & ~operand_invalid1) | (Rd1 == RdE2 & ~StallE2)),
      .Result(ALUResultE1),
      .PC(PC1),
      .Rd(Rd1),
      .valid_Rd(valid_Rd1),
      .invalid_Rd(invalid_Rd1),
      .valid(valid1),
      .used(used1)
  );

  state_manager state_manager2 (
      .clk(clk),
      .rstN(rstN),
      .ALUResultE(ALUResultE_1),
      .FPUResult(ALUResultE2_fpu),
      .PCPlus4E(PCPlus4E1),
      .ALUControlE(ALUControlE1),
      .BranchControlE(BranchControlE1),
      .PCE(PCE1),
      .RdE(RdE1),
      .ready(ready2),
      .write_en(~empty1 & empty2 & wr_en1),
      .read_en(~(valid1 | ready1) & (valid2 | ready2) & alu_read_en1),
      .flash_en((Rd2 == RdE1 & ~operand_invalid1) | (Rd2 == RdE2 & ~StallE2)),
      .Result(ALUResultE2),
      .PC(PC2),
      .Rd(Rd2),
      .valid_Rd(valid_Rd2),
      .invalid_Rd(invalid_Rd2),
      .valid(valid2),
      .used(used2)
  );

  state_manager state_manager3 (
      .clk(clk),
      .rstN(rstN),
      .ALUResultE(ALUResultE_2),
      .FPUResult(ALUResultE3_fpu),
      .PCPlus4E(PCPlus4E2),
      .ALUControlE(ALUControlE2),
      .BranchControlE(BranchControlE2),
      .PCE(PCE2),
      .RdE(RdE2),
      .ready(ready3),
      .write_en(empty3 & wr_en2),
      .read_en((valid3 | ready3) & alu_read_en2),
      .flash_en((Rd3 == RdE1 & ~operand_invalid1) | (Rd3 == RdE2 & ~StallE2)),
      .Result(ALUResultE3),
      .PC(PC3),
      .Rd(Rd3),
      .valid_Rd(valid_Rd3),
      .invalid_Rd(invalid_Rd3),
      .valid(valid3),
      .used(used3)
  );

  state_manager state_manager4 (
      .clk(clk),
      .rstN(rstN),
      .ALUResultE(ALUResultE_2),
      .FPUResult(ALUResultE4_fpu),
      .PCPlus4E(PCPlus4E2),
      .ALUControlE(ALUControlE2),
      .BranchControlE(BranchControlE2),
      .PCE(PCE2),
      .RdE(RdE2),
      .ready(ready4),
      .write_en(~empty3 & empty4 & wr_en2),
      .read_en(~(valid3 | ready3) & (valid4 | ready4) & alu_read_en2),
      .flash_en((Rd4 == RdE1 & ~operand_invalid1) | (Rd4 == RdE2 & ~StallE2)),
      .Result(ALUResultE4),
      .PC(PC4),
      .Rd(Rd4),
      .valid_Rd(valid_Rd4),
      .invalid_Rd(invalid_Rd4),
      .valid(valid4),
      .used(used4)
  );

  logic print1, print2, scan1, scan2;
  logic mem_full1, mem_full2;
  logic [31:0] AddrE1, AddrE2;
  assign AddrE1 = ImmExtE1 + SrcAE1;
  assign AddrE2 = ImmExtE2 + SrcAE2;
  assign print1 = MemWriteE1 & AddrE1[26:0] == WRITE_ADR;
  assign print2 = MemWriteE2 & AddrE2[26:0] == WRITE_ADR;
  assign scan1  = ~MemWriteE1 & AddrE1[26:0] == READ_ADR;
  assign scan2  = ~MemWriteE2 & AddrE2[26:0] == READ_ADR;
  logic [91:0] fifoReadDataM;
  assign {RdM, WriteDataM, MemAddrM, PCM, MemWriteM, printM, scanM, LwM} = fifoReadDataM;

  two_line_fifo two_line_fifo (
      .clk(clk),
      .rstN(rstN),
      .writeEn1(mem_en1 & ~operand_invalid1),
      .writeData1({RdE1, WriteDataE1, AddrE1, PCE1, MemWriteE1, print1, scan1, LwE1}),
      .writeEn2(mem_en2 & ~(mem_en1 & operand_invalid1) & ~operand_invalid2 & ~dst_invalid2 & ~BranchFailE1),
      .writeData2({RdE2, WriteDataE2, AddrE2, PCE2, MemWriteE2, print2, scan2, LwE2}),
      .readEn(mem_read_en),
      .flash_m(flash_m),
      .StallE1(operand_invalid1),
      .StallE2(StallE2),
      .Rs1D1(Rs1D1),
      .Rs2D1(Rs2D1),
      .Rs1D2(Rs1D2),
      .Rs2D2(Rs2D2),
      .RdE1(RdE1),
      .RdE2(RdE2),
      .RdD1(RdD1),
      .LwE1(LwE1),
      .LwE2(LwE2),
      .LwD1(LwD1),
      .readData(fifoReadDataM),
      .full1(mem_full1),
      .full2(mem_full2),
      .lwStallE1(lwStallE1),
      .lwStallE2(lwStallE2)
  );

  always @(posedge clk) begin
    if (alu_read_en1) begin
      if (valid1 | ready1) begin
        if ((~operand_invalid1 & RdE1 == Rd1) | (~StallE2 & ~BranchFailE1 & RdE2 == Rd1)) begin
          RdW1 <= 0;
          ALUResultW1 <= 0;
          PCW1 <= 0;
          // if (Rd1[5]) $display("f%d: skip at %h", Rd1[4:0], PC1);
          // else $display("x%d: skip at %h", Rd1[4:0], PC1);
        end else begin
          RdW1 <= Rd1;
          ALUResultW1 <= valid1 ? ALUResultE1 : ALUResultE1_fpu;
          PCW1 <= PC1;
        end
      end else if (valid2 | ready2) begin
        if ((~operand_invalid1 & RdE1 == Rd2) | (~StallE2 & ~BranchFailE1 & RdE2 == Rd2)) begin
          RdW1 <= 0;
          ALUResultW1 <= 0;
          PCW1 <= 0;
          // if (Rd2[5]) $display("f%d: skip at %h", Rd2[4:0], PC2);
          // else $display("x%d: skip at %h", Rd2[4:0], PC2);
        end else begin
          RdW1 <= Rd2;
          ALUResultW1 <= valid2 ? ALUResultE2 : ALUResultE2_fpu;
          PCW1 <= PC2;
        end
      end else if (RdE1 != 0 & alu_en1 & ~operand_invalid1 & ~ALUControlE1[6]) begin
        if (~StallE2 & ~BranchFailE1 & RdE2 == RdE1) begin
          RdW1 <= 0;
          ALUResultW1 <= 0;
          PCW1 <= 0;
          // if (RdE1[5]) $display("f%d: skip at %h", RdE1[4:0], PCE1);
          // else $display("x%d: skip at %h", RdE1[4:0], PCE1);
        end else begin
          RdW1 <= RdE1;
          ALUResultW1 <= ALUResultE_1;
          PCW1 <= PCE1;
        end
      end else begin
        RdW1 <= 0;
        ALUResultW1 <= 0;
        PCW1 <= 0;
      end
    end else if (flash_w_alu1) begin
      RdW1 <= 0;
      ALUResultW1 <= 0;
      PCW1 <= 0;
      // if (RdW1[5]) $display("f%d: skip at %h", RdW1[4:0], PCW1);
      // else $display("x%d: skip at %h", RdW1[4:0], PCW1);
    end
    if (alu_read_en2) begin
      if (valid3 | ready3) begin
        if ((~operand_invalid1 & RdE1 == Rd3) | (~StallE2 & ~BranchFailE1 & RdE2 == Rd3)) begin
          RdW2 <= 0;
          ALUResultW2 <= 0;
          PCW2 <= 0;
          // if (Rd3[5]) $display("f%d: skip at %h", Rd3[4:0], PC3);
          // else $display("x%d: skip at %h", Rd3[4:0], PC3);
        end else begin
          RdW2 <= Rd3;
          ALUResultW2 <= valid3 ? ALUResultE3 : ALUResultE3_fpu;
          PCW2 <= PC3;
        end
      end else if (valid4 | ready4) begin
        if ((~operand_invalid1 & RdE1 == Rd4) | (~StallE2 & ~BranchFailE1 & RdE2 == Rd4)) begin
          RdW2 <= 0;
          ALUResultW2 <= 0;
          PCW2 <= 0;
          // if (Rd4[5]) $display("f%d: skip at %h", Rd4[4:0], PC4);
          // else $display("x%d: skip at %h", Rd4[4:0], PC4);
        end else begin
          RdW2 <= Rd4;
          ALUResultW2 <= valid4 ? ALUResultE4 : ALUResultE4_fpu;
          PCW2 <= PC4;
        end
      end else if (RdE2 != 0 & alu_en2 & ~operand_invalid2 & ~dst_invalid2 & ~ALUControlE2[6] & ~BranchFailE1) begin
        RdW2 <= RdE2;
        ALUResultW2 <= ALUResultE_2;
        PCW2 <= PCE2;
      end else begin
        RdW2 <= 0;
        ALUResultW2 <= 0;
        PCW2 <= 0;
      end
    end else if (flash_w_alu2) begin
      RdW2 <= 0;
      ALUResultW2 <= 0;
      PCW2 <= 0;
      // if (RdW2[5]) $display("f%d: skip at %h", RdW2[4:0], PCW2);
      // else $display("x%d: skip at %h", RdW2[4:0], PCW2);
    end

  end

  execute_line execute_line1 (
      .clk(clk),
      .rstN(rstN),
      .en(wr_en1 & empty1),
      .ALUControlE(ALUControlE1),
      .FPUResults(FPUResults_1),
      .ready(ready1),
      .Result(ALUResultE1_fpu)
  );

  execute_line execute_line2 (
      .clk(clk),
      .rstN(rstN),
      .en(wr_en1 & ~empty1 & empty2),
      .ALUControlE(ALUControlE1),
      .FPUResults(FPUResults_1),
      .ready(ready2),
      .Result(ALUResultE2_fpu)
  );

  execute_line execute_line3 (
      .clk(clk),
      .rstN(rstN),
      .en(wr_en2 & empty3),
      .ALUControlE(ALUControlE2),
      .FPUResults(FPUResults_2),
      .ready(ready3),
      .Result(ALUResultE3_fpu)
  );

  execute_line execute_line4 (
      .clk(clk),
      .rstN(rstN),
      .en(wr_en2 & ~empty3 & empty4),
      .ALUControlE(ALUControlE2),
      .FPUResults(FPUResults_2),
      .ready(ready4),
      .Result(ALUResultE4_fpu)
  );

endmodule
