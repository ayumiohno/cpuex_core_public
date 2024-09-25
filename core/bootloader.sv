`default_nettype none

/* verilator lint_off MULTITOP */
module bootloader #(
    CLK_PER_HALF_BIT = 5208
) (
    input wire rxd,
    input wire clk,
    input wire reset,
    input wire start,
    input wire init_end,
    output logic [7:0] sdata,
    output logic wr_en,
    output logic [63:0] instr_data,
    output logic [31:0] instr_addr,
    output logic instr_valid,
    output logic [31:0] data_data,
    output logic [31:0] data_addr,
    output logic data_valid,
    output logic [31:0] sp_data,
    output logic sp_valid,
    output logic [31:0] pc_data,
    output logic pc_valid,
    output logic pc_start
);
  enum bit [4:0] {
    IDLE,
    START,
    PROG_LEN,
    DATA_INIT_ADDR,
    DATA_INIT_VALUE,
    SP_INIT,
    PC_INIT,
    INSTR_INIT_EVEN,
    INSTR_INIT_ODD,
    PROG_RECV_END,
    WAIT
  } status;

  logic [31:0] rword;
  logic rword_ready, ferr;
  logic [31:0] length;
  logic [31:0] recv_length;

  initial begin
    status = IDLE;
    length = 0;
    recv_length = 0;
    instr_addr = -4;
    instr_valid = 0;
    data_valid = 0;
    sp_valid = 0;
    pc_valid = 0;
    pc_start = 0;
    sdata = 8'b0;
    wr_en = 0;
  end

  uart_word #(CLK_PER_HALF_BIT) uart_word (
      rword,
      rword_ready,
      ferr,
      rxd,
      clk,
      reset
  );


  always @(posedge clk) begin
    if (~reset) begin
      status <= IDLE;
      recv_length <= 0;
      pc_start <= 0;
    end else begin
      case (status)
        IDLE: begin
          if (start) status <= status.next();
        end
        START: begin
          sdata  <= 8'b10011001;
          wr_en  <= 1;
          status <= status.next();
          // $display("state: %d", status);
        end
        PROG_LEN: begin
          wr_en <= 0;
          if (rword_ready) begin
            // $display("state: %d", status);
            status <= status.next();
            length <= rword;
          end else begin
            data_valid <= 0;
            instr_valid <= 0;
            sp_valid <= 0;
            pc_valid <= 0;
          end
        end
        DATA_INIT_ADDR: begin
          if (rword_ready) begin
            recv_length <= recv_length + 4;
            if (rword == 32'hFFFFFFFF) begin
              // $display("state: %d", status);
              status <= SP_INIT;
            end else begin
              data_addr <= rword;
              status <= status.next();
            end
          end
          data_valid <= 0;
          instr_valid <= 0;
          sp_valid <= 0;
          pc_valid <= 0;
        end
        DATA_INIT_VALUE: begin
          if (rword_ready) begin
            recv_length <= recv_length + 4;
            data_data <= rword;
            data_valid <= 1;
            status <= DATA_INIT_ADDR;
          end
        end
        SP_INIT: begin
          if (rword_ready) begin
            recv_length <= recv_length + 4;
            status <= status.next();
            sp_data <= rword;
            sp_valid <= 1;
          end else begin
            data_valid <= 0;
            instr_valid <= 0;
            sp_valid <= 0;
            pc_valid <= 0;
          end
        end
        PC_INIT: begin
          if (rword_ready) begin
            recv_length <= recv_length + 4;
            if (rword == 32'hFFFFFFFF) begin
              // $display("state: %d", status);
              status <= status.next();
            end else begin
              pc_data  <= rword;
              pc_valid <= 1;
            end
          end else begin
            data_valid <= 0;
            instr_valid <= 0;
            sp_valid <= 0;
            pc_valid <= 0;
          end
        end
        INSTR_INIT_EVEN: begin
          //   $display("length: %d %d", recv_length, length);
          if (rword_ready) begin
            recv_length <= recv_length + 4;
            instr_data  <= {32'b0, rword};
            instr_addr  <= instr_addr + 4;
            if (recv_length + 4 == length) begin
              // $display("state: %d", status);
              status <= PROG_RECV_END;
              instr_valid <= 1;
            end else begin
              status <= INSTR_INIT_ODD;
            end
          end else begin
            data_valid <= 0;
            instr_valid <= 0;
            sp_valid <= 0;
            pc_valid <= 0;
          end
        end
        INSTR_INIT_ODD: begin
          //   $display("length: %d %d", recv_length, length);
          if (rword_ready) begin
            recv_length <= recv_length + 4;
            instr_data  <= {rword, instr_data[31:0]};
            instr_addr  <= instr_addr + 4;
            instr_valid <= 1;
            // instr_addr  <= instr_addr + 4;
            if (recv_length + 4 == length) begin
              // $display("state: %d", status);
              status <= PROG_RECV_END;
            end else begin
              status <= INSTR_INIT_EVEN;
            end
          end else begin
            data_valid <= 0;
            instr_valid <= 0;
            sp_valid <= 0;
            pc_valid <= 0;
          end
        end
        PROG_RECV_END: begin
          if (init_end) begin
            // $display("state: %d", status);
            $display("send: 0xaa at ");
            sdata <= 8'haa;
            wr_en <= 1;
            data_valid <= 0;
            instr_valid <= 0;
            sp_valid <= 0;
            pc_valid <= 0;
            status <= status.next();
          end
        end
        WAIT: begin
          pc_start <= 1;
          wr_en <= 0;
        end
        default: begin
        end
      endcase
    end
  end

endmodule
`default_nettype wire
