module out_controller #(
    CLK_PER_HALF_BIT = 5208
) (
    input  logic       clk,
    reset,
    pc_en,
    print,
    input  logic [7:0] dout_bootloader,
    dout_core,
    input  logic       wr_en_bootloader,
    output logic       txd,
    stall,
    io_end
);
  // logic [7:0] buffer;
  // logic has_buf;

  initial begin
    wr_en = 0;
    dout  = 8'h00;
  end

  logic [7:0] sdata;
  logic readEn, empty, wr_en, full, wr_en_core;
  logic [7:0] dout;

  assign wr_en_core = print;
  assign wr_en = (wr_en_core | wr_en_bootloader) & ~full;
  assign dout = print ? dout_core : dout_bootloader;
  assign stall = print & full;

  fifo #(8, 2 ** 14) fifo (
      clk,
      reset,
      wr_en,
      dout,
      readEn,
      sdata,
      full,  // never be full
      empty
  );

  fifo_tx #(CLK_PER_HALF_BIT) fifo_tx (
      sdata,
      empty,
      txd,
      readEn,
      wr_en,
      clk,
      reset,
      io_end
  );

endmodule
