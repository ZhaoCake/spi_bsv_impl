package SPISlave;

import SPICommon::*;

// SPI 模式0从机：在上升沿采样 MOSI，在下降沿阶段准备 MISO。
module mkSPISlave(SPISlaveIfc);
  Wire#(Bool) w_mosi <- mkDWire(False);
  Wire#(Bool) w_sclk <- mkDWire(False);
  Wire#(Bool) w_cs_n <- mkDWire(True);
  Reg#(Bool) r_miso <- mkReg(False);

  Reg#(Bit#(8)) preloadTx <- mkReg(0);
  Reg#(Bit#(8)) txShift <- mkReg(0);
  Reg#(Bit#(8)) rxShift <- mkReg(0);

  Reg#(Bool) sclkPrev <- mkReg(False);
  Reg#(Bool) csPrev <- mkReg(True);
  Reg#(UInt#(4)) riseCount <- mkReg(0);
  Reg#(Bool) hasData <- mkReg(False);

  rule sampleEdges;
    let csFall = csPrev && !w_cs_n;
    let sclkRise = !sclkPrev && w_sclk;

    csPrev <= w_cs_n;
    sclkPrev <= w_sclk;

    if (csFall) begin
      // CS 拉低后立刻装载首个输出位。
      txShift <= preloadTx;
      r_miso <= unpack(preloadTx[7]);
      rxShift <= 0;
      riseCount <= 0;
      hasData <= False;
    end
    else if (!w_cs_n) begin
      if (sclkRise) begin
        rxShift <= {rxShift[6:0], pack(w_mosi)};
        if (riseCount == 7) begin
          hasData <= True;
        end
        else begin
          txShift <= {txShift[6:0], 1'b0};
          r_miso <= unpack(txShift[6]);
        end
        riseCount <= riseCount + 1;
      end
    end
  endrule

  interface SPISlavePinsIfc pins;
    method Action mosi(Bool v);
      w_mosi <= v;
    endmethod

    method Action sclk(Bool v);
      w_sclk <= v;
    endmethod

    method Action cs_n(Bool v);
      w_cs_n <= v;
    endmethod

    method Bool miso() = r_miso;
  endinterface

  method Action setTxData(Bit#(8) data);
    preloadTx <= data;
  endmethod

  method ActionValue#(Bit#(8)) getRxData() if (hasData);
    hasData <= False;
    return rxShift;
  endmethod
endmodule

endpackage