module alu (
    input logic [31:0] SrcA,
    input logic [31:0] SrcB,
    input logic [31:0] SrcA_shift,
    input logic [3:0] ALUControl,
    input logic [1:0] BranchControl,
    output logic [31:0] ALUResult,
    AddResult,
    output logic Zero
);
  parameter ADD = 4'b0000;
  parameter SUB = 4'b0001;
  parameter SCOMP = 4'b1000;
  parameter LUI = 4'b1001;
  parameter SLL = 4'b1010;
  parameter SRL = 4'b1011;
  parameter SRA = 4'b1100;
  parameter AND = 4'b1101;
  parameter OR = 4'b1110;
  parameter XOR = 4'b1111;

  assign AddResult = SrcA_shift + SrcB;

  always_comb
    case (ALUControl[3])
      0: ALUResult = ALUControl[0] ? SrcA - SrcB : AddResult;
      1:
      case (ALUControl[2:0])
        LUI[2:0]: ALUResult = SrcB;  //lui
        OR[2:0]:  ALUResult = SrcA | SrcB;  //or, ori
        // AND[2:0]: ALUResult = SrcA & SrcB;  //and, andi
        XOR[2:0]: ALUResult = SrcA ^ SrcB;  //xor, xori
        SLL[2:0]: ALUResult = SrcA << SrcB[4:0];  //sll
        SRL[2:0]: ALUResult = SrcA >> SrcB[4:0];  //srl

        // SRA[2:0]: ALUResult = SrcA >>> SrcB[4:0];  //sra
        default: ALUResult = {31'b0, Zero};
      endcase
    endcase

  always_comb
    case (BranchControl[0])
      1: Zero = BranchControl[1] ? SrcA < SrcB : SrcA == SrcB;
      0: Zero = $signed(SrcA) < $signed(SrcB);
    endcase
endmodule
