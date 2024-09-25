module fpu (
    input logic clk,
    rstn,
    input logic [31:0] SrcA,
    input logic [31:0] SrcB,
    output logic [226:0] FPUResult
);
  logic [31:0]
      fadd_res, fsub_res, fmul_res, fdiv_res, fsqrt_res, fcvtws_res, fcvtsw_res, ALUResult_sv;
  logic [31:0]
      fadd_res_reg,
      fsub_res_reg,
      fmul_res_reg,
      fdiv_res_reg,
      fsqrt_res_reg,
      fcvtws_res_reg,
      fcvtsw_res_reg;
  logic feq_res, flt_res, fle_res;

  logic [31:0] SrcA_reg, SrcB_reg;
  always @(posedge clk) begin
    SrcA_reg <= SrcA;
    SrcB_reg <= SrcB;
  end
  fadd fadd (
      SrcA_reg,
      SrcB_reg,
      fadd_res,
      clk,
      rstn
  );
  fsub fsub (
      SrcA_reg,
      SrcB_reg,
      fsub_res,
      clk,
      rstn
  );
  fmul fmul (
      SrcA_reg,
      SrcB_reg,
      fmul_res,
      clk,
      rstn
  );
  fdiv fdiv (
      SrcA_reg,
      SrcB_reg,
      fdiv_res,
      clk,
      rstn
  );
  fsqrt fsqrt (
      SrcA_reg,
      fsqrt_res,
      clk,
      rstn
  );
  feq feq (
      SrcA_reg,
      SrcB_reg,
      feq_res
  );

  flt flt (
      SrcA_reg,
      SrcB_reg,
      flt_res
  );

  fle fle (
      SrcA_reg,
      SrcB_reg,
      fle_res
  );

  fcvtws fcvtws (
      SrcA_reg,
      fcvtws_res,
      clk,
      rstn
  );

  fcvtsw fcvtsw (
      SrcA_reg,
      fcvtsw_res,
      clk,
      rstn
  );

  always @(posedge clk) begin
    fadd_res_reg   <= fadd_res;
    fsub_res_reg   <= fsub_res;
    fmul_res_reg   <= fmul_res;
    fdiv_res_reg   <= fdiv_res;
    fsqrt_res_reg  <= fsqrt_res;
    fcvtws_res_reg <= fcvtws_res;
    fcvtsw_res_reg <= fcvtsw_res;
  end

  assign FPUResult = {
    fcvtsw_res_reg,
    fcvtws_res_reg,
    flt_res,
    fle_res,
    feq_res,
    fsqrt_res_reg,
    fdiv_res,
    fmul_res,
    fsub_res,
    fadd_res
  };

endmodule
