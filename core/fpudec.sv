module fpudec (
    input  logic [2:0] funct3,
    input  logic [4:0] funct7b6to2,
    input  logic [1:0] ALUop,
    output logic [3:0] ALUControl,
    output logic       ALURegWrite,
    not_fpu_src_a,
    fpu_stall_op
);

  parameter ADD = 4'b0000;
  parameter [3:0] 
        FADD = 4'b1000,
        FSUB = 4'b1001,
        FDIV = 4'b1010,
        FSQRT = 4'b1011,
        FCVTWS = 4'b1100,
        FCVTSW = 4'b1101,
        FMUL = 4'b1110;
  parameter [3:0]
        FEQ = 4'b0000,
        FLT = 4'b0001,
        FLE = 4'b0010,
        FLEABS = 4'b0011,
        FHALF = 4'b0100,
        FSIGNJ = 4'b0101,
        FSIGNJN = 4'b0110,
        FSIGNJX = 4'b0111;

  always_comb
    case (ALUop)
      2'b00: begin
        ALUControl = ADD;  //LW/SW
        ALURegWrite = 1'b0;
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
          case (funct3[1:0])
            2'b00:   ALUControl = FSIGNJ;  // fsgnj
            2'b01:   ALUControl = FSIGNJN;  // fsgnjn
            2'b10:   ALUControl = FSIGNJX;  // fsgnjx
            default: ALUControl = 4'b0;
          endcase
          5'b11000: ALUControl = FCVTWS;  // fcvt.w.s
          5'b11010: ALUControl = FCVTSW;  // fcvt.s.w
          5'b00101: ALUControl = FHALF;  // falf
          5'b10100:
          case (funct3[1:0])
            2'b10: ALUControl = FEQ;  // eq
            2'b01: ALUControl = FLT;  // lt
            2'b00: ALUControl = FLE;  // le
            2'b11: ALUControl = FLEABS;  // leabs
          endcase
          default: ALUControl = 4'b0;
        endcase
        // fcvt.w.s or compare
        ALURegWrite   = funct7b6to2 == 5'b11000 | funct7b6to2 == 5'b10100;
        // fcvt.w.s
        not_fpu_src_a = funct7b6to2 == 5'b11010;
      end
    endcase

  assign fpu_stall_op = ALUControl[3];

endmodule
