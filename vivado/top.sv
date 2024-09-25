module top #(
    parameter CLK_PER_HALF_BIT = 16
) (
    // DDR2
    output wire [12:0] ddr2_addr,
    output wire [2:0] ddr2_ba,
    output wire ddr2_cas_n,
    output wire [0:0] ddr2_ck_n,
    output wire [0:0] ddr2_ck_p,
    output wire [0:0] ddr2_cke,
    output wire ddr2_ras_n,
    output wire ddr2_we_n,
    inout wire [15:0] ddr2_dq,
    inout wire [1:0] ddr2_dqs_n,
    inout wire [1:0] ddr2_dqs_p,
    output wire [0:0] ddr2_cs_n,
    output wire [1:0] ddr2_dm,
    output wire [0:0] ddr2_odt,
    // others
    input wire clk,
    input wire uart_txd_in,
    output wire uart_rxd_out,
    input wire btnc,
    output reg [6:0] SEG,
    output reg [7:0] AN,
    output wire DP
);
  // clock
  logic cpu_clk;
  logic mig_clk;
  clk_wiz_0 clk_gen (
      .clk_in1 (clk),
      .clk_out1(mig_clk),
      .clk_out2(cpu_clk)
  );

  // interfaces
  master_fifo master_fifo ();
  slave_fifo slave_fifo ();

  logic wr;
  logic [20:0] req_addr;
  logic [31:0] req_data;
  logic req_valid;
  logic req_ready;
  logic rsp_valid;
  logic [31:0] rsp_data;

  logic all_end;
  logic [31:0] dout;
//     assign ledout = {wr, req_valid, req_ready, rsp_valid, req_addr[15:0], dout[11:0]};

//assign led0 = req_valid;
//assign led1 = req_ready;
//assign led2 = rsp_valid;


  core_top #(CLK_PER_HALF_BIT) core_top (
      .clk(cpu_clk),
      .reset(1'b1),
      .rxd(uart_txd_in),
      .start(btnc),
      .txd(uart_rxd_out),
      .dout(dout),
      .all_end(all_end),
      .cache_req_addr(req_addr),
      .cache_req_data(req_data),
      .cache_req_wr(wr),
      .cache_req_valid(req_valid),
      .cache_req_ready(req_ready),
      .cache_rsp_data(rsp_data),
      .cache_rsp_valid(rsp_valid)
  );
  assign SEG = 0;
  assign AN  = 0;
  assign DP  = 0;

//  two_digit_ssd(
//   	   dout,
//       cpu_clk,
//       SEG,
//       AN,
//       DP
//  );


  // master
  cache_controller cache_controller (
      .fifo(master_fifo),
      .clk(cpu_clk),
      .wr(wr),
      .addr(req_addr),
      .data(req_data),
      .req_valid(req_valid),
      .req_ready(req_ready),
      .rsp_data(rsp_data),
      .rsp_valid(rsp_valid)
  );

  // fifo
  dram_buf dram_buf (
      .master(master_fifo),
      .slave (slave_fifo)
  );

  // slave
  dram_controller dram_controller (
      // DDR2
      .*,
      // others
      .sys_clk(mig_clk),
      .fifo(slave_fifo)
  );

endmodule

