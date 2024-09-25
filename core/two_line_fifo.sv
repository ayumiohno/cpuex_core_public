module fifo_reg_manager #(
    parameter DataWidth = 92,
    parameter MyPtr = 0
) (
    input logic clk,
    input logic [1:0] rdPtr,
    wrPtr1,
    wrPtr2,
    input logic [DataWidth-1:0] writeData1,
    writeData2,
    input logic writeEn1,
    writeEn2,
    readEn,
    StallE1,
    StallE2,
    input logic [5:0] RdE1,
    RdE2,
    output logic [DataWidth-1:0] mem
);
  logic [5:0] Rd;
  logic MemWrite, scan;
  assign Rd = mem[91:86];
  assign MemWrite = mem[3];
  assign scan = mem[1];
  logic [17:0] PC;
  assign PC = mem[21:4];
  always_ff @(posedge clk) begin
    if (writeEn1 & wrPtr1 == MyPtr) begin
      mem <= writeData1;
    end else if (writeEn2 & wrPtr2 == MyPtr) begin
      mem <= writeData2;
    end else if ((readEn & rdPtr == MyPtr)) begin
      mem <= '0;
    end else if ((RdE1 == Rd & ~StallE1) | (RdE2 == Rd & ~StallE2)) begin
      if (scan) begin
        mem <= {6'b0, mem[85:0]};
      end else if (~MemWrite) begin
        mem <= '0;
        // if (Rd != 0)
        //   if (Rd[5]) $display("f%d: skip at %h", Rd[4:0], PC);
        //   else $display("x%d: skip at %h", Rd[4:0], PC);
      end
    end
  end
endmodule

module two_line_fifo #(
    parameter DataWidth = 92
) (
    input  logic                 clk,
    rstN,
    writeEn1,
    input  logic [DataWidth-1:0] writeData1,
    input  logic                 writeEn2,
    input  logic [DataWidth-1:0] writeData2,
    input  logic                 readEn,
    flash_m,
    StallE1,
    StallE2,
    input  logic [          5:0] Rs1D1,
    Rs2D1,
    Rs1D2,
    Rs2D2,
    RdE1,
    RdE2,
    RdD1,
    input  logic                 LwE1,
    LwE2,
    LwD1,
    output logic [DataWidth-1:0] readData,
    output logic                 full1,
    full2,
    lwStallE1,
    lwStallE2
);

  parameter PtrWidth = 2;

  logic empty;
  logic [DataWidth-1:0] mem1, mem2, mem3, mem4;

  logic [PtrWidth:0] wrPtr1, wrPtr2, wrPtr1Plus2, wrPtr2Plus2;
  logic [PtrWidth:0] rdPtr, rdPtrPlus1;

  initial begin
    wrPtr1 = '0;
    wrPtr2 = 3'b1;
    rdPtr  = '0;
    empty  = 1;
    full1  = '0;
    full2  = '0;
  end
  assign wrPtr1Plus2 = wrPtr1 + 2;
  assign wrPtr2Plus2 = wrPtr2 + 2;
  assign rdPtrPlus1  = rdPtr + 1;

  logic [DataWidth-1:0] read_mem;
  assign readData = empty ? '0 : (rdPtr[1] ? rdPtr[0] ? mem4 : mem3 : rdPtr[0] ? mem2 : mem1);

  always_ff @(posedge clk) begin
    if (!rstN) begin
      wrPtr1 <= '0;
      wrPtr2 <= 3'b1;
      rdPtr  <= '0;
    end else begin
      empty <= (wrPtr1Next[PtrWidth] == rdPtrNext[PtrWidth]) && (wrPtr1Next[PtrWidth-1:0] == rdPtrNext[PtrWidth-1:0]);
      full1 <= (wrPtr1Next[PtrWidth] != rdPtrNext[PtrWidth]) && (wrPtr1Next[PtrWidth-1:0] == rdPtrNext[PtrWidth-1:0]);
      full2 <= (wrPtr2Next[PtrWidth] != rdPtrNext[PtrWidth]) && (wrPtr2Next[PtrWidth-1:0] == rdPtrNext[PtrWidth-1:0]);
      wrPtr1 <= wrPtr1Next;
      wrPtr2 <= wrPtr2Next;
      rdPtr <= rdPtrNext;
    end
  end

  logic [PtrWidth:0] rdPtrNext, wrPtr1Next, wrPtr2Next;
  always_comb begin
    rdPtrNext = rdPtr;
    if ((readEn | readData == 0) & ~empty) rdPtrNext = rdPtrPlus1;
    wrPtr1Next = wrPtr1;
    wrPtr2Next = wrPtr2;
    if (writeEn1 & writeEn2 & ~full1 & ~full2) begin
      wrPtr1Next = wrPtr1Plus2;
      wrPtr2Next = wrPtr2Plus2;
    end else if (writeEn1 & ~full1) begin
      wrPtr1Next = wrPtr2;
      wrPtr2Next = wrPtr1Plus2;
    end else if (writeEn2 & ~full1) begin
      wrPtr1Next = wrPtr2;
      wrPtr2Next = wrPtr1Plus2;
    end
  end

  logic buf_writeEn1, buf_writeEn2, buf_readEn;
  logic [DataWidth-1:0] buf_writeData1, buf_writeData2;
  assign buf_readEn = readEn & ~empty;
  assign buf_writeEn1 = (writeEn1 | writeEn2) & ~full1;
  assign buf_writeEn2 = writeEn1 & writeEn2 & ~full1 & ~full2;
  assign buf_writeData1 = writeEn1 ? writeData1 : writeData2;
  assign buf_writeData2 = writeData2;

  logic [5:0] Rd1, Rd2, Rd3, Rd4;
  assign Rd1 = mem1[91:86];
  assign Rd2 = mem2[91:86];
  assign Rd3 = mem3[91:86];
  assign Rd4 = mem4[91:86];
  assign lwStallE1 = (Rs1D1 != 0 & (Rs1D1 == Rd1 | Rs1D1 == Rd2 | Rs1D1 == Rd3 | Rs1D1 == Rd4 | (Rs1D1 == RdE1 & LwE1) | (Rs1D1 == RdE2 & LwE2)))
            | (Rs2D1 != 0 & (Rs2D1 == Rd1 | Rs2D1 == Rd2 | Rs2D1 == Rd3 | Rs2D1 == Rd4 | (Rs2D1 == RdE1 & LwE1) | (Rs2D1 == RdE2 & LwE2)));
  assign lwStallE2 = (Rs1D2 != 0 & (Rs1D2 == Rd1 | Rs1D2 == Rd2 | Rs1D2 == Rd3 | Rs1D2 == Rd4 | (Rs1D2 == RdE1 & LwE1) | (Rs1D2 == RdE2 & LwE2) | (Rs1D2 == RdD1 & LwD1)))
            | (Rs2D2 != 0 & (Rs2D2 == Rd1 | Rs2D2 == Rd2 | Rs2D2 == Rd3 | Rs2D2 == Rd4 | (Rs2D2 == RdE1 & LwE1) | (Rs2D2 == RdE2 & LwE2) | (Rs2D2 == RdD1 & LwD1)));

  fifo_reg_manager #(
      .DataWidth(DataWidth),
      .MyPtr(0)
  ) fifo_reg_manager1 (
      .clk(clk),
      .rdPtr(rdPtr[1:0]),
      .wrPtr1(wrPtr1[1:0]),
      .wrPtr2(wrPtr2[1:0]),
      .writeData1(buf_writeData1),
      .writeData2(buf_writeData2),
      .writeEn1(buf_writeEn1),
      .writeEn2(buf_writeEn2),
      .readEn(buf_readEn),
      .StallE1(lwStallE1),
      .StallE2(lwStallE2),
      .RdE1(RdE1),
      .RdE2(RdE2),
      .mem(mem1)
  );
  fifo_reg_manager #(
      .DataWidth(DataWidth),
      .MyPtr(1)
  ) fifo_reg_manager2 (
      .clk(clk),
      .rdPtr(rdPtr[1:0]),
      .wrPtr1(wrPtr1[1:0]),
      .wrPtr2(wrPtr2[1:0]),
      .writeData1(buf_writeData1),
      .writeData2(buf_writeData2),
      .writeEn1(buf_writeEn1),
      .writeEn2(buf_writeEn2),
      .readEn(buf_readEn),
      .StallE1(lwStallE1),
      .StallE2(lwStallE2),
      .RdE1(RdE1),
      .RdE2(RdE2),
      .mem(mem2)
  );
  fifo_reg_manager #(
      .DataWidth(DataWidth),
      .MyPtr(2)
  ) fifo_reg_manager3 (
      .clk(clk),
      .rdPtr(rdPtr[1:0]),
      .wrPtr1(wrPtr1[1:0]),
      .wrPtr2(wrPtr2[1:0]),
      .writeData1(buf_writeData1),
      .writeData2(buf_writeData2),
      .writeEn1(buf_writeEn1),
      .writeEn2(buf_writeEn2),
      .readEn(buf_readEn),
      .StallE1(lwStallE1),
      .StallE2(lwStallE2),
      .RdE1(RdE1),
      .RdE2(RdE2),
      .mem(mem3)
  );
  fifo_reg_manager #(
      .DataWidth(DataWidth),
      .MyPtr(3)
  ) fifo_reg_manager4 (
      .clk(clk),
      .rdPtr(rdPtr[1:0]),
      .wrPtr1(wrPtr1[1:0]),
      .wrPtr2(wrPtr2[1:0]),
      .writeData1(buf_writeData1),
      .writeData2(buf_writeData2),
      .writeEn1(buf_writeEn1),
      .writeEn2(buf_writeEn2),
      .readEn(buf_readEn),
      .StallE1(lwStallE1),
      .StallE2(lwStallE2),
      .RdE1(RdE1),
      .RdE2(RdE2),
      .mem(mem4)
  );

endmodule
