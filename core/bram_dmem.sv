module bram_dmem (
    input logic clk,
    re,
    we,
    input logic [10:0] a,
    wa,
    input logic [31:0] wd,
    output logic [31:0] rd
);
  (* ram_style = "block" *)
  logic [31:0] RAM[0:2**11-1];

  always_ff @(posedge clk) begin
    if (we) RAM[wa] <= wd;
    if (re) rd <= RAM[a];
  end
endmodule
