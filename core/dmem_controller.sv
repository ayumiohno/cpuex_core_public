module dmem_controller #(
    CLK_PER_HALF_BIT = 5208,
    Addresswidth = 21
) (
    input  logic                    clk,
    reset,
    pc_en,
    Lw,
    MemWrite,
    input  logic [            31:0] DataAdr,
    input  logic [            31:0] WriteData,
    output logic [            31:0] read_data,
    output logic                    stall_w,
    stall_m,
    wb_valid,
    output logic [Addresswidth-1:0] cache_req_addr,
    output logic [            31:0] cache_req_data,
    output logic                    cache_req_wr,     //write = 0, read = 1
    output logic                    cache_req_valid,
    input  wire                     cache_req_ready,
    input  wire  [            31:0] cache_rsp_data,
    input  wire                     cache_rsp_valid,
    output logic                    init_end
);
  assign init_end = 1;

  logic cmd, req_valid, req_ready, rsp_valid, lift_stall;
  assign wb_valid = cache_rsp_valid;

  logic [31:0] addr, write_data;

  logic write, read;

  assign cache_req_addr = DataAdr[Addresswidth+1:2];
  assign cache_req_data = WriteData;
  assign cache_req_wr = cmd;
  assign cache_req_valid = req_valid;
  assign req_ready = cache_req_ready;
  assign rsp_valid = cache_rsp_valid;
  assign read_data = cache_rsp_data;

  logic [1:0] read_data_cnt;
  logic read_data_prev;
  assign read_data_prev = read_data_cnt != 0;

  initial begin
    stall_m = 0;
    stall_w = 0;
    req_valid = 0;
    cmd = 1;
    read_data_cnt = 0;
  end

  logic req_done;

  always @(posedge clk) begin
    if (read_valid & rsp_valid) begin
    end else if (read_valid) begin
      read_data_cnt <= read_data_cnt + 1;
    end else if (rsp_valid) begin
      read_data_cnt <= read_data_cnt - 1;
    end

    if (~stall_w) req_done <= 0;
    else if (req_ready) req_done <= 1;
  end
  assign write = MemWrite;
  assign read  = Lw;

  logic write_stall, read_stall_m, read_stall_w;
  assign write_stall = write & ~req_ready;

  assign read_stall_m = read & ~req_ready;
  assign read_stall_w = read_data_prev & ~rsp_valid;
  assign stall_m = write_stall | read_stall_m;
  assign stall_w = read_stall_w;

  assign cmd = ~write;
  logic write_valid, read_valid;
  assign write_valid = write & req_ready & ~req_done;
  assign read_valid  = read & req_ready & ~req_done;
  assign req_valid   = write_valid | read_valid;

endmodule
