module RAM2P #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 2,
    parameter INIT_VALUE = 0
) (
    input clk,
    input logic [ADDR_WIDTH-1:0] addr0,
    input logic enable0,
    output logic [DATA_WIDTH-1:0] read_data0,
    input logic [ADDR_WIDTH-1:0] addr1,
    input logic write_enable1,
    input logic [DATA_WIDTH-1:0] write_data1
);
  (*ram_style = "BLOCK"*) reg [DATA_WIDTH-1:0] mem[0:2**ADDR_WIDTH-1];

  initial begin
    integer i;
    for (i = 0; i < 2 ** ADDR_WIDTH; i = i + 1) begin
      mem[i] = INIT_VALUE;
    end
  end

  always @(posedge clk) begin
    if (enable0) begin
      read_data0 <= mem[addr0];
    end
  end

  always @(posedge clk) begin
    if (write_enable1) begin
      mem[addr1] <= write_data1;
    end
  end
endmodule
