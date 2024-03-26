module test_top #(
    CLK_PER_HALF_BIT = 8
) (
    input  logic        clk,
    reset,
    rxd,
    start,
    output logic        txd,
    output logic [31:0] dout,
    output logic        all_end
);

  logic [25-1:0] cache_req_addr;
  logic [31:0] cache_req_data, cache_rsp_data;
  logic cache_req_wr, cache_req_valid, cache_req_ready, cache_rsp_valid;

  core_top #(CLK_PER_HALF_BIT) core_top (
      clk,
      reset,
      rxd,
      start,
      txd,
      dout,
      all_end,
      cache_req_addr,
      cache_req_data,
      cache_req_wr,
      cache_req_valid,
      cache_req_ready,
      cache_rsp_data,
      cache_rsp_valid
  );

  master_fifo master_fifo ();

  // master
  cache_controller cache_controller (
      .fifo(master_fifo),
      .clk(clk),
      .wr(cache_req_wr),
      .addr(cache_req_addr),
      .data(cache_req_data),
      .req_valid(cache_req_valid),
      .req_ready(cache_req_ready),
      .rsp_data(cache_rsp_data),
      .rsp_valid(cache_rsp_valid)
  );

  dram dram (
      .clk (clk),
      .fifo(master_fifo)
  );



  //   dmem dmem (
  //       clk,
  //       cache_req_addr,
  //       cache_req_data,
  //       cache_req_wr,
  //       cache_req_valid,
  //       cache_req_ready,
  //       cache_rsp_data,
  //       cache_rsp_valid
  //   );
endmodule
