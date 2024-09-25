module controller (
    input logic [6:0] op,
    input logic [2:0] funct3,
    input logic [6:0] funct7,
    output logic RegWrite,
    FPURegWrite,
    output logic [1:0] ResultSrc,
    output logic MemWrite,
    Jump,
    JumpR,
    Branch,
    output logic ALUSrcb,
    output logic [2:0] ImmSrc,
    output logic [6:0] ALUControl,
    output logic neg,
    output logic FPUSrcA,
    FPUSrcB,
    Lw,
    output logic [1:0] BranchControl
);

  logic [1:0] ALUOp, BranchControl1;
  logic RegWriteMain;
  logic IsRegWriteFPU;
  logic FPU, neg1, neg2, FPUSrcATMP;
  logic cvt_s_w;
  logic fpu_stall_op_fpu;
  logic [2:0] ImmSrcMain;
  logic shift;

  logic FPUResultSrc;  // TODO: delete

  maindec md (
      op,
      RegWriteMain,
      ResultSrc,
      MemWrite,
      Jump,
      JumpR,
      Branch,
      ALUOp,
      ALUSrcb,
      ImmSrcMain,
      FPU,
      FPUResultSrc,
      FPUSrcATMP,
      FPUSrcB,
      Lw
  );

  logic [6:0] ALUControl1, ALUControl2;
  aludec ad (
      op[5],
      funct3,
      funct7[5],
      ALUOp,
      ALUControl1,
      neg1,
      shift,
      BranchControl1
  );

  fpudec fd (
      funct3,
      funct7[6:2],
      ALUOp,
      ALUControl2,
      IsRegWriteFPU,
      neg2,
      cvt_s_w
  );

  assign ALUControl = FPU ? ALUControl2 : ALUControl1;
  assign RegWrite = FPU ? RegWriteMain & ~IsRegWriteFPU : RegWriteMain;
  assign FPURegWrite = FPU ? RegWriteMain & IsRegWriteFPU : 0;
  assign neg = FPU ? neg2 : neg1;
  assign FPUSrcA = FPU && cvt_s_w ? 1'b0 : FPUSrcATMP;
  assign ImmSrc = shift & ~FPU ? 3'b101 : ImmSrcMain;
  assign BranchControl = FPU ? 0 : BranchControl1;

endmodule
