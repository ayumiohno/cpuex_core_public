module fpu (
    input logic clk,
    rstn,
    input logic [31:0] SrcA,
    input logic [31:0] SrcB,
    input logic [3:0] ALUControl,
    output logic [31:0] FPUResult,
    output logic [223:0] FPUResults
);
  logic [31:0] fadd_res, fsub_res, fmul_res, fdiv_res, fsqrt_res, fcvtws_res, fcvtsw_res, fhalf_res;
  logic feq_res, flt_res, fle_res;

  logic [31:0] SrcA_reg, fcvtws_res_reg, fcvtsw_res_reg;
  always_ff @(posedge clk) begin
    SrcA_reg <= SrcA;
    fcvtws_res_reg <= fcvtws_res;
    fcvtsw_res_reg <= fcvtsw_res;
  end

  fadd fadd (
      SrcA,
      SrcB,
      fadd_res,
      clk,
      rstn
  );
  fsub fsub (
      SrcA,
      SrcB,
      fsub_res,
      clk,
      rstn
  );
  fmul fmul (
      SrcA,
      SrcB,
      fmul_res,
      clk,
      rstn
  );
  fdiv fdiv (
      SrcA,
      SrcB,
      fdiv_res,
      clk,
      rstn
  );
  fsqrt fsqrt (
      SrcA,
      fsqrt_res,
      clk,
      rstn
  );
  feq feq (
      SrcA,
      SrcB,
      feq_res
  );

  flt flt (
      SrcA,
      SrcB,
      flt_res
  );

  fle fle (
      SrcA,
      ALUControl[0] ? {1'b0, SrcB[30:0]} : SrcB,
      fle_res
  );

  fcvtws fcvtws (
      SrcA_reg,
      fcvtws_res,
      clk,
      rstn
  );

  fcvtsw fcvtsw (
      SrcA,
      fcvtsw_res,
      clk,
      rstn
  );

  fhalf fhalf (
      SrcA,
      fhalf_res,
      clk,
      rstn
  );

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
    case (ALUControl[2])
      1:
      case (ALUControl[1:0])
        FHALF[1:0]:   FPUResult = fhalf_res;
        FSIGNJ[1:0]:  FPUResult = {SrcB[31], SrcA[30:0]};
        FSIGNJN[1:0]: FPUResult = {~SrcB[31], SrcA[30:0]};
        FSIGNJX[1:0]: FPUResult = {1'b0, SrcA[30:0]};
      endcase
      0: FPUResult = {31'b0, ALUControl[1] ? fle_res : ALUControl[0] ? flt_res : feq_res};
    endcase

  assign FPUResults = {
    fmul_res, fcvtsw_res_reg, fcvtws_res_reg, fsqrt_res, fdiv_res, fsub_res, fadd_res
  };
endmodule
