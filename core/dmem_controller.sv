module dmem_controller #(
    CLK_PER_HALF_BIT = 5208,
    Addresswidth = 25
) (
    input  logic          clk,
    reset,
    pc_en,
    Lw,
    print,
    scan,
    MemWrite,
    input  logic [  31:0] DataAdr,
    input  logic [  31:0] WriteData,
    output logic [  31:0] read_data,
    output logic          stall_w,
    stall_m,
    wb_valid,
    req_ready,
    input  logic          init_data_valid,
    input  logic [  31:0] init_data_addr,
    init_data,
    output logic [25-1:0] cache_req_addr,
    output logic [  31:0] cache_req_data,
    output logic          cache_req_wr,     //write = 0, read = 1
    output logic          cache_req_valid,
    input  wire           cache_req_ready,
    input  wire  [  31:0] cache_rsp_data,
    input  wire           cache_rsp_valid,
    output logic          init_end
);
  logic cmd, req_valid, rsp_valid, lift_stall;
  logic init_req_valid;
  logic [31:0] init_write_data, init_write_addr;
  assign wb_valid = cache_rsp_valid;

  logic [31:0] addr, write_data;

  logic write, read;

  assign cache_req_addr = init_req_valid ? init_data_addr[Addresswidth+1:2] : DataAdr[Addresswidth+1:2];
  assign cache_req_data = init_req_valid ? init_data : WriteData;
  assign cache_req_wr = init_req_valid ? 0 : cmd;
  assign cache_req_valid = req_valid | init_req_valid;
  assign req_ready = cache_req_ready;
  assign rsp_valid = cache_rsp_valid;
  assign read_data = cache_rsp_data;


  init_data_controller #(CLK_PER_HALF_BIT) init_data_controller (
      clk,
      reset,
      init_data_valid,
      init_data_addr,
      init_data,
      init_req_valid,
      init_write_data,
      init_write_addr,
      req_ready,
      rsp_valid,
      init_end
  );

  logic read_data_prev;

  initial begin
    stall_m = 0;
    stall_w = 0;
    req_valid = 0;
    cmd = 1;
  end

  always @(posedge clk)
    if (req_ready) read_data_prev <= read;
    else if (rsp_valid) read_data_prev <= 0;

  assign write = ~print & MemWrite;
  assign read  = Lw & ~scan;

  logic read_stall_w;

  assign read_stall_w = read_data_prev & ~rsp_valid;
  assign stall_m = ~req_ready & (read | write);
  assign stall_w = read_stall_w;

  assign cmd = ~write;
  logic write_valid, read_valid;
  assign write_valid = write & req_ready;
  assign read_valid  = read & req_ready;
  assign req_valid   = write_valid | read_valid;

endmodule
