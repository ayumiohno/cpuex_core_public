module controller (
    input logic [6:0] op,
    input logic [2:0] funct3,
    input logic [6:0] funct7,
    output logic RegWrite,
    FPURegWrite,
    output logic ResultSrc,
    output logic MemWrite,
    Jump,
    JumpR,
    Branch,
    output logic ALUSrcb,
    output logic [2:0] ImmSrc,
    output logic [3:0] ALUControl,
    output logic neg,
    output logic FPUResultSrc,
    FPUSrcA,
    FPUSrcB,
    Lw,
    fpu_stall_op,
    shift2,
    shift6,
    lw_add,
    output logic [1:0] BranchControl
);

  logic [1:0] ALUOp, BranchControl1;
  logic RegWriteMain;
  logic RegWriteALU;
  logic FPU, neg1, FPUSrcATMP;
  logic cvt_s_w;
  logic fpu_stall_op_fpu;
  logic [2:0] ImmSrcMain;
  logic shift, shift2_alu, shift6_alu, beq_imm, ALUSrcb_main, Lw_main, lw_add_alu, FPURegWrite_main;

  maindec md (
      op,
      RegWriteMain,
      FPURegWrite_main,
      ResultSrc,
      MemWrite,
      Jump,
      JumpR,
      Branch,
      ALUOp,
      ALUSrcb_main,
      ImmSrcMain,
      FPU,
      FPUResultSrc,
      FPUSrcATMP,
      FPUSrcB,
      Lw_main
  );

  logic [3:0] ALUControl1, ALUControl2;
  aludec ad (
      op[5],
      funct3,
      funct7[4],
      funct7[5],
      funct7[6],
      ALUSrcb,  // itype
      ~FPU & Lw_main,  // lw
      ALUOp,
      ALUControl1,
      neg1,
      shift,
      shift2_alu,
      shift6_alu,
      lw_add_alu,
      beq_imm,
      BranchControl1
  );

  fpudec fd (
      funct3,
      funct7[6:2],
      ALUOp,
      ALUControl2,
      RegWriteALU,
      cvt_s_w,
      fpu_stall_op_fpu
  );

  assign ALUControl = FPU ? ALUControl2 : ALUControl1;
  assign RegWrite = FPU ? RegWriteALU : RegWriteMain;
  assign FPURegWrite = FPU ? FPURegWrite_main & ~RegWriteALU : FPURegWrite_main;
  assign neg = FPU ? 0 : neg1;
  assign FPUSrcA = FPU & cvt_s_w ? 1'b0 : FPUSrcATMP;
  assign fpu_stall_op = FPUResultSrc ? fpu_stall_op_fpu : 0;
  //   assign FPUSrcA = 1'b0;
  assign ImmSrc = shift & ~FPU ? 3'b011 : ImmSrcMain;
  assign BranchControl = FPU ? 0 : BranchControl1;
  assign shift2 = FPU ? 0 : shift2_alu;
  assign shift6 = FPU ? 0 : shift6_alu;
  assign lw_add = FPU ? 0 : lw_add_alu;
  assign ALUSrcb = FPU ? ALUSrcb_main : ALUSrcb_main | beq_imm;
  assign Lw = FPU ? Lw_main : Lw_main | lw_add_alu;
  //   assign ALUSrcb = ALUSrcb_main | (~FPU & beq_imm);

endmodule
