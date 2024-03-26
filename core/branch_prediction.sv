module branch_prediction (
    input logic clk,
    result,
    en,
    StallD,
    StallE,
    input logic [14:0] PCF,
    input logic [14:0] PCE,
    output logic predict
);

  typedef enum logic [1:0] {
    STRONG_NOT_TAKEN,
    WEAK_NOT_TAKEN,
    WEAK_TAKEN,
    STRONG_TAKEN
  } state_t;

  typedef enum logic [1:0] {
    STRONG_USE_LOCAL,
    WEAK_USE_LOCAL,
    WEAK_USE_GLOBAL,
    STRONG_USE_GLOBAL
  } select_state_t;

  logic [9:0] globalHistory, globalHistoryNext;

  initial globalHistory = 0;
  initial globalHistoryNext = 0;

  state_t localPredictState, localReadState, localWritebackState;
  state_t globalPredictState, globalReadState, globalWritebackState;
  select_state_t selectPredictState, selectReadState, selectWritebackState;

  logic select_local, select_global;

  assign select_local  = localReadState[1] == result;
  assign select_global = globalReadState[1] == result;

  RAM2P #(10, 2, WEAK_NOT_TAKEN) global_pht (
      .clk(clk),
      .addr0(globalHistory),
      .enable0(~StallD),
      .read_data0(globalPredictState),
      .addr1(globalHistory),
      .write_enable1(en),
      .write_data1(globalWritebackState)
  );

  RAM2P #(8, 2, WEAK_NOT_TAKEN) local_pht (
      .clk(clk),
      .addr0(PCF[7:0]),
      .enable0(~StallD),
      .read_data0(localPredictState),
      .addr1(PCE[7:0]),
      .write_enable1(en),
      .write_data1(localWritebackState)
  );

  RAM2P #(8, 2, WEAK_USE_GLOBAL) select_pht (
      .clk(clk),
      .addr0(PCF[7:0]),
      .enable0(~StallD),
      .read_data0(selectPredictState),
      .addr1(PCE[7:0]),
      .write_enable1(en),
      .write_data1(selectWritebackState)
  );

  always_comb begin
    case (globalReadState)
      STRONG_NOT_TAKEN: begin
        globalWritebackState = result ? WEAK_NOT_TAKEN : STRONG_NOT_TAKEN;
      end
      WEAK_NOT_TAKEN: begin
        globalWritebackState = result ? WEAK_TAKEN : STRONG_NOT_TAKEN;
      end
      WEAK_TAKEN: begin
        globalWritebackState = result ? STRONG_TAKEN : WEAK_NOT_TAKEN;
      end
      STRONG_TAKEN: begin
        globalWritebackState = result ? STRONG_TAKEN : WEAK_TAKEN;
      end
    endcase
  end

  always_comb begin
    case (localReadState)
      STRONG_NOT_TAKEN: begin
        localWritebackState = result ? WEAK_NOT_TAKEN : STRONG_NOT_TAKEN;
      end
      WEAK_NOT_TAKEN: begin
        localWritebackState = result ? WEAK_TAKEN : STRONG_NOT_TAKEN;
      end
      WEAK_TAKEN: begin
        localWritebackState = result ? STRONG_TAKEN : WEAK_NOT_TAKEN;
      end
      STRONG_TAKEN: begin
        localWritebackState = result ? STRONG_TAKEN : WEAK_TAKEN;
      end
    endcase
  end

  always_comb begin
    case (selectReadState)
      STRONG_USE_LOCAL: begin
        selectWritebackState = select_local ? STRONG_USE_LOCAL : WEAK_USE_LOCAL;
      end
      WEAK_USE_LOCAL: begin
        selectWritebackState = select_local ? WEAK_USE_LOCAL : select_global ? WEAK_USE_GLOBAL : WEAK_USE_LOCAL;
      end
      WEAK_USE_GLOBAL: begin
        selectWritebackState = ~select_local & select_global ? STRONG_USE_GLOBAL : WEAK_USE_LOCAL;
      end
      STRONG_USE_GLOBAL: begin
        selectWritebackState = ~select_local & select_global ? STRONG_USE_GLOBAL : WEAK_USE_GLOBAL;
      end
    endcase
  end

  logic predict_prev;
  assign globalHistoryNext = {globalHistory[8:0], result};

  always_ff @(posedge clk) begin
    if (~StallE) begin
      predict_prev <= predict;
      localReadState <= localPredictState;
      globalReadState <= globalPredictState;
      selectReadState <= selectPredictState;
    end
    if (en) begin
      // $display("result: %d, predict: %d, at: %h", result, predict_prev, PCE);
      globalHistory <= globalHistoryNext;
      // $display("Update local: %h, global: %h, select: %h", localWritebackState,
      //          globalWritebackState, selectWritebackState);
    end
  end

  assign predict = selectPredictState[1] ? globalPredictState[1] : localPredictState[1];
  // assign predict = predictState == TAKEN;

endmodule
