module imem (
    input logic clk,
    we,
    re,  //read enable
    input logic [PC_LEN-3:0] a,
    input logic [31:0] wd,
    output logic [31:0] rd
);
  parameter PC_LEN = 17;
  (* ram_style = "block" *)
  logic [31:0] RAM[0:2**(PC_LEN-2)-1];

  // initial $readmemh("data/fib5.data", RAM);

  always_ff @(posedge clk) begin
    if (re) rd <= RAM[a];
    if (we) RAM[a] <= wd;
  end
endmodule
