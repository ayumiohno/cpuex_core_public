module init_data_controller #(
    parameter CLK_PER_HALF_BIT = 5208
) (
    input  logic        clk,
    reset,
    input  logic        init_data_valid,
    input  logic [31:0] init_data_addr,
    init_data,
    output logic        req_valid,
    output logic [31:0] init_write_data,
    init_write_addr,
    input  logic        req_ready,
    rsp_valid,
    output logic        empty             // init_end
);

  assign req_valid = init_data_valid;
  assign init_write_addr = init_data_addr;
  assign init_write_data = init_data;
  assign empty = 1;

endmodule
