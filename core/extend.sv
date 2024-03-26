module extend (
    input  logic [31:7] instr,
    input  logic [ 2:0] immsrc,
    input  logic        rs2_1,
    output logic [31:0] immext
);
  parameter F0 = 32'h00000000,
F1 = 32'h3C23D70A,
F2 = 32'hBF800000,
F3 = 32'hBE4CCCCD,
F4 = 32'hBDCCCCCD,
F5 = 32'h4CBEBC20,
F6 = 32'h43160000,
F7 = 32'hC3160000;

  always_comb
    case (immsrc[2])
      0:
      case (immsrc[1:0])
        2'b00: immext = {{20{instr[31]}}, instr[31:20]};  // I-type
        2'b01: immext = {{20{instr[31]}}, instr[31:25], instr[11:7]};  //S-type
        2'b10: immext = {instr[31:12], 12'b0};  //LUI
        2'b11: immext = {{20'b0}, instr[31:20]};  // I-type unsigned
      endcase
      1:
      case (immsrc[0])
        0: immext = rs2_1 ? 32'd99 : 32'd2;  // B-type 
        1:
        immext = instr[26] ? instr[25] ? instr[24] ? F7 : F6 : instr[24] ? F5: F4 :
                    instr[25] ? instr[24] ? F3 : F2 : instr[24] ? F1 : F0;  // F-type
      endcase
    endcase
endmodule
