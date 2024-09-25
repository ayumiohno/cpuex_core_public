module branch_prediction (
    input logic clk,
    result,
    en,
    input logic [17:0] PCF,
    input logic [17:0] PCE,
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

  logic [9:0] globalHistory;

  initial globalHistory = 0;

  // enum logic [0:0] {
  //   NOT_TAKEN,
  //   TAKEN
  // } state;

  state_t localPredictState, localReadState, localWritebackState;
  state_t globalPredictState, globalReadState, globalWritebackState;
  select_state_t selectPredictState, selectReadState, selectWritebackState;

  logic write_en, result_prev, select_local, select_global;
  logic [17:0] PCE_prev;

  assign select_local  = localReadState >= 2 == result_prev;
  assign select_global = globalReadState >= 2 == result_prev;

  RAM2P #(10, 2, WEAK_NOT_TAKEN) global_pht (
      .clk(clk),
      .addr0(globalHistory),
      .enable0(1),
      .read_data0(globalPredictState),
      .write_enable0(0),
      .write_data0(0),
      .addr1(globalHistory),
      .enable1(en | write_en),
      .read_data1(globalReadState),
      .write_enable1(write_en),
      .write_data1(globalWritebackState)
  );

  RAM2P #(10, 2, WEAK_NOT_TAKEN) local_pht (
      .clk(clk),
      .addr0(PCF[12:3]),
      .enable0(1),
      .read_data0(localPredictState),
      .write_enable0(0),
      .write_data0(0),
      .addr1(write_en ? PCE_prev[12:3] : PCE[12:3]),
      .enable1(en | write_en),
      .read_data1(localReadState),
      .write_enable1(write_en),
      .write_data1(localWritebackState)
  );

  RAM2P #(10, 2, WEAK_USE_GLOBAL) select_pht (
      .clk(clk),
      .addr0(PCF[12:3]),
      .enable0(1),
      .read_data0(selectPredictState),
      .write_enable0(0),
      .write_data0(0),
      .addr1(write_en ? PCE_prev[12:3] : PCE[12:3]),
      .enable1(en | write_en),
      .read_data1(selectReadState),
      .write_enable1(write_en),
      .write_data1(selectWritebackState)
  );

  always_comb begin
    case (globalReadState)
      STRONG_NOT_TAKEN: begin
        globalWritebackState = result_prev ? WEAK_NOT_TAKEN : STRONG_NOT_TAKEN;
      end
      WEAK_NOT_TAKEN: begin
        globalWritebackState = result_prev ? WEAK_TAKEN : STRONG_NOT_TAKEN;
      end
      WEAK_TAKEN: begin
        globalWritebackState = result_prev ? STRONG_TAKEN : WEAK_NOT_TAKEN;
      end
      STRONG_TAKEN: begin
        globalWritebackState = result_prev ? STRONG_TAKEN : WEAK_TAKEN;
      end
    endcase
  end

  always_comb begin
    case (localReadState)
      STRONG_NOT_TAKEN: begin
        localWritebackState = result_prev ? WEAK_NOT_TAKEN : STRONG_NOT_TAKEN;
      end
      WEAK_NOT_TAKEN: begin
        localWritebackState = result_prev ? WEAK_TAKEN : STRONG_NOT_TAKEN;
      end
      WEAK_TAKEN: begin
        localWritebackState = result_prev ? STRONG_TAKEN : WEAK_NOT_TAKEN;
      end
      STRONG_TAKEN: begin
        localWritebackState = result_prev ? STRONG_TAKEN : WEAK_TAKEN;
      end
    endcase
  end

  always_comb begin
    case (selectReadState)
      STRONG_USE_LOCAL: begin
        selectWritebackState = select_local ? STRONG_USE_LOCAL : WEAK_USE_LOCAL;
      end
      WEAK_USE_LOCAL: begin
        selectWritebackState = select_local ? STRONG_USE_LOCAL : WEAK_USE_GLOBAL;
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
  always_ff @(posedge clk) begin
    PCE_prev <= PCE;
    result_prev <= result;
    write_en <= en;
    predict_prev <= predict;
    // if (en) begin
    //   $display("result: %d, state: %d, predict: %d", result, 1, predict_prev);
    // end
    if (write_en) begin
      globalHistory <= {globalHistory[8:0], result_prev};
    end
  end

  assign predict = selectPredictState[1] ? globalPredictState[1] : localPredictState[1];
  // assign predict = predictState == TAKEN;

endmodule
