`default_nettype none

/* verilator lint_off MULTITOP */
module uart_tx #(
    CLK_PER_HALF_BIT = 5208
) (
    input  wire  [7:0] sdata,
    input  wire        tx_start,
    output logic       tx_busy,
    output logic       txd,
    input  wire        clk,
    input  wire        rstn
);

  localparam E_CLK_BIT = CLK_PER_HALF_BIT * 2 - 1;

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


  logic [7:0] txbuf;

  logic [31:0] counter;

  initial begin
    status = IDLE;
    counter = 32'b0;
    txd = 1;
  end

  // counter
  always @(posedge clk) begin
    if (~rstn) begin
      counter <= 32'b0;
    end else begin
      if (status == IDLE) begin
        counter <= 0;
      end else begin
        if (counter == E_CLK_BIT) begin
          counter <= 0;
        end else begin
          counter <= counter + 1;
        end
      end
    end
  end

  assign txd = 
      status == IDLE        ? 1'b1 :
      status == START_BIT   ? 1'b0 :
      status == STOP_BIT    ? 1'b1 : txbuf[0];

  always @(posedge clk) begin
    // $display("tx %h, counter: %h", status, counter);
    if (~rstn) begin
      txbuf   <= 8'b0;
      status  <= IDLE;
      tx_busy <= 1'b0;
    end else begin
      if (status == IDLE) begin
        if (tx_start) begin
          txbuf   <= sdata;
          status  <= START_BIT;
          tx_busy <= 1'b1;
        end
        // if (status == IDLE) begin
      end else if (counter == E_CLK_BIT) begin
        if (status == STOP_BIT) begin
          status  <= IDLE;
          tx_busy <= 1'b0;
          txbuf   <= 8'b0;
        end else if (status == START_BIT) begin
          status <= status.next();
        end else begin
          // $display("status %h, send %b", status, txbuf[0]);
          txbuf  <= txbuf >> 1;
          status <= status.next();
        end
      end
    end
  end
endmodule  // uart_tx
`default_nettype wire
