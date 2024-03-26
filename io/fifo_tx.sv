//`default_nettype none
/* verilator lint_off MULTITOP */
module fifo_tx #(
    CLK_PER_HALF_BIT = 5208
) (
    input  logic [7:0] sdata,
    input  logic       empty,
    output logic       txd,
    readEn,
    input  wire        writeEn,
    input  wire        clk,
    input  wire        rstn,
    output logic       io_end
);

  enum bit [1:0] {
    EMPTY,
    SEND_START,
    SEND_WAIT
  } status;

  logic [7:0] data;

  logic tx_busy, tx_start;
  uart_tx #(CLK_PER_HALF_BIT) tx (
      sdata,
      tx_start,
      tx_busy,
      txd,
      clk,
      rstn
  );

  initial begin
    status = EMPTY;
    io_end = 1'b0;
    readEn = 1'b0;
  end

  assign readEn = (status == EMPTY) && ~empty && ~writeEn;

  always @(posedge clk) begin
    if (~rstn) begin
      status <= EMPTY;
    end else begin
      case (status)
        EMPTY: begin
          if (~empty && ~tx_busy && ~writeEn) begin
            status <= status.next();
            // readEn <= 1'b1;
            // data   <= sdata;
          end
        end
        SEND_START: begin
          if (tx_busy) begin
            status   <= status.next();
            tx_start <= 1'b0;
          end else begin
            tx_start <= 1'b1;
          end
          // readEn <= 1'b0;
        end
        SEND_WAIT: begin
          if (~tx_busy) begin
            status <= EMPTY;
            // $display("sent %h", sdata);
          end
        end
        default: begin
        end
      endcase
    end
  end

  assign io_end = (status == EMPTY) && empty;

endmodule
