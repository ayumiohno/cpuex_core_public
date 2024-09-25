module input_controller #(
    CLK_PER_HALF_BIT = 5208
) (
    input  logic        clk,
    reset,
    pc_start,
    pc_en,
    rxd,
    scan,
    output logic [31:0] ReadData,
    output logic        stall,
    valid
);

  logic [31:0] rword, dout, read_data;
  logic rword_ready, ferr;
  logic wr_en, full, empty, readEn;

  fifo #(32, 325, "input") fifo (
      clk,
      reset,
      wr_en,
      dout,
      readEn,
      ReadData,
      full,  // never be full
      empty
  );
  //   fifo #(32, 2 ** 12, "input") fifo (
  //       clk,
  //       reset,
  //       wr_en,
  //       dout,
  //       readEn,
  //       ReadData,
  //       full,  // never be full
  //       empty
  //   );

  uart_word #(CLK_PER_HALF_BIT) uart_word (
      rword,
      rword_ready,
      ferr,
      pc_start ? rxd : 1'b1,
      clk,
      reset
  );

  // to pass the data to core
  assign readEn = scan & ~empty & ~wr_en;
  assign stall  = scan & (empty | wr_en);
  always @(posedge clk) valid <= readEn;

  // to receive
  assign wr_en = rword_ready;
  assign dout  = rword;

  //   always @(posedge clk) begin
  //     if (valid) begin
  //       $display("ScandData: %h", ReadData);
  //     end
  //     if (stall) begin
  //       $display("Scan Stall");
  //     end
  //     if (readEn) begin
  //       $display("readEn");
  //     end
  //     if (wr_en) begin
  //       $display("wr_en");
  //     end
  //   end
endmodule
