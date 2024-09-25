module maindec (
    input logic [6:0] op,
    output logic RegWrite,
    output logic [1:0] ResultSrc,
    output logic MemWrite,
    Jump,
    JumpR,
    Branch,
    output logic [1:0] ALUOp,
    output logic ALUSrcb,
    output logic [2:0] ImmSrc,
    output logic FPU,
    FPUResultSrc,
    FPUSrcA,
    FPUSrcB,
    Lw
);

  parameter RTYPE = 7'b0110011;
  parameter ITYPE = 7'b0010011;
  parameter BTYPE = 7'b1100011;
  parameter JAL = 7'b1101111;
  parameter JALR = 7'b1100111;
  parameter LW = 7'b0000011;
  parameter SW = 7'b0100011;
  parameter FRTYPE = 7'b1010011;
  parameter FLW = 7'b0000111;
  parameter FSW = 7'b0100111;
  parameter LUI = 7'b0110111;

  logic [17:0] controls;
  assign {RegWrite, ImmSrc, ALUSrcb, MemWrite, ResultSrc, Branch, ALUOp, Jump, JumpR, FPU, FPUResultSrc, FPUSrcA, FPUSrcB, Lw} = controls;

  always_comb
    case (op)
      LW: controls = 18'b1_000_1_0_01_0_00_00_0000_1;
      SW: controls = 18'b0_001_1_1_00_0_00_00_0000_0;
      FLW: controls = 18'b1_000_1_0_01_0_00_00_1000_1;
      FSW: controls = 18'b0_001_1_1_00_0_00_00_1001_0;
      RTYPE: controls = 18'b1_xxx_0_0_00_0_10_00_0000_0;
      FRTYPE: controls = 18'b1_xxx_0_0_00_0_10_00_1111_0;
      BTYPE: controls = 18'b0_010_0_0_00_1_01_00_0000_0;  //btype
      ITYPE: controls = 18'b1_000_1_0_00_0_10_00_0000_0;  //I-type ALU
      JAL: controls = 18'b1_011_0_0_10_0_00_10_0000_0;
      JALR: controls = 18'b1_000_1_0_10_0_00_01_0000_0;
      LUI: controls = 18'b1_100_1_0_00_0_11_00_0000_0;  //lui
      default: controls    = 18'bx_xxx_x_x_xx_x_xx_xx_xxxx_x;
    endcase
endmodule
