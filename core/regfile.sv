module regfile (
    input logic clk,
    input logic we1,
    we2,
    input logic [5:0] ar1,
    ar2,
    ar3,
    ar4,
    aw1,
    aw2,
    input logic [31:0] wd1,
    wd2,
    output logic [31:0] rd1,
    rd2,
    rd3,
    rd4
);
  logic [31:0] rf[63:0];

  initial rf[1] = 32'hDEADBEEF;

  always_ff @(posedge clk) begin
    if (we1 & aw1 != 0) rf[aw1] <= wd1;
    if (we2 & aw2 != 0) rf[aw2] <= wd2;
  end

  assign rd1 = ar1 == 0 ? 0 : (ar1 == aw2 & we2) ? wd2 : (ar1 == aw1 & we1) ? wd1 : rf[ar1];
  assign rd2 = ar2 == 0 ? 0 : (ar2 == aw2 & we2) ? wd2 : (ar2 == aw1 & we1) ? wd1 : rf[ar2];
  assign rd3 = ar3 == 0 ? 0 : (ar3 == aw2 & we2) ? wd2 : (ar3 == aw1 & we1) ? wd1 : rf[ar3];
  assign rd4 = ar4 == 0 ? 0 : (ar4 == aw2 & we2) ? wd2 : (ar4 == aw1 & we1) ? wd1 : rf[ar4];

endmodule
