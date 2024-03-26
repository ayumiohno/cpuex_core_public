module execute_line (
    input logic clk,
    rstN,
    en,
    input logic [3:0] ALUControlE,
    input logic [223:0] FPUResults,
    output logic ready,
    output logic [31:0] Result
);

  typedef enum logic [1:0] {
    DEFAULT,
    FPU_END,
    FPU_WAIT2,
    FPU_WAIT1
  } fpustate_t;

  assign ready = fpustate == FPU_END;

  fpustate_t fpustate;
  initial begin
    fpustate = DEFAULT;
  end

  logic [3:0] ALUControlSave;

  parameter [3:0] 
        FADD = 4'b1000,
        FSUB = 4'b1001,
        FDIV = 4'b1010,
        FSQRT = 4'b1011,
        FCVTWS = 4'b1100,
        FCVTSW = 4'b1101,
        FMUL = 4'b1110;

  always @(posedge clk) begin
    if (en) begin
      case (ALUControlE[2:0])
        // FADD[2:0]: fpustate <= FPU_WAIT1;  //FADD
        // FSUB[2:0]: fpustate <= FPU_WAIT1;  //FSUB
        FDIV[2:0]: fpustate <= FPU_WAIT2;  //FDIV
        FMUL[2:0]: fpustate <= FPU_END;
        FSQRT[2:0]: fpustate <= FPU_END;
        default: fpustate <= FPU_WAIT1;
      endcase
    end else begin
      case (fpustate)
        FPU_WAIT1: fpustate <= FPU_END;
        FPU_WAIT2: fpustate <= FPU_WAIT1;
        FPU_END:   fpustate <= DEFAULT;
        default:   fpustate <= fpustate;
      endcase
    end
    if (en) begin
      ALUControlSave <= ALUControlE;
    end
  end
  always_comb
    case (ALUControlSave[2:0])
      FADD[2:0]:   Result = FPUResults[31:0];
      FSUB[2:0]:   Result = FPUResults[63:32];
      FDIV[2:0]:   Result = FPUResults[95:64];
      FSQRT[2:0]:  Result = FPUResults[127:96];
      FCVTWS[2:0]: Result = FPUResults[159:128];
      FCVTSW[2:0]: Result = FPUResults[191:160];
      FMUL[2:0]:   Result = FPUResults[223:192];
      // FFLOOR[2:0]: Result = FPUResults[223:224];
      default:     Result = 0;
    endcase
endmodule

module state_manager #(
    parameter PC_LEN = 17
) (
    input logic clk,
    rstN,
    input logic [31:0] FPUResult,
    input logic [PC_LEN-3:0] PCE,
    input logic [5:0] RdE,
    input logic ready,
    write_en,
    read_en,
    flash_en,
    output logic [31:0] Result,
    output logic [PC_LEN-3:0] PC,
    output logic [5:0] Rd,
    output logic valid,
    invalid,
    used
);
  always @(posedge clk) begin
    if (write_en) begin
      used <= 1;
      invalid <= 1;
      Rd <= RdE;
      valid <= 0;
      PC <= PCE;
    end else if (read_en | flash_en) begin
      used <= 0;
      Rd <= 0;
      valid <= 0;
      invalid <= 0;
      // if (used & ~read_en & flash_en & Rd != 0)
      //   if (Rd[5]) $display("f%d: skip at %h", Rd[4:0], PC);
      //   else $display("r%d: skip at %h", Rd[4:0], PC);
    end else if (ready) begin
      valid   <= 1;
      invalid <= 0;
      Result  <= FPUResult;
    end
  end
endmodule


module fpu_reg #(
    parameter PC_LEN = 17
) (
    input logic clk,
    rstN,
    fpu_stall_opE,
    StallE,
    input logic [5:0] Rs1E,
    Rs2E,
    RdE,
    input logic [223:0] FPUResults,
    input logic [3:0] ALUControlE,
    input logic [PC_LEN-3:0] PCE,
    output logic RegWrite_fpu,
    output logic [PC_LEN-3:0] PCW_fpu,
    output logic [5:0] RdW_fpu,
    output logic [31:0] ResultW_fpu,
    output logic operand_invalid1,
    operand_invalid2,
    full
);

  logic [31:0] Result1, Result2, FPUResult1, FPUResult2;
  logic valid1, valid2, ready1, ready2, invalid1, invalid2, used1, used2;
  logic [5:0] Rd1, Rd2;
  logic [PC_LEN-3:0] PC1, PC2;

  logic operand_invalid;
  assign operand_invalid1 = Rs1E != 0 & (Rs1E == Rd1 | Rs1E == Rd2);
  assign operand_invalid2 = Rs2E != 0 & (Rs2E == Rd1 | Rs2E == Rd2);
  assign operand_invalid = operand_invalid1 | operand_invalid2;
  assign full = invalid1 & invalid2 & ~ready1 & ~ready2;

  logic use_reg1, use_reg2;
  assign use_reg1 = fpu_stall_opE & ~operand_invalid & (~used1 | ready1);
  assign use_reg2 = fpu_stall_opE & ~operand_invalid & used1 & ~ready1 & (~used2 | valid2 | ready2);
  logic read1, read2;
  assign read1 = ready1;
  assign read2 = ~ready1 & (valid2 | ready2);

  state_manager #(PC_LEN) state_manager1 (
      .clk(clk),
      .rstN(rstN),
      .FPUResult(FPUResult1),
      .PCE(PCE),
      .RdE(RdE),
      .ready(ready1),
      .write_en(use_reg1),
      .read_en(read1),
      .flash_en(RdE == Rd1 & ~StallE),
      .Result(Result1),
      .PC(PC1),
      .Rd(Rd1),
      .valid(valid1),
      .invalid(invalid1),
      .used(used1)
  );

  state_manager #(PC_LEN) state_manager2 (
      .clk(clk),
      .rstN(rstN),
      .FPUResult(FPUResult2),
      .PCE(PCE),
      .RdE(RdE),
      .ready(ready2),
      .write_en(use_reg2),
      .read_en(read2),
      .flash_en(RdE == Rd2 & ~StallE),
      .Result(Result2),
      .PC(PC2),
      .Rd(Rd2),
      .valid(valid2),
      .invalid(invalid2),
      .used(used2)
  );

  execute_line execute_line1 (
      .clk(clk),
      .rstN(rstN),
      .en(use_reg1),
      .ALUControlE(ALUControlE),
      .FPUResults(FPUResults),
      .ready(ready1),
      .Result(FPUResult1)
  );

  execute_line execute_line2 (
      .clk(clk),
      .rstN(rstN),
      .en(use_reg2),
      .ALUControlE(ALUControlE),
      .FPUResults(FPUResults),
      .ready(ready2),
      .Result(FPUResult2)
  );

  always @(posedge clk) begin
    if (ready1) begin
      RdW_fpu <= Rd1;
      ResultW_fpu <= FPUResult1;
      RegWrite_fpu <= 1;
      PCW_fpu <= PC1;
    end else if (valid2 | ready2) begin
      RdW_fpu <= Rd2;
      ResultW_fpu <= ready2 ? FPUResult2 : Result2;
      RegWrite_fpu <= 1;
      PCW_fpu <= PC2;
    end else begin
      RdW_fpu <= 0;
      ResultW_fpu <= 0;
      RegWrite_fpu <= 0;
      PCW_fpu <= 0;
    end
  end

endmodule
