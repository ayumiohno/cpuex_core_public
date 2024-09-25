module alu (
    input logic [31:0] SrcA,
    input logic [31:0] SrcB,
    input logic [6:0] ALUControl,
    input logic [1:0] BranchControl,
    output logic [31:0] ALUResult,
    output logic Zero
);
  parameter ADD = 7'b0;
  parameter SUB = 7'b1;
  parameter SCOMP = 7'b100100;
  parameter SLL = 7'b101000;
  parameter SRL = 7'b101100;
  parameter SRA = 7'b110000;
  parameter AND = 7'b110100;
  parameter OR = 7'b111000;
  parameter XOR = 7'b111100;
  parameter LUI = 7'b100000;
  parameter FMV = 7'b100001;
  parameter FSGNJ = 7'b100010;
  parameter FSGNJN = 7'b100011;

  always_comb
    case (ALUControl[5])
      0: ALUResult = ALUControl[0] ? SrcA - SrcB : SrcA + SrcB;
      1:
      case (ALUControl[4:2])
        OR[4:2]: ALUResult = SrcA | SrcB;  //or, ori
        AND[4:2]: ALUResult = SrcA & SrcB;  //and, andi
        XOR[4:2]: ALUResult = SrcA ^ SrcB;  //xor, xori
        SLL[4:2]: ALUResult = SrcA << SrcB[4:0];  //sll
        SRL[4:2]: ALUResult = SrcA >> SrcB[4:0];  //srl
        SRA[4:2]: ALUResult = SrcA >>> SrcB[4:0];  //sra
        SCOMP[4:2]: ALUResult = {31'b0, Zero};
        default:
        case (ALUControl[1:0])
          LUI[1:0]: ALUResult = SrcB;  //lui
          FMV[1:0]: ALUResult = SrcA;  //fmv
          FSGNJ[1:0]: ALUResult = {SrcA[31], SrcB[30:0]};  //fsgnj
          FSGNJN[1:0]: ALUResult = {~SrcA[31], SrcB[30:0]};  //fsgnjn
        endcase
      endcase
    endcase

  always_comb
    case (BranchControl)
      2'b01:   Zero = SrcA == SrcB;
      2'b11:   Zero = SrcA < SrcB;
      2'b10:   Zero = $signed(SrcA) < $signed(SrcB);
      default: Zero = 1'b0;
    endcase
  // assign Zero = ALUResult[0];
endmodule
