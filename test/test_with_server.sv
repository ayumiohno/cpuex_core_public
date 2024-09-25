module test_with_server #(
    CLK_PER_HALF_BIT = 2,
    FILENAME = "data/honban128_zero.hex"
) (
    input wire clk,
    input wire resetn,
    input wire start,
    output logic txd,
    output logic [31:0] out,
    output logic pc_end
);

  enum bit [3:0] {
    IDLE,
    PROG_LEN_SEND,
    PROG_LEN_WAIT,
    PROG_SEND,
    PROG_WAIT,
    WAIT_AA,
    DATA_SEND,
    DATA_WAIT,
    DONE
  } status;

  logic tx_start, tx_busy;

  parameter [31:0] bin_length = (2 ** 15 - 1) * 4;
  parameter [14:0] hex_length = 2 ** 15 - 1;

  logic [7:0] send_data;
  logic [1:0] addr_offset;
  logic [14:0] addr, data_addr;
  logic [1:0] data_addr_offset;


  logic [31:0] RAM[2**15-1:0];
  logic [31:0] DATA_RAM[2**15-1:0];

  parameter [31:0] data_bin_length = 325 * 4;
  parameter [14:0] data_hex_length = 325;

  initial begin
    $readmemh(FILENAME, RAM);
    addr = 0;
    data_addr = 0;
    // $readmemh("data/minrt_input.hex", DATA_RAM);
    $readmemh("data/honban_input.hex", DATA_RAM);
  end

  uart_tx #(CLK_PER_HALF_BIT) tx (
      send_data,
      tx_start,
      tx_busy,
      txd,
      clk,
      resetn
  );

  logic [7:0] rdata;
  logic rxd, rdata_ready, ferr;

  uart_rx #(CLK_PER_HALF_BIT) rx (
      rdata,
      rdata_ready,
      ferr,
      rxd,
      clk,
      resetn
  );
  test_top #(CLK_PER_HALF_BIT) test_top (
      clk,
      resetn,
      txd,
      start,
      rxd,
      out,
      pc_end
  );

  always @(posedge clk) begin
    if (~resetn) begin
      status <= IDLE;
      addr   <= 0;
    end else begin
      if (status == IDLE) begin
        if (rdata_ready && rdata == 8'h99) status <= status.next();
      end else if (status == PROG_LEN_SEND) begin
        tx_start <= 1;
        case (addr_offset)
          2'b00: send_data[7:0] <= bin_length[7:0];
          2'b01: send_data[7:0] <= bin_length[15:8];
          2'b10: send_data[7:0] <= bin_length[23:16];
          2'b11: send_data[7:0] <= bin_length[31:24];
        endcase
        if (tx_busy == 1) begin
          status   <= status.next();
          tx_start <= 0;
        end
      end else if (status == PROG_LEN_WAIT) begin
        if (tx_busy == 0) begin
          if (addr_offset == 2'b11) begin
            status <= status.next();
            addr_offset <= 0;
          end else begin
            status <= PROG_LEN_SEND;
            addr_offset <= addr_offset + 1;
          end
        end
      end else if (status == PROG_SEND) begin
        tx_start <= 1;
        case (addr_offset)
          2'b00: send_data[7:0] <= RAM[addr][7:0];
          2'b01: send_data[7:0] <= RAM[addr][15:8];
          2'b10: send_data[7:0] <= RAM[addr][23:16];
          2'b11: send_data[7:0] <= RAM[addr][31:24];
        endcase
        if (tx_busy == 1) begin
          status   <= status.next();
          tx_start <= 0;
        end
      end else if (status == PROG_WAIT) begin
        if (tx_busy == 0) begin
          if (addr + 1 < hex_length || (addr + 1 == hex_length && addr_offset != 2'b11)) begin
            status <= PROG_SEND;
            if (addr_offset == 2'b11) begin
              addr <= addr + 1;
              addr_offset <= 2'b00;
            end else begin
              addr_offset <= addr_offset + 1;
            end
          end else begin
            status <= status.next();
          end
        end
      end else if (status == WAIT_AA) begin
        if (rdata_ready && rdata == 8'haa) begin
          status <= status.next();
        end
      end else if (status == DATA_SEND) begin
        tx_start <= 1;
        case (data_addr_offset)
          2'b00: send_data[7:0] <= DATA_RAM[data_addr][7:0];
          2'b01: send_data[7:0] <= DATA_RAM[data_addr][15:8];
          2'b10: send_data[7:0] <= DATA_RAM[data_addr][23:16];
          2'b11: send_data[7:0] <= DATA_RAM[data_addr][31:24];
        endcase
        if (tx_busy == 1) begin
          status   <= status.next();
          tx_start <= 0;
        end
      end else if (status == DATA_WAIT) begin
        if (tx_busy == 0) begin
          if (data_addr + 1 < data_hex_length || (data_addr + 1 == data_hex_length && data_addr_offset != 2'b11)) begin
            status <= DATA_SEND;
            if (data_addr_offset == 2'b11) begin
              data_addr <= data_addr + 1;
              data_addr_offset <= 2'b00;
            end else begin
              data_addr_offset <= data_addr_offset + 1;
            end
          end else begin
            status <= status.next();
          end
        end
      end else if (status == DONE) begin
        if (rdata_ready) begin
          // $write("%c", rdata);
        end
        if (pc_end) $exit;
      end
    end
  end

endmodule
