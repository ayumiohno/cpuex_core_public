module imem (
    input logic clk,
    we,
    re,  //read enable
    input logic [17:0] a,
    input logic [63:0] wd,
    output logic [63:0] rd
);
  (* ram_style = "block" *)
  logic [63:0] RAM[0:2**14-1];

  // initial $readmemh("data/fib5.data", RAM);

  always_ff @(posedge clk) begin
    if (re) rd <= RAM[a[16:3]];
    if (we) RAM[a[16:3]] <= wd;
  end
endmodule
