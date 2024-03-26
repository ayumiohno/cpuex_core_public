`default_nettype none

/* verilator lint_off MULTITOP */
module uart_rx #(
    CLK_PER_HALF_BIT = 5208
) (
    output logic [7:0] rdata,
    output logic       rdata_ready,
    output logic       ferr,
    input  wire        rxd,
    input  wire        clk,
    input  wire        reset
);

  localparam E_CLK_BIT = CLK_PER_HALF_BIT * 2 - 1;
  localparam E_CLK_HALF_BIT = CLK_PER_HALF_BIT - 1;

  enum bit [3:0] {
    IDLE,
    START_BIT,
    BIT0,
    BIT1,
    BIT2,
    BIT3,
    BIT4,
    BIT5,
    BIT6,
    BIT7,
    STOP_BIT
  } status;


  logic [31:0] counter;

  initial begin
    status = IDLE;
    counter = 32'b0;
    rdata = 8'b0;
    rdata_ready = 1'b0;
  end

  // counter
  always @(posedge clk) begin
    if (~reset) begin
      counter <= 32'b0;
    end else begin
      if (status == IDLE) begin
        counter <= 0;
      end else if (status == START_BIT) begin
        if (counter == E_CLK_HALF_BIT) begin
          counter <= 0;
        end else begin
          counter <= counter + 1;
        end
      end else begin
        if (counter == E_CLK_BIT) begin
          counter <= 0;
        end else begin
          counter <= counter + 1;
        end
      end
    end
  end

  always @(posedge clk) begin
    // $display("rx %h, counter: %h", status, counter);
    if (~reset) begin
      status <= IDLE;
      rdata <= 8'b0;
      rdata_ready <= 1'b0;
    end else begin
      if (status == IDLE) begin
        rdata_ready <= 1'b0;
        if (rxd == 1'b0) begin
          status <= START_BIT;
        end
      end else if (status == START_BIT) begin
        if (counter == E_CLK_HALF_BIT) begin
          status <= status.next();
        end
      end else if (counter == E_CLK_BIT) begin
        if (status == STOP_BIT) begin
          status <= IDLE;
          rdata_ready <= 1'b1;
          ferr <= ~rxd;
        end else begin
          //   $display("status %h, rscv %b", status, rxd);
          rdata  <= (rdata >> 1) | {rxd, 7'b0};
          status <= status.next();
        end
      end
    end
  end
endmodule  // uart_rx
`default_nettype wire
