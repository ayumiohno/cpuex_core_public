module fifo_buf #(
    parameter  DataWidth = 32,
    parameter  Depth     = 8,
    localparam PtrWidth  = $clog2(Depth)
) (
    input logic clk,
    we,
    re,  //read enable
    input logic [PtrWidth-1:0] a,
    input logic [DataWidth-1:0] wd,
    output logic [DataWidth-1:0] rd
);
  (* ram_style = "block" *)
  logic [DataWidth-1:0] RAM[0:Depth-1];

  // initial $readmemh("data/fib5.data", RAM);

  always_ff @(posedge clk) begin
    if (re) rd <= RAM[a];
    else if (we) RAM[a] <= wd;
  end
endmodule

module fifo #(
    parameter  DataWidth = 32,
    parameter  Depth     = 8,
    parameter  token     = "",
    localparam PtrWidth  = $clog2(Depth)
) (
    input  logic                 clk,
    input  logic                 rstN,
    input  logic                 writeEn,
    input  logic [DataWidth-1:0] writeData,
    input  logic                 readEn,
    output logic [DataWidth-1:0] readData,
    output logic                 full,
    output logic                 empty
);

  (* ram_style = "block" *)
  logic [DataWidth-1:0] mem[0:Depth-1];

  logic [PtrWidth:0] wrPtr, wrPtrNext;
  logic [PtrWidth:0] rdPtr, rdPtrNext;

  logic buf_rd_en, buf_wr_en;


  initial begin
    wrPtr = '0;
    rdPtr = '0;
    empty = '1;
    full  = '0;
  end
  assign wrPtrNext = wrPtr + 1;
  assign rdPtrNext = rdPtr + 1;
  always_ff @(posedge clk or negedge rstN) begin
    if (!rstN) begin
      wrPtr <= '0;
      rdPtr <= '0;
    end else begin
      if (buf_wr_en) begin
        // $display("%s write %h", token, writeData);
        wrPtr <= wrPtrNext;
        empty <= (wrPtrNext[PtrWidth] == rdPtr[PtrWidth]) && (wrPtrNext[PtrWidth-1:0] == rdPtr[PtrWidth-1:0]);
        full  <= (wrPtrNext[PtrWidth] != rdPtr[PtrWidth]) && (wrPtrNext[PtrWidth-1:0] == rdPtr[PtrWidth-1:0]);
        // mem[wrPtr[PtrWidth-1:0]] <= writeData;
      end else if (buf_rd_en) begin
        // $display("%s read %h", token, mem[rdPtr[PtrWidth-1:0]]);
        rdPtr <= rdPtrNext;
        empty <= (wrPtr[PtrWidth] == rdPtrNext[PtrWidth]) && (wrPtr[PtrWidth-1:0] == rdPtrNext[PtrWidth-1:0]);
        full  <= (wrPtr[PtrWidth] != rdPtrNext[PtrWidth]) && (wrPtr[PtrWidth-1:0] == rdPtrNext[PtrWidth-1:0]);
        // readData <= mem[rdPtr[PtrWidth-1:0]];
      end
    end
  end

  assign buf_wr_en = writeEn;
  assign buf_rd_en = readEn;

  // assign empty = (wrPtr[PtrWidth] == rdPtr[PtrWidth]) && (wrPtr[PtrWidth-1:0] == rdPtr[PtrWidth-1:0]);
  // assign full  = (wrPtr[PtrWidth] != rdPtr[PtrWidth]) && (wrPtr[PtrWidth-1:0] == rdPtr[PtrWidth-1:0]);

  fifo_buf #(
      .DataWidth(DataWidth),
      .Depth(Depth)
  ) fifo_buf (
      .clk(clk),
      .we (buf_wr_en),
      .re (buf_rd_en),
      .a  (buf_rd_en ? rdPtr[PtrWidth-1:0] : wrPtr[PtrWidth-1:0]),
      .wd (writeData),
      .rd (readData)
  );

  // assign readData = mem[rdPtr[PtrWidth-1:0]];


endmodule
