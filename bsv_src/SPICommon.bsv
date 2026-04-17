package SPICommon;

interface SPIMasterPinsIfc;
  (* always_ready *)
  method Bool mosi();
  (* always_ready *)
  method Bool sclk();
  (* always_ready *)
  method Bool cs_n();
  (* always_ready, always_enabled *)
  method Action miso(Bool v);
endinterface

interface SPIMasterIfc;
  interface SPIMasterPinsIfc pins;
  method Action startTransfer(Bit#(8) txData);
  method ActionValue#(Bit#(8)) getRxData();
endinterface

interface SPISlavePinsIfc;
  (* always_ready, always_enabled *)
  method Action mosi(Bool v);
  (* always_ready, always_enabled *)
  method Action sclk(Bool v);
  (* always_ready, always_enabled *)
  method Action cs_n(Bool v);
  (* always_ready *)
  method Bool miso();
endinterface

interface SPISlaveIfc;
  interface SPISlavePinsIfc pins;
  method Action setTxData(Bit#(8) data);
  method ActionValue#(Bit#(8)) getRxData();
endinterface

endpackage