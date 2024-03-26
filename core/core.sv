module core (
    input logic clk,
    reset,
    output logic MemWriteM,
    BramWriteM,
    output logic [PC_LEN-3:0] PCF,
    PCE,
    input logic [31:0] InstrRead,
    output logic [31:0] MemAddrM,
    output logic [10:0] BramAddrE,
    BramAddrM,
    output logic [31:0] WriteDataM,
    output logic LwM,
    printM,
    scanM,
    StallD,
    StallM,
    FlashD,
    input logic [31:0] ReadDataIOW,
    ReadDataMEMW,
    BramReadDataM,
    input logic [31:0] sp_data,
    input logic sp_valid,
    input logic [PC_LEN-3:0] pc_data,
    input logic pc_valid,
    core_en,
    stall_w,
    stall_m,
    valid_in,
    valid_mem
    // ,flash_w
);

  parameter [31:0] WRITE_ADR = 32'h8;
  parameter [31:0] READ_ADR = 32'hc;
  parameter PC_LEN = 17;


  logic [PC_LEN-3:0] PCNextF, PCD, PCTargetE, PCTargetD;
  logic [PC_LEN-3:0] PCPlus4F, PCPlus4D, PCPlus4E, PCPlus4M, PCF_reg;
  logic [31:0] InstrD;
  logic [31:0] ImmExtD, ImmExtE;
  logic [31:0] ResultW, ResultW1, ResultM, ResultW2, ResultW_fpu;
  logic [31:0] ALUResultE, ALUResultM, ALUResultW;

  logic [31:0] RD1D, RD2D, RD1E, RD2E;
  logic [5:0] RdD, RdE, RdM, RdW, RdW_fpu;
  logic [5:0] Rs1D, Rs1E, Rs2D, Rs2E;

  // control signals

  logic RegWriteD, RegWriteE, RegWriteM, RegWriteW, RegWriteW_fpu;
  logic FPURegWriteD;
  logic ResultSrcD, ResultSrcE, ResultSrcM;
  logic MemWriteD, MemWriteE;
  logic JumpD, JumpE, JumpRD, JumpRE;
  logic LwD, LwE, LwW;
  logic BramLwE, BramLwM, StallLwE, StallLwM;
  logic BranchD, BranchE;
  logic [3:0] ALUControlD, ALUControlE, ALUControlM;
  logic ALUSrcbD, ALUSrcbE;
  logic [2:0] ImmSrcD;
  logic [1:0] PCSrcE, BranchControlD, BranchControlE;

  logic ZeroE;

  logic lwStall;

  // hazard signals
  logic StallF, StallE, StallW, FlashE, FlashM, operand_invalid1, operand_invalid2, full;
  logic [2:0] ForwardAE, ForwardBE;


  logic FPUD, FPUE;
  logic negD, negE;
  logic FPUSrcAD, FPUSrcBD;

  logic stall_fpu;
  logic fpu_stall_opD, fpu_stall_opE;
  logic shift2D, shift6D, shift2E, shift6E;
  logic use_prev_data1, use_prev_data2;

  logic [PC_LEN-3:0] ra_cache;

  logic predictD, predictE;

  branch_prediction bp (
      clk,
      (negE ^ ZeroE),  //& ~StallE,
      BranchE,
      StallD,
      StallE,
      PCF,
      PCE,
      predictD
  );
  //   assign predictD = 0;

  hazard_unit hazard (
      .clk(clk),
      .Rs1D(Rs1D),
      .Rs2D(Rs2D),
      .Rs1E(Rs1E),
      .Rs2E(Rs2E),
      .RdE(RdE),
      .RdM(RdM),
      .RdW(RdW),
      .RdW_fpu(RdW_fpu),
      .LwE(LwE),
      .RegWriteE(RegWriteE),
      .RegWriteM(RegWriteM),
      .RegWriteW(RegWriteW),
      .RegWriteW_fpu(RegWriteW_fpu),
      .PCJump(BranchE & ((negE ^ predictE) ^ ZeroE)),
      .JumpRD(JumpRD),
      .operand_invalid1(operand_invalid1),
      .operand_invalid2(operand_invalid2),
      .full(full),
      .StallF(StallF),
      .StallD(StallD),
      .StallE(StallE),
      .StallM(StallM),
      .FlashD(FlashD),
      .FlashE(FlashE),
      .FlashM(FlashM),
      .ForwardAE(ForwardAE),
      .ForwardBE(ForwardBE),
      .core_en(core_en),
      .stall_m(stall_m),
      .stall_w(stall_w),
      .use_prev_data1(use_prev_data1),
      .use_prev_data2(use_prev_data2),
      .lwStall(lwStall),
      .fpu_stall_op(fpu_stall_opE),
      .LwM(StallLwM),
      .LwW(LwW)
  );

  //   For debug
  logic [PC_LEN-3:0] PCM, PCW, PCW_fpu;
  //   flopenr #(PC_LEN - 2) execute_reg_db (
  //       clk,
  //       ~FlashE,
  //       ~StallE && core_en,
  //       PCD,
  //       PCE
  //   );
  //   flopenr #(PC_LEN - 2) memory_reg_db (
  //       clk,
  //       ~FlashM,
  //       core_en && ~StallM,
  //       PCE,
  //       PCM
  //   );
  //   flopenr #(PC_LEN - 2) wb_reg_db (
  //       clk,
  //       reset & (~StallM | stall_w),
  //       core_en & ~stall_w,
  //       PCM,
  //       PCW
  //   );

  //   logic we3;
  //   logic [5:0] a3;
  //   assign we3 = sp_valid | (RegWriteW & ~LwW & ~scanW) | valid_mem | valid_in;  //we3
  //   assign a3  = sp_valid ? 6'b10 : RdW;  // a3
  //   always @(posedge clk) begin
  //     if (we3 & a3 != 0) begin
  //       if (a3[5]) $display("f%d: %h at %h", a3[4:0], ResultW, PCW);
  //       else $display("x%d: %h at %h", a3[4:0], sp_valid ? sp_data : ResultW, PCW);
  //     end
  //     if (RegWriteW_fpu & RdW_fpu != 0) begin
  //       if (RdW_fpu[5]) $display("f%d: %h at %h", RdW_fpu[4:0], ResultW_fpu, PCW_fpu);
  //       else $display("x%d: %h at %h", RdW_fpu[4:0], ResultW_fpu, PCW_fpu);
  //     end
  //     if (FlashRdM)
  //       if (RdM[5]) $display("f%d: skip at %h", RdM[4:0], PCM);
  //       else $display("x%d: skip at %h", RdM[4:0], PCM);
  //     if (FlashRdW)
  //       if (RdW[5]) $display("f%d: skip at %h", RdW[4:0], PCW);
  //       else $display("x%d: skip at %h", RdW[4:0], PCW);
  //   end


  mux3 #(PC_LEN - 2) pcmux (
      PCPlus4F,
      PCTargetE,
      PCPlus4E,
      PCSrcE,
      PCNextF
  );

  //////////////////////////Fetch/////////////////////////////////
  flopenr2 #(PC_LEN - 2) pcreg (
      clk,
      (core_en & ~StallF) | pc_valid,
      pc_valid ? pc_data : PCNextF,
      PCF_reg
  );

  assign PCF = JumpD | (BranchD & predictD) ? PCTargetD : JumpRD ? ra_cache : PCF_reg;
  logic [PC_LEN-3:0] ra_cachePlus4, PCTargetDPlus4, PCF_regPlus4;

  adder pcadd4_2 (
      ra_cache,
      15'd1,
      ra_cachePlus4
  );
  adder pcadd4_3 (
      PCF_reg,
      15'd1,
      PCF_regPlus4
  );

  assign PCPlus4F =  JumpD | (BranchD & predictD)  ? PCTargetDPlus4 : JumpRD  ? ra_cachePlus4 : PCF_regPlus4;


  // instruction memory

  ////////////////////////////Decode////////////////////////////////

  logic FlashD_prev;
  always @(posedge clk) begin
    if (FlashD | ~StallD) FlashD_prev <= FlashD;
  end
  assign InstrD = FlashD_prev ? 0 : InstrRead;

  logic [PC_LEN*2-5:0] decodeDataF, decodeDataD;
  assign decodeDataF = {  /*InstrF,*/ PCF, PCPlus4F};
  assign {  /*InstrD, */ PCD, PCPlus4D} = decodeDataD;

  flopenr #(PC_LEN * 2 - 4) decode_reg (
      clk,
      FlashD,
      core_en && ~StallD,
      decodeDataF,
      decodeDataD
  );

  controller c (
      InstrD[6:0],
      InstrD[14:12],
      InstrD[31:25],
      RegWriteD,
      FPURegWriteD,
      ResultSrcD,
      MemWriteD,
      JumpD,
      JumpRD,
      BranchD,
      ALUSrcbD,
      ImmSrcD,
      ALUControlD,
      negD,
      FPUD,
      FPUSrcAD,
      FPUSrcBD,
      LwD,
      fpu_stall_opD,
      shift2D,
      shift6D,
      lwaddD,
      BranchControlD
  );

  assign Rs1D = {FPUSrcAD, InstrD[19:15]};
  assign Rs2D = {FPUSrcBD, InstrD[24:20]};
  assign RdD  = (RegWriteD | FPURegWriteD) ? {FPURegWriteD, InstrD[11:7]} : 0;

  regfile rf (
      clk,  //clk
      RegWriteW,  //we1
      RegWriteW_fpu,  //we2
      Rs1D,  // a1
      Rs2D,  // a2
      RdW,  // aw1
      RdW_fpu,  // aw2
      ResultW,  //wd3
      ResultW_fpu,  //wd4
      RD1D,
      RD2D
  );

  extend ext (
      InstrD[31:7],
      ImmSrcD,
      Rs2D[0],
      ImmExtD
  );

  logic [PC_LEN-3:0] JumpImmD;
  assign JumpImmD = JumpD ?  {InstrD[PC_LEN-1:12], InstrD[20], InstrD[30:22]} : {{4{InstrD[31]}}, InstrD[7], InstrD[30:25], InstrD[11:8]};

  adder pcaddbranch (
      PCD,
      JumpImmD,
      PCTargetD
  );
  adder pcaddbranch4 (
      PCPlus4D,
      JumpImmD,
      PCTargetDPlus4
  );


  always @(posedge clk) begin
    if (valid_mem & RdW == 6'b1) ra_cache <= ReadDataMEMW[PC_LEN-3:0];  // ra
    else if (JumpD & RdD == 6'b1 & ~StallE) ra_cache <= PCPlus4D;  // ra
  end

  logic scanD, printD;
  assign scanD  = Rs1D == 0 & ImmExtD == READ_ADR & LwD;
  assign printD = Rs1D == 0 & ImmExtD == WRITE_ADR & MemWriteD;

  ///////////////////////Execute///////////////////////////////
  logic [129:0] executeDataDataD, executeDataDataE;
  assign executeDataDataD = {
    RD1D, RD2D, ~operand_invalid1 & StallE, ~operand_invalid2 & StallE, SrcAE, WriteDataE
  };
  assign {RD1E, RD2E, use_prev_data1, use_prev_data2, SrcAE_prev, WriteDataE_prev} = executeDataDataE;
  logic [11:0] executeDataRegD, executeDataRegE;
  assign executeDataRegD = {Rs1D, Rs2D};
  assign {Rs1E, Rs2E} = executeDataRegE;
  logic [90:0] executeDataD, executeDataE;
  assign executeDataD = {
    (RegWriteD | FPURegWriteD) & RdD != 0,
    ResultSrcD,
    MemWriteD,
    JumpD,
    JumpRD,
    BranchD,
    ALUControlD,
    ALUSrcbD,
    RdD,
    ImmExtD,
    PCPlus4D,
    FPUD,
    negD,
    LwD,
    fpu_stall_opD,
    BranchControlD,
    PCTargetD,
    predictD,
    scanD,
    printD,
    shift2D,
    shift6D,
    lwaddD
  };
  assign {RegWriteE, ResultSrcE, MemWriteE, JumpE, JumpRE, BranchE, ALUControlE,
      ALUSrcbE, RdE, ImmExtE, PCPlus4E, FPUE, negE, LwE, fpu_stall_opE, BranchControlE, PCTargetE, predictE, scanE, printE, shift2E, shift6E, lwaddE} = executeDataE;
  always_ff @(posedge clk) begin
    executeDataDataE <= executeDataDataD;
  end
  flopenr #(12) execute_reg_reg (
      clk,
      FlashE,
      ~StallE && core_en,
      executeDataRegD,
      executeDataRegE
  );
  flopenr #(91) execute_reg (
      clk,
      FlashE,
      ~StallE && core_en,
      executeDataD,
      executeDataE
  );

  logic [31:0] SrcAE, SrcBE, SrcAE_shift;
  logic [31:0] SrcAE_prev, WriteDataE_prev, WriteDataE_lw, WriteDataE;
  //   always @(posedge clk) begin
  //     SrcAE_prev <= SrcAE;
  //     WriteDataE_prev <= WriteDataE;
  //   end

  mux5 #(32) srcamux (
      RD1E,
      ResultW_fpu,
      ResultW1,
      SrcAE_prev,
      ALUResultM,
      ForwardAE,
      SrcAE
  );
  mux5 #(32) writedatamux (
      RD2E,
      ResultW_fpu,
      ResultW1,
      WriteDataE_prev,
      ALUResultM,
      ForwardBE,
      WriteDataE
  );
  //   mux2 #(32) srcbmux (
  //       WriteDataE,
  //       ImmExtE,
  //       ALUSrcbE,
  //       SrcBE
  //   );
  mux6 #(32) srcbmux (
      RD2E,
      ResultW_fpu,
      ResultW1,
      WriteDataE_prev,
      ALUResultM,
      ImmExtE,
      ForwardBE | {3{ALUSrcbE}},
      SrcBE
  );

  assign SrcAE_shift = shift6E ? {SrcAE[25:0], 6'b0} : shift2E ? {SrcAE[29:0], 2'b0} : SrcAE;
  //   assign SrcAE = shift6E ? SrcAE_tmp << 6 : shift2E ? SrcAE_tmp << 2 : SrcAE_tmp;


  logic [31:0] ALUResultE1, ALUResultE2, AddResult;
  logic [223:0] FPUResults;

  alu alu (
      SrcAE,
      SrcBE,
      SrcAE_shift,
      ALUControlE,
      BranchControlE,
      ALUResultE1,
      AddResult,
      ZeroE
  );

  fpu fpu (
      clk,
      reset,
      SrcAE,
      WriteDataE,
      ALUControlE,
      ALUResultE2,
      FPUResults
  );

  logic [12:0] AddrE_sh;
  logic lwaddD, lwaddE, BramWriteE;
  assign AddrE_sh  = SrcAE_shift[14:2] + SrcBE[14:2];
  assign BramAddrE = AddrE_sh[10:0];
  logic use_bramE;
  assign use_bramE = (lwaddE ? ~(|SrcBE[26:14]) : ~(|SrcAE_shift[26:14])) & ~AddrE_sh[11];

  assign BramWriteE = MemWriteE & use_bramE;
  assign BramLwE = (LwE & use_bramE) & ~scanE;
  assign StallLwE = (LwE & ~use_bramE) | scanE;

  assign ALUResultE = FPUE ? ALUResultE2 : ALUResultE1;

  assign PCSrcE = BranchE & ((negE ^ predictE) ^ ZeroE) ? predictE ? 2'b11 : 2'b10 : 2'b00;

  assign WriteDataE_lw = lwaddE ? AddResult : WriteDataE;

  logic printE, scanE, scanW;

  fpu_reg fpu_reg (
      .clk(clk),
      .rstN(reset),
      .fpu_stall_opE(fpu_stall_opE),
      .StallE(StallE),
      .Rs1E(Rs1E),
      .Rs2E(Rs2E),
      .RdE(RdE),
      .FPUResults(FPUResults),
      .ALUControlE(ALUControlE),
      .PCE(PCE),
      .RegWrite_fpu(RegWriteW_fpu),
      .PCW_fpu(PCW_fpu),
      .RdW_fpu(RdW_fpu),
      .ResultW_fpu(ResultW_fpu),
      .operand_invalid1(operand_invalid1),
      .operand_invalid2(operand_invalid2),
      .full(full)
  );


  ////////////////////////Memory///////////////////////////////
  // Data Memory

  logic [97:0] MemDataE, MemDataM;
  assign MemDataE = {
    ResultSrcE,
    MemWriteE & ~use_bramE & ~printE,
    ALUResultE,
    WriteDataE_lw,
    PCPlus4E,
    StallLwE,
    StallLwE & ~scanE,
    printE,
    scanE,
    BramLwE,
    BramWriteE,
    BramAddrE
  };
  assign {ResultSrcM, MemWriteM, MemAddrM, WriteDataM, PCPlus4M, StallLwM, LwM, printM, scanM, BramLwM, BramWriteM, BramAddrM} = MemDataM;

  flopenr #(98) memory_reg (
      clk,
      FlashM,
      core_en && ~StallM,
      MemDataE,
      MemDataM
  );

  logic FlashRdM;
  assign FlashRdM = RdM == RdE & RdE != 0 & ~StallE & StallM;

  flopenr #(7) memory_rd_reg (
      clk,
      FlashM | FlashRdM,
      core_en && ~StallM,
      {RdE, RegWriteE},
      {RdM, RegWriteM}
  );

  assign ALUResultM = BramLwM ? BramReadDataM : MemAddrM;

  mux2 #(32) resultmux1 (
      ALUResultM,
      {17'b0, PCPlus4M},
      ResultSrcM,
      ResultM
  );

  ////////////////////////WriteBack//////////////////////////////
  logic [33:0] WBDataM, WBDataW;
  assign WBDataM = {ResultM, LwM, scanM};
  assign {ResultW1, LwW, scanW} = WBDataW;

  logic FlashRdW;
  assign FlashRdW = RdE != 0 & RdW == RdE & ~StallE & stall_w;

  flopenr #(34) wb_reg (
      clk,
      (StallM & ~stall_w),
      core_en & ~stall_w,
      WBDataM,
      WBDataW
  );
  flopenr #(7) wb_rd_reg (
      clk,
      (StallM & ~stall_w) | FlashRdW,
      core_en & ~stall_w,
      {RdM, RegWriteM},
      {RdW, RegWriteW}
  );

  mux2 #(32) resultmux2 (
      ResultW1,
      ReadDataIOW,
      scanW,
      ResultW2
  );

  mux2 #(32) resultmux (
      ResultW2,
      ReadDataMEMW,
      LwW,
      ResultW
  );

endmodule
