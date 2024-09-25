module hazard_unit (
    input logic clk,
    input logic [5:0] Rs1D1,
    Rs2D1,
    Rs1E1,
    Rs2E1,
    RdE1,
    Rs1D2,
    Rs2D2,
    Rs1E2,
    Rs2E2,
    RdE2,
    RdM,
    RdW_alu1,
    RdW_alu2,
    RdW_mem,
    input logic JumpD1,
    JumpRD1,
    JumpRD2,
    BranchFailE1,
    BranchFailE2,
    lwStallE1,
    lwStallE2,
    wb_valid,
    input logic StallE1,
    StallE2,
    output logic StallF,
    StallD1,
    StallD2,
    output logic FlashD1,
    FlashD2,
    output logic FlashE1,
    FlashE2,
    output logic [1:0] ForwardAE1,
    ForwardAE2,
    ForwardBE1,
    ForwardBE2,
    output lwStall,
    LwM,
    LwW
);

  logic StallE1_prev, StallE2_prev;
  always_ff @(posedge clk) begin
    StallE1_prev <= StallE1;
    StallE2_prev <= StallE2;
  end
  assign ForwardAE1 = (Rs1E1 == RdW_alu2 & Rs1E1 != 0) ? 2'b01 : (Rs1E1 == RdW_alu1 & Rs1E1 != 0) ? 2'b10 : StallE1_prev ? 2'b11 : 2'b00;
  assign ForwardBE1 = (Rs2E1 == RdW_alu2 & Rs2E1 != 0) ? 2'b01 :(Rs2E1 == RdW_alu1 & Rs2E1 != 0) ? 2'b10 :  StallE1_prev ? 2'b11 :2'b00;
  assign ForwardAE2 = (Rs1E2 == RdW_alu2 & Rs1E2 != 0) ? 2'b01 :(Rs1E2 == RdW_alu1 & Rs1E2 != 0) ?  2'b10 : StallE2_prev ? 2'b11 : 2'b00;
  assign ForwardBE2 = (Rs2E2 == RdW_alu2 & Rs2E2 != 0) ? 2'b01 :(Rs2E2 == RdW_alu1 & Rs2E2 != 0) ? 2'b10 :  StallE2_prev ? 2'b11 :2'b00;


  logic lwStallM, lwStallW;
  assign lwStallM = RdM != 0 & (Rs1D1 == RdM | Rs2D1 == RdM | Rs1D2 == RdM | Rs2D2 == RdM);
  assign lwStallW = RdW_mem != 0 & (~wb_valid | (JumpRD1 & (Rs1D1 == RdW_mem | Rs2D1 == RdW_mem)) | (JumpRD2 & (Rs1D2 == RdW_mem | Rs2D2 == RdW_mem)));
  assign lwStall = lwStallE1 | lwStallM | lwStallW;

  assign StallF = (lwStall | (lwStallE2 & ~JumpD1 & ~JumpRD1) | StallE1 | StallE2) & ~(BranchFailE1 | BranchFailE2);
  assign StallD1 = lwStall | StallE1 | StallE2;
  assign StallD2 = lwStall | (lwStallE2 & ~JumpD1 & ~JumpRD1) | StallE1 | StallE2;

  assign FlashD1 = BranchFailE1 | BranchFailE2 | (StallF & ~StallD1);
  assign FlashD2 = BranchFailE1 | BranchFailE2 | (StallF & ~StallD2);
  assign FlashE1 = (~StallE1 & (StallD1 | BranchFailE2)) | BranchFailE1;
  assign FlashE2 = (~StallE2 & (StallD2 | JumpD1 | JumpRD1)) | BranchFailE1 | BranchFailE2;

endmodule
