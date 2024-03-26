module core_top #(
    CLK_PER_HALF_BIT = 520
) (
    input  logic          clk,
    reset,
    rxd,
    start,
    output logic          txd,
    output logic [  31:0] dout,
    output logic          all_end,
    output logic [21-1:0] cache_req_addr,
    output logic [  31:0] cache_req_data,
    output logic          cache_req_wr,     //write = 0, read = 1
    output logic          cache_req_valid,
    input  wire           cache_req_ready,
    input  wire  [  31:0] cache_rsp_data,
    input  wire           cache_rsp_valid
);
  parameter PC_LEN = 17;
  logic pc_end, io_end;
  logic [31:0] WriteData, DataAdr;
  logic MemWrite, Lw;

  logic [PC_LEN-3:0] PCF, PCE;
  logic [31:0] Instr, ReadData, ReadDataIO, ReadDataMEM;

  logic [31:0] instr_data, data_data, sp_data, instr_addr, data_addr, pc_data;
  logic instr_valid, data_valid, sp_valid, pc_start, pc_valid;

  logic stall_in_m, valid_in, stall_mem_m, stall_out_m, stall_w, stall_m, flash_w;
  logic StallD, FlashD, StallM;
  logic wb_valid, wb_valid_mem;

  logic print, scan;
  logic init_end;

  logic [7:0] dout_bootloader;
  logic wr_en_bootloader;

  logic [31:0] BramReadData;  //, BramWriteData;
  logic [10:0] BramAddr, BramAddrWrite;
  logic BramWrite;


  core c (
      clk,
      reset,
      MemWrite,
      BramWrite,
      PCF,
      PCE,
      Instr,
      DataAdr,
      BramAddr,
      BramAddrWrite,
      WriteData,
      //   BramWriteData,
      Lw,
      print,
      scan,
      StallD,
      StallM,
      FlashD,
      ReadDataIO,
      ReadDataMEM,
      BramReadData,
      sp_data,
      sp_valid,
      pc_data[PC_LEN-1:2],
      pc_valid,
      pc_start,  // & ~pc_end,
      stall_w,
      stall_m,
      valid_in,
      wb_valid_mem
      // ,flash_w
  );

  bram_dmem bram_dmem (
      .clk(clk),
      .re (~StallM),
      .we (data_valid | BramWrite),
      .a  (BramAddr),
      .wa (data_valid ? data_addr[12:2] : BramAddrWrite),
      .wd (data_valid ? data_data : WriteData),
      .rd (BramReadData)
  );


  imem imem (
      clk,
      instr_valid,
      ~StallD,  // & pc_start,  // && ~pc_end,
      instr_valid ? instr_addr[PC_LEN-1:2] : PCF,
      instr_data,
      Instr
  );

  dmem_controller dc (
      clk,
      reset,
      pc_start,  // && ~pc_end,
      Lw,
      MemWrite,
      DataAdr,
      WriteData,
      ReadDataMEM,
      stall_w,
      stall_mem_m,
      wb_valid_mem,
      cache_req_addr,
      cache_req_data,
      cache_req_wr,
      cache_req_valid,
      cache_req_ready,
      cache_rsp_data,
      cache_rsp_valid,
      init_end
  );

  bootloader #(CLK_PER_HALF_BIT) bootloader (
      rxd,
      clk,
      reset,
      start,
      init_end,
      dout_bootloader,
      wr_en_bootloader,
      instr_data,
      instr_addr,
      instr_valid,
      data_data,
      data_addr,
      data_valid,
      sp_data,
      sp_valid,
      pc_data,
      pc_valid,
      pc_start
  );

  out_controller #(CLK_PER_HALF_BIT) out_controller (
      clk,
      reset,
      pc_start,  // && ~pc_end,
      print,
      dout_bootloader,
      WriteData[7:0],
      wr_en_bootloader,
      txd,
      stall_out_m,
      io_end
  );

  input_controller #(CLK_PER_HALF_BIT) input_controller (
      clk,
      reset,
      pc_start,
      pc_start,  // && ~pc_end,
      rxd,
      scan,
      ReadDataIO,
      stall_in_m,
      valid_in
  );

  logic flash_w_prev;
  always @(posedge clk) flash_w_prev <= flash_w;

  // assign ReadData = valid_in ? ReadDataIO : ReadDataMEM;
  assign all_end = io_end & pc_end;
  assign stall_m = stall_in_m | stall_out_m | stall_mem_m;

  // assign wb_valid = wb_valid_mem | valid_in;

  initial begin
    pc_end = 0;
  end
  always @(posedge clk) begin
    // if (pc_start & {PCF, 2'b0} == 17'h1BEEF) begin
    //   pc_end <= 1;
    // end
    // if (~reset) begin
    //   pc_end <= 0;
    // end
  end
endmodule
