module aludec (
    input logic opb5,
    input logic [2:0] funct3,
    input logic funct7b5,
    input logic [1:0] ALUOp,
    output logic [6:0] ALUControl,
    output logic neg,
    shift,
    output logic [1:0] BranchControl
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


  logic RtypeSub;
  assign RtypeSub = funct7b5 & opb5;

  always_comb
    case (ALUOp)
      2'b00: begin
        ALUControl = ADD;  //addition
        neg = 1'b0;
        BranchControl = 2'b00;
      end
      2'b11: begin  //lui
        ALUControl = LUI;
        neg = 1'b0;
        BranchControl = 2'b00;
      end
      2'b01: begin
        ALUControl = SCOMP;
        case (funct3)
          3'b000: begin
            neg = 1'b0;
            BranchControl = 2'b01;
          end
          3'b001: begin
            neg = 1'b1;
            BranchControl = 2'b01;
          end
          3'b100: begin
            neg = 1'b0;
            BranchControl = 2'b10;
          end
          3'b101: begin
            neg = 1'b1;
            BranchControl = 2'b10;
          end
          3'b110: begin
            neg = 1'b0;
            BranchControl = 2'b11;
          end
          3'b111: begin
            neg = 1'b1;
            BranchControl = 2'b11;
          end
          default: begin
            ALUControl = 7'bxxx;
            neg = 1'bx;
            BranchControl = 2'bxx;
          end
        endcase
      end
      default: begin
        neg = 1'b0;
        BranchControl = 2'b00;
        case (funct3)  // R-type of I-type ALU
          3'b000:
          if (RtypeSub) ALUControl = SUB;  //sub
          else ALUControl = ADD;  //add, addi
          3'b010: begin
            ALUControl = SCOMP;  //slt, slti
            BranchControl = 2'b10;
          end
          3'b110: ALUControl = OR;  //or, ori
          3'b100: ALUControl = XOR;  //xor, xori
          3'b011: begin
            ALUControl = SCOMP;  //sltu, sltiu
            BranchControl = 2'b11;
          end
          3'b111: ALUControl = AND;  //and, andi
          3'b001: ALUControl = SLL;  //sll
          3'b101:
          case (funct7b5)
            0: ALUControl = SRL;  //srl
            1: ALUControl = SRA;  //sra
          endcase
          default: ALUControl = 7'bxxx;
        endcase
      end
    endcase
  assign shift = ALUOp == 2'b10 & (funct3 == 3'b001 | funct3 == 3'b101);
endmodule
