module fpudec (
    input  logic [2:0] funct3,
    input  logic [4:0] funct7b6to2,
    input  logic [1:0] ALUop,
    output logic [6:0] ALUControl,
    output logic       FPURegWrite,
    neg,
    not_fpu_src_a
);

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
  parameter FMV = 7'b100001;
  parameter FSGNJ = 7'b100010;
  parameter FSGNJN = 7'b100011;

  parameter ADD = 7'b0;

  always_comb
    case (ALUop)
      2'b00: begin
        ALUControl = ADD;  //LW/SW
        FPURegWrite = 1'b1;
        neg = 1'b0;
        not_fpu_src_a = 1'b0;
      end
      default: begin  //RType
        case (funct7b6to2)
          5'b00000: ALUControl = FADD;  // ADD
          5'b00001: ALUControl = FSUB;  // SUB
          5'b00010: ALUControl = FMUL;  // MUL
          5'b00011: ALUControl = FDIV;  // DIV
          5'b01011: ALUControl = FSQRT;  // SQRT
          5'b00100:
          case (funct3)
            3'b000:  ALUControl = FSGNJ;  // fsgnj
            3'b001:  ALUControl = FSGNJN;  // fsgnjn
            default: ALUControl = 7'bx;
          endcase
          5'b11000: ALUControl = FCVTWS;  // fcvt.w.s
          5'b11010: ALUControl = FCVTSW;  // fcvt.s.w
          5'b11100: ALUControl = FMV;  // fmv.x.w
          5'b11110: ALUControl = FMV;  // fmv.w.x
          5'b10100:
          case (funct3)
            3'b010:  ALUControl = FEQ;  // eq
            3'b001:  ALUControl = FLT;  // lt
            3'b000:  ALUControl = FLE;  // le
            default: ALUControl = 7'bxxx;
          endcase
          default: ALUControl = 7'bxxx;
        endcase
        // not fcvt.w.s and not compare and not fmv.x.w
        FPURegWrite = funct7b6to2 != 5'b10100 & funct7b6to2 != 5'b11000 & funct7b6to2 != 5'b11100;
        neg = 1'b0;
        // fcvt.w.s and fmv.w.x
        not_fpu_src_a = funct7b6to2 == 5'b11010 | funct7b6to2 == 5'b11110;
      end
    endcase
endmodule
