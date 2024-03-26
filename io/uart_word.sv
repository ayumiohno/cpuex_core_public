`default_nettype none
module uart_word #(
    CLK_PER_HALF_BIT = 5208
) (
    output logic [31:0] rword,
    output logic        rword_ready,
    output logic        ferr,
    input  wire         rxd,
    input  wire         clk,
    input  wire         reset
);

  enum bit [1:0] {BYTE0, BYTE1, BYTE2, BYTE3}       status;

  logic                                       [7:0] rdata;
  logic                                             rdata_ready;

  uart_rx #(CLK_PER_HALF_BIT) rx (
      rdata,
      rdata_ready,
      ferr,
      rxd,
      clk,
      reset
  );

  initial begin
    status = BYTE0;
    rword_ready = 1'b0;
  end

  always @(posedge clk) begin
    if (~reset) begin
      status <= BYTE0;
      rword_ready <= 1'b0;
    end else begin
      if (rdata_ready) begin
        rword <= {rdata, rword[31:8]};
        if (status == BYTE3) begin
          status <= BYTE0;
          rword_ready <= 1'b1;
        end else begin
          status <= status.next();
          rword_ready <= 1'b0;
        end
      end else begin
        rword_ready <= 1'b0;
      end
    end
  end
endmodule
`default_nettype wire
