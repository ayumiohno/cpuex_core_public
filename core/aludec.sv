module aludec (
    input logic opb5,
    input logic [2:0] funct3,
    input logic funct7b4,
    input logic funct7b5,
    input logic funct7b6,
    itype,
    lw,
    input logic [1:0] ALUOp,
    output logic [3:0] ALUControl,
    output logic neg,
    shift,
    shift2,
    shift6,
    lw_add,
    beq_imm,
    output logic [1:0] BranchControl
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

  logic RtypeSub;
  assign RtypeSub = funct7b5 & opb5;

  always_comb begin
    shift2  = 0;
    shift6  = 0;
    beq_imm = 0;
    lw_add  = 0;
    case (ALUOp)
      2'b00: begin  // LW
        ALUControl = ADD;  //addition
        neg = 1'b0;
        BranchControl = 2'b00;
        shift2 = lw & funct3[1:0] == 2'b00;
        shift6 = lw & funct3[1:0] == 2'b01;
      end
      2'b11: begin  //lui or fload
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
          3'b010: begin
            neg = 1'b0;
            BranchControl = 2'b01;
            beq_imm = 1;
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
            ALUControl = 4'b0;
            neg = 1'b0;
            BranchControl = 2'b0;
          end
        endcase
      end
      default: begin
        neg = 1'b0;
        BranchControl = 2'b00;
        case (funct3)  // R-type of I-type ALU
          3'b000: begin
            if (RtypeSub) ALUControl = SUB;  //sub
            else ALUControl = ADD;  //add, addi
            shift2 = ~itype & funct7b6;
            lw_add = ~itype & funct7b4;
          end
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
          default: ALUControl = 4'b0;
        endcase
      end
    endcase
  end
  assign shift = ALUOp == 2'b10 & (funct3 == 3'b001 | funct3 == 3'b101);
endmodule
