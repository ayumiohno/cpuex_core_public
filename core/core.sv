module core (
    input logic clk,
    reset,
    output logic MemWriteM,
    output logic [17:0] PCF,
    input logic [63:0] InstrRead,
    output logic [31:0] ALUResultM,  //DataAdr
    output logic [31:0] WriteDataM,
    output logic LwM,
    printM,
    scanM,
    StallD2,
    input logic [31:0] ReadDataW,
    input logic [31:0] sp_data,
    input logic sp_valid,
    input logic [17:0] pc_data,
    input logic pc_valid,
    core_en,
    stall_w,
    stall_m,
    wb_valid,
    req_ready
);

  logic [17:0] PCNextF, PCD, PCTargetD;
  logic [17:0] PCPlus8F, PCPlus8D, PCPlus8M, PCPlus8W, PCF_reg;
  logic [17:0]
      PCD1,
      PCD2,
      PCE1,
      PCE2,
      PCPlus8D1,
      PCPlus8D2,
      PCTargetD1,
      PCTargetD2,
      PCPlus8E1,
      PCPlus8E2,
      PCTargetE,
      PCPlus8E,
      PCTargetE1,
      PCTargetE2;
  logic [63:0] InstrD;
  logic [31:0] InstrD1, InstrD2;
  logic [31:0] ImmExtD1, ImmExtD2, ImmExtE1, ImmExtE2;
  logic [31:0] ResultW1, ResultW2;
  logic [31:0] ALUResultW1, ALUResultW2;
  logic [31:0] WriteDataE1, WriteDataE2, ReadDataM;
  logic [31:0] FWDataAE1, FWDataAE2, FWDataBE1, FWDataBE2;

  logic [31:0] RD1D1, RD2D1, RD1E1, RD2E1, RD1D2, RD2D2, RD1E2, RD2E2;
  logic [5:0] RdD1, RdD2, RdE1, RdE2, RdW1, RdW2, RdM;
  logic [5:0] Rs1D1, Rs2D1, Rs1E1, Rs2E1, Rs1D2, Rs2D2, Rs1E2, Rs2E2;

  // control signals

  logic RegWriteD1, RegWriteD2, RegWriteE1, RegWriteE2, RegWriteM, RegWriteW;
  logic FPURegWriteD1, FPURegWriteD2;
  logic [1:0] ResultSrcD1, ResultSrcE1, ResultSrcD2, ResultSrcE2;
  logic MemWriteD1, MemWriteD2, MemWriteE1, MemWriteE2;
  logic JumpD1, JumpE1, JumpRD1, JumpRE1, JumpD2, JumpE2, JumpRD2, JumpRE2;
  logic LwD1, LwE1, LwD2, LwE2, LwW;
  logic BranchD1, BranchE1, BranchD2, BranchE2, BranchFailE1, BranchFailE2;
  logic [6:0] ALUControlD1, ALUControlE1, ALUControlD2, ALUControlE2;
  logic ALUSrcbD1, ALUSrcbE1, ALUSrcbD2, ALUSrcbE2;
  logic [2:0] ImmSrcD1, ImmSrcD2;
  logic [1:0] PCSrcE, BranchControlD1, BranchControlE1, BranchControlD2, BranchControlE2;

  logic ZeroE1, ZeroE2;

  logic lwStall, lwStallE1, lwStallE2;

  // hazard signals
  logic StallF, StallD1, StallE1, StallE2, StallW, FlashD1, FlashD2, FlashE1, FlashE2;
  logic [1:0] ForwardAE1, ForwardBE1, ForwardAE2, ForwardBE2;
  logic matchA1, matchB1, matchA2, matchB2;


  logic FPUD1, FPUE1, FPUD2, FPUE2;
  logic negD1, negE1, negD2, negE2;
  logic FPUSrcAD1, FPUSrcBD1, FPUSrcAD2, FPUSrcBD2;

  logic fpu_stall_opD1, fpu_stall_opE1, fpu_stall_opD2, fpu_stall_opE2;

  logic [17:0] ra_cache;

  logic predictD, predictE1, predictE2;

  logic BranchPlus8;

  branch_prediction bp (
      clk,
      BranchE1 ? negE1 ^ ZeroE1 : negE2 ^ ZeroE2,
      BranchE1 | BranchE2,
      PCF,
      PCE1,
      predictD
  );

  hazard_unit hazard (
      .clk(clk),
      .Rs1D1(Rs1D1),
      .Rs2D1(Rs2D1),
      .Rs1E1(Rs1E1),
      .Rs2E1(Rs2E1),
      .RdE1(RdE1),
      .Rs1D2(Rs1D2),
      .Rs2D2(Rs2D2),
      .Rs1E2(Rs1E2),
      .Rs2E2(Rs2E2),
      .RdE2(RdE2),
      .RdM(RdM),
      .RdW_alu1(RdW_alu1),
      .RdW_alu2(RdW_alu2),
      .RdW_mem(RdW_mem),
      .JumpD1(Jump1),
      .JumpRD1(JumpRD1),
      .JumpRD2(JumpRD2),
      .BranchFailE1(BranchFailE1),
      .BranchFailE2(BranchFailE2),
      .lwStallE1(lwStallE1),
      .lwStallE2(lwStallE2),
      .wb_valid(wb_valid),
      .StallE1(StallE1),
      .StallE2(StallE2),
      .StallF(StallF),
      .StallD1(StallD1),
      .StallD2(StallD2),
      .FlashD1(FlashD1),
      .FlashD2(FlashD2),
      .FlashE1(FlashE1),
      .FlashE2(FlashE2),
      .ForwardAE1(ForwardAE1),
      .ForwardAE2(ForwardAE2),
      .ForwardBE1(ForwardBE1),
      .ForwardBE2(ForwardBE2),
      .lwStall(lwStall),
      .LwM(LwM),
      .LwW(LwW)
  );

  //   For debugging
  logic [17:0] PCM, PCW1, PCW2, PCW_mem;
  flopenr #(18) wb_reg_db (
      clk,
      reset & ~(stall_m & ~stall_w),
      core_en && ~(stall_w | stall_m),
      PCM,
      PCW_mem
  );

  mux3 #(18) pcmux (
      {PCPlus8F[17:3], 3'b000},
      PCTargetE,
      PCPlus8E,
      PCSrcE,
      PCNextF
  );


  //////////////////////////Fetch/////////////////////////////////

  flopenr #(18) pcreg (
      clk,
      reset,
      (core_en & ~StallF) | pc_valid,
      pc_valid ? pc_data : PCNextF,
      PCF_reg
  );

  logic Jump1, Jump2;
  assign Jump1 = JumpD1 | (BranchD1 & predictD);
  assign Jump2 = JumpD2 | (BranchD2 & predictD);
  assign PCF   = Jump1 ? PCTargetD1 : JumpRD1 | JumpRD2 ? ra_cache : Jump2 ? PCTargetD2 : PCF_reg;

  logic [17:0] ra_cachePlus8, PCTargetDPlus8_1, PCTargetDPlus8_2, PCF_regPlus8;

  adder pcadd4_2 (
      ra_cache,
      8,
      ra_cachePlus8
  );
  adder pcadd4_3 (
      PCF_reg,
      8,
      PCF_regPlus8
  );

  assign PCPlus8F =  Jump1 ? PCTargetDPlus8_1 : JumpRD1 | JumpRD2  ? ra_cachePlus8 :  Jump2 ? PCTargetDPlus8_2 : PCF_regPlus8;


  // instruction memory

  ////////////////////////////Decode////////////////////////////////

  logic FlashD1_prev, FlashD2_prev;
  always @(posedge clk) begin
    if (FlashD1 | ~StallD1) FlashD1_prev <= FlashD1;
    if (FlashD2 | ~StallD2) FlashD2_prev <= FlashD2;
  end
  //   assign InstrD = FlashD_prev ? 0 : InstrRead;
  assign InstrD1 = PCD[2] | FlashD1_prev ? 0 : InstrRead[31:0];
  assign InstrD2 = FlashD2_prev ? 0 : InstrRead[63:32];
  assign PCD1 = PCD[2] ? 0 : PCD;
  assign PCD2 = {PCD[17:3], 3'b100};
  assign PCPlus8D1 = PCD[2] ? 0 : PCD2;
  assign PCPlus8D2 = {PCPlus8D[17:3], 3'b000};

  logic [35:0] decodeDataF, decodeDataD;
  assign decodeDataF = {  /*InstrF,*/ PCF, PCPlus8F};
  assign {  /*InstrD, */ PCD, PCPlus8D} = decodeDataD;

  flopenr #(36) decode_reg (
      clk,
      reset & ~(FlashD1 & FlashD2),
      core_en & ~(StallD1 | StallD2),
      decodeDataF,
      decodeDataD
  );

  controller c1 (
      InstrD1[6:0],
      InstrD1[14:12],
      InstrD1[31:25],
      RegWriteD1,
      FPURegWriteD1,
      ResultSrcD1,
      MemWriteD1,
      JumpD1,
      JumpRD1,
      BranchD1,
      ALUSrcbD1,
      ImmSrcD1,
      ALUControlD1,
      negD1,
      FPUSrcAD1,
      FPUSrcBD1,
      LwD1,
      BranchControlD1
  );

  controller c2 (
      InstrD2[6:0],
      InstrD2[14:12],
      InstrD2[31:25],
      RegWriteD2,
      FPURegWriteD2,
      ResultSrcD2,
      MemWriteD2,
      JumpD2,
      JumpRD2,
      BranchD2,
      ALUSrcbD2,
      ImmSrcD2,
      ALUControlD2,
      negD2,
      FPUSrcAD2,
      FPUSrcBD2,
      LwD2,
      BranchControlD2
  );

  assign Rs1D1 = {FPUSrcAD1, InstrD1[19:15]};
  assign Rs2D1 = {FPUSrcBD1, InstrD1[24:20]};
  assign RdD1  = BranchD1 | MemWriteD1 ? 0 : {FPURegWriteD1, InstrD1[11:7]};
  assign Rs1D2 = {FPUSrcAD2, InstrD2[19:15]};
  assign Rs2D2 = {FPUSrcBD2, InstrD2[24:20]};
  assign RdD2  = BranchD2 | MemWriteD2 ? 0 : {FPURegWriteD2, InstrD2[11:7]};
  assign RdW1  = RdW_alu1;  //alu_read_en1 ? RdW_alu1 : RdW_mem;
  assign RdW2  = alu_read_en2 ? RdW_alu2 : RdW_mem;
  //   assign RdW2  = RdW_alu2;

  regfile rf (
      .clk(clk),  //clk
      .we1(sp_valid | core_en),  //we1
      .we2(core_en),  //we2
      .ar1(Rs1D1),  // a1
      .ar2(Rs2D1),  // a2
      .ar3(Rs1D2),  // a3
      .ar4(Rs2D2),  // a4
      .aw1(sp_valid ? 6'b10 : RdW1),  // a3
      .aw2(RdW2),  // a4
      .wd1(sp_valid ? sp_data : ResultW1),  //wd1
      .wd2(ResultW2),  //wd2
      .rd1(RD1D1),
      .rd2(RD2D1),
      .rd3(RD1D2),
      .rd4(RD2D2)
  );

  extend ext1 (
      InstrD1[31:7],
      ImmSrcD1,
      ImmExtD1
  );
  extend ext2 (
      InstrD2[31:7],
      ImmSrcD2,
      ImmExtD2
  );

  logic [17:0] JumpImmD1;
  assign JumpImmD1 = JumpD1 ?  {InstrD1[17:12], InstrD1[20], InstrD1[30:21], 1'b0} : {{6{InstrD1[31]}}, InstrD1[7], InstrD1[30:25], InstrD1[11:8], 1'b0};
  logic [17:0] JumpImmD2;
  assign JumpImmD2 = JumpD2 ?  {InstrD2[17:12], InstrD2[20], InstrD2[30:21], 1'b0} : {{6{InstrD2[31]}}, InstrD2[7], InstrD2[30:25], InstrD2[11:8], 1'b0};

  adder pcaddbranch1 (
      PCD1,
      JumpImmD1,
      PCTargetD1
  );
  adder pcaddbranch2 (
      PCD2,
      JumpImmD2,
      PCTargetD2
  );

  adder pcaddbranch8_1 (
      PCPlus8D2,  // PCD1 + 8
      JumpImmD1,
      PCTargetDPlus8_1
  );

  adder pcaddbranch8_2 (
      {PCPlus8D2[17:3], 3'b100},  // PCD2 + 8
      JumpImmD2,
      PCTargetDPlus8_2
  );


  always @(posedge clk) begin
    if (JumpD1 & RdD1 == 6'b1 & ~StallE1) ra_cache <= PCPlus8D1;
    else if (JumpD2 & RdD2 == 6'b1 & ~StallE2) ra_cache <= PCPlus8D2;
    else if (wb_valid & RdW_mem == 6'b1) ra_cache <= ReadDataW[17:0];

    // if (JumpRD) $display("JUMP RA: %h", ra_cache);
  end

  logic [187:0] executeDataD1, executeDataE1;
  assign executeDataD1 = {
    RegWriteD1 | FPURegWriteD1,
    ResultSrcD1,
    MemWriteD1,
    JumpD1,
    JumpRD1,
    BranchD1,
    ALUControlD1,
    ALUSrcbD1,
    RD1D1,
    RD2D1,
    PCD1,
    Rs1D1,
    Rs2D1,
    RdD1,
    ImmExtD1,
    PCPlus8D1,
    negD1,
    LwD1,
    BranchControlD1,
    PCTargetD1,
    predictD
  };
  assign {RegWriteE1, ResultSrcE1, MemWriteE1, JumpE1, JumpRE1, BranchE1, ALUControlE1,
        ALUSrcbE1, RD1E1, RD2E1, PCE1, Rs1E1, Rs2E1, RdE1, ImmExtE1, PCPlus8E1, negE1, LwE1,  BranchControlE1, PCTargetE1, predictE1} = executeDataE1;

  logic [187:0] executeDataD2, executeDataE2;
  assign executeDataD2 = {
    RegWriteD2 | FPURegWriteD2,
    ResultSrcD2,
    MemWriteD2,
    JumpD2,
    JumpRD2,
    BranchD2,
    ALUControlD2,
    ALUSrcbD2,
    RD1D2,
    RD2D2,
    PCD2,
    Rs1D2,
    Rs2D2,
    RdD2,
    ImmExtD2,
    PCPlus8D2,
    negD2,
    LwD2,
    BranchControlD2,
    PCTargetD2,
    predictD
  };
  assign {RegWriteE2, ResultSrcE2, MemWriteE2, JumpE2, JumpRE2, BranchE2, ALUControlE2,
        ALUSrcbE2, RD1E2, RD2E2, PCE2, Rs1E2, Rs2E2, RdE2, ImmExtE2, PCPlus8E2,  negE2, LwE2, BranchControlE2, PCTargetE2, predictE2} = executeDataE2;

  flopenr #(188) execute_reg1 (
      clk,
      reset && ~FlashE1,
      ~(StallE1 | StallE2) && core_en,
      executeDataD1,
      executeDataE1
  );
  flopenr #(188) execute_reg2 (
      clk,
      reset && ~FlashE2,
      ~(StallE1 | StallE2) && core_en,
      executeDataD2,
      executeDataE2
  );

  logic [31:0] SrcAE1, SrcBE1;
  logic [31:0] SrcAE2, SrcBE2;
  logic [31:0] SrcAE_prev1, SrcBE_prev1;
  logic [31:0] SrcAE_prev2, SrcBE_prev2;
  logic [31:0] SrcAE1_tmp, SrcBE1_tmp, WriteDataE1_tmp, SrcAE2_tmp, SrcBE2_tmp, WriteDataE2_tmp;

  always @(posedge clk) begin
    SrcAE_prev1 <= SrcAE1;
    SrcBE_prev1 <= WriteDataE1;
    SrcAE_prev2 <= SrcAE2;
    SrcBE_prev2 <= WriteDataE2;
  end

  assign SrcAE1 = matchA1 ? FWDataAE1 : SrcAE1_tmp;
  assign SrcAE2 = matchA2 ? FWDataAE2 : SrcAE2_tmp;
  assign WriteDataE1 = matchB1 ? FWDataBE1 : WriteDataE1_tmp;
  assign WriteDataE2 = matchB2 ? FWDataBE2 : WriteDataE2_tmp;

  mux4 #(32) srcamux1 (
      RD1E1,
      ALUResultW2,
      ALUResultW1,
      SrcAE_prev1,
      ForwardAE1,
      SrcAE1_tmp
  );
  mux4 #(32) writedatamux1 (
      RD2E1,
      ALUResultW2,
      ALUResultW1,
      SrcBE_prev1,
      ForwardBE1,
      WriteDataE1_tmp
  );
  mux2 #(32) srcbmux1 (
      WriteDataE1,
      ImmExtE1,
      ALUSrcbE1,
      SrcBE1
  );
  mux4 #(32) srcamux2 (
      RD1E2,
      ALUResultW2,
      ALUResultW1,
      SrcAE_prev2,
      ForwardAE2,
      SrcAE2_tmp
  );
  mux4 #(32) writedatamux2 (
      RD2E2,
      ALUResultW2,
      ALUResultW1,
      SrcBE_prev2,
      ForwardBE2,
      WriteDataE2_tmp
  );
  mux2 #(32) srcbmux2 (
      WriteDataE2,
      ImmExtE2,
      ALUSrcbE2,
      SrcBE2
  );


  logic [5:0] RdW_alu1, RdW_alu2, RdW_mem;
  logic flash_w, flash_m;
  //   logic operand_invalid1, operand_invalid2;
  logic alu_read_en1, alu_read_en2;

  alu_mem_reg alu_mem_reg (
      .clk(clk),
      .core_en(core_en),
      .rstN(reset),
      .LwD1(LwD1),
      .LwE1(LwE1),
      .LwE2(LwE2),
      .MemWriteE1(MemWriteE1),
      .MemWriteE2(MemWriteE2),
      .JumpE1(JumpE1),
      .JumpE2(JumpE2),
      .stall_m(stall_m),
      .wb_valid(wb_valid),
      .BranchE1(BranchE1),
      .negE1(negE1),
      .predictE1(predictE1),
      .BranchE2(BranchE2),
      .negE2(negE2),
      .predictE2(predictE2),
      .Rs1D1(Rs1D1),
      .Rs2D1(Rs2D1),
      .Rs1E1(Rs1E1),
      .Rs2E1(Rs2E1),
      .RdE1(RdE1),
      .Rs1D2(Rs1D2),
      .Rs2D2(Rs2D2),
      .Rs1E2(Rs1E2),
      .Rs2E2(Rs2E2),
      .RdE2(RdE2),
      .RdD1(RdD1),
      .RdW_mem(RdW_mem),
      .SrcAE1(SrcAE1),
      .SrcBE1(SrcBE1),
      .SrcAE2(SrcAE2),
      .SrcBE2(SrcBE2),
      .ImmExtE1(ImmExtE1),
      .ImmExtE2(ImmExtE2),
      .PCPlus4E1({14'b0, PCPlus8E1}),
      .PCPlus4E2({14'b0, PCPlus8E2}),
      .WriteDataE1(WriteDataE1),
      .WriteDataE2(WriteDataE2),
      .ALUControlE1(ALUControlE1),
      .ALUControlE2(ALUControlE2),
      .BranchControlE1(BranchControlE1),
      .BranchControlE2(BranchControlE2),
      .MemAddrM(ALUResultM),
      .ALUResultW1(ALUResultW1),
      .ALUResultW2(ALUResultW2),
      .WriteDataM(WriteDataM),
      .FWDataAE1(FWDataAE1),
      .FWDataBE1(FWDataBE1),
      .FWDataAE2(FWDataAE2),
      .FWDataBE2(FWDataBE2),
      .RdM(RdM),
      .RdW1(RdW_alu1),
      .RdW2(RdW_alu2),
      .StallE1(StallE1),
      .StallE2(StallE2),
      .lwStallE1(lwStallE1),
      .lwStallE2(lwStallE2),
      .MemWriteM(MemWriteM),
      .LwM(LwM),
      .printM(printM),
      .scanM(scanM),
      .ZeroE1(ZeroE1),
      .ZeroE2(ZeroE2),
      .matchA1(matchA1),
      .matchB1(matchB1),
      .matchA2(matchA2),
      .matchB2(matchB2),
      .flash_m(flash_m),
      .flash_w_mem(flash_w),
      .BranchFailE1(BranchFailE1),
      .BranchFailE2(BranchFailE2),
      .alu_read_en1(alu_read_en1),
      .alu_read_en2(alu_read_en2),
      .PCE1(PCE1),
      .PCE2(PCE2),
      .PCM(PCM),
      .PCW1(PCW1),
      .PCW2(PCW2)
  );

  assign PCSrcE = BranchFailE1 ? predictE1 ? 2'b11 : 2'b10 : BranchFailE2 ? predictE2 ? 2'b11 : 2'b10 : 2'b00;
  assign PCTargetE = BranchFailE1 ? PCTargetE1 : PCTargetE2;
  assign PCPlus8E = BranchFailE1 ? PCPlus8E1 : PCPlus8E2;

  ////////////////////////WriteBack//////////////////////////////
  flopenr #(6) wb_reg (
      clk,
      reset & ~(stall_m & ~stall_w) & ~flash_w,
      core_en & ~(stall_w | stall_m),
      flash_m ? 0 : RdM,
      RdW_mem
  );


  assign ResultW1 = ALUResultW1;

  mux2 #(32) resultmux2 (
      ReadDataW,
      ALUResultW2,
      alu_read_en2,
      ResultW2
  );

endmodule
