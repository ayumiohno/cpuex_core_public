module dram (
    input logic clk,
    master_fifo.fifo fifo
);
  (* ram_style = "block" *)
  logic [127:0] RAM[0:2**24-1];

  // assign rd = RAM[a[11:2]];
  //   modport fifo(input req, req_en, rsp_rdy, clk, output req_rdy, rsp, rsp_en);

  logic [127:0] wd;
  logic [26:0] a;
  logic [31:0] stall_times;
  logic cmd;

  enum logic [1:0] {
    IDLE,
    WAIT
  } state;

  always @(posedge clk) begin
    if (state == IDLE) begin
      if (fifo.req_en) begin
        a <= fifo.req.addr;
        wd <= fifo.req.data;
        cmd <= fifo.req.cmd;
        stall_times <= $urandom_range(1, 10);
        state <= WAIT;
      end
      fifo.rsp_en <= 0;
    end else begin
      if (stall_times > 0) begin
        stall_times <= stall_times - 1;
      end else begin
        if (cmd) begin  // read
          fifo.rsp.data <= RAM[a[26:3]];
          // $display("DRAM Read: a = %h, rd = %h", a[15:0], RAM[a[15:3]]);
          fifo.rsp_en   <= 1;
        end else begin
          RAM[a[26:3]] <= wd;
          // $display("DRAM Write: a = %h, wr = %h", a[15:0], wd);
        end
        state <= IDLE;
      end
    end
  end
  assign fifo.req_rdy = (state == IDLE);
endmodule
