module hazard_unit (
    input logic clk,
    input logic [5:0] Rs1D,
    input logic [5:0] Rs2D,
    input logic [5:0] Rs1E,
    input logic [5:0] Rs2E,
    input logic [5:0] RdE,
    input logic [5:0] RdM,
    input logic [5:0] RdW,
    input logic [5:0] RdW_fpu,
    input logic LwE,
    input logic RegWriteE,
    input logic RegWriteM,
    input logic RegWriteW,
    input logic RegWriteW_fpu,
    input logic PCJump,
    JumpRD,
    operand_invalid1,
    operand_invalid2,
    full,
    output logic StallF,
    StallD,
    StallE,
    StallM,
    output logic FlashD,
    output logic FlashE,
    FlashM,
    output logic [2:0] ForwardAE,
    output logic [2:0] ForwardBE,
    input logic core_en,
    stall_m,
    stall_w,
    use_prev_data1,
    use_prev_data2,
    output lwStall,
    input fpu_stall_op,
    LwM,
    LwW
);

  logic operand_invalid;
  assign operand_invalid = operand_invalid1 | operand_invalid2;

  // logic use_prev_data1, use_prev_data2;
  // always @(posedge clk) begin
  //   use_prev_data1 <= ~operand_invalid1 & StallE;
  //   use_prev_data2 <= ~operand_invalid2 & StallE;
  // end

  assign ForwardAE = use_prev_data1 ? 3'b11 : (Rs1E == RdM & RegWriteM) ? 3'b100 : (Rs1E == RdW & RegWriteW) ? 3'b10 :
    (Rs1E == RdW_fpu & RegWriteW_fpu) ? 3'b01 : 3'b00;
  assign ForwardBE = use_prev_data2 ? 3'b11 : (Rs2E == RdM & RegWriteM) ? 3'b100 : (Rs2E == RdW & RegWriteW) ? 3'b10 :
    (Rs2E == RdW_fpu & RegWriteW_fpu) ? 3'b01 : 3'b00;

  // logic lwStall;
  logic lwStallE, lwStallM, lwStallW;
  assign lwStallE = LwE & (Rs1D == RdE | Rs2D == RdE);
  assign lwStallM = LwM & (Rs1D == RdM | Rs2D == RdM);
  assign lwStallW = LwW & (Rs1D == RdW | Rs2D == RdW) & (stall_w | JumpRD);
  assign lwStall  = lwStallE | lwStallM | lwStallW;

  assign StallF   = StallD & ~PCJump;
  assign StallD   = lwStall | StallE;
  assign StallE   = (fpu_stall_op ? full : StallM) | operand_invalid;
  assign StallM   = stall_m | stall_w;

  assign FlashD   = PCJump;  // Branch
  // assign FlashE = lwStallE | ((~operand_invalid | StallM) & PCJump);  
  assign FlashE   = ~StallE & (StallD | PCJump);
  assign FlashM   = ~StallM & (StallE | fpu_stall_op);

endmodule
