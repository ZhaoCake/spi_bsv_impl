package SPIMaster;

import SPICommon::*;

// SPI 模式0主机：在 SCLK 上升沿采样，在下降沿更新 MOSI。
module mkSPIMaster(SPIMasterIfc);
  Reg#(Bool) r_cs_n <- mkReg(True);
  Reg#(Bool) r_sclk <- mkReg(False);
  Reg#(Bool) r_mosi <- mkReg(False);
  Wire#(Bool) w_miso <- mkDWire(False);

  Reg#(Bool) active <- mkReg(False);
  Reg#(Bool) startPending <- mkReg(False);
  Reg#(Bool) highPhase <- mkReg(False);
  Reg#(UInt#(4)) bitIdx <- mkReg(0);

  Reg#(Bit#(8)) txShift <- mkReg(0);
  Reg#(Bit#(8)) rxShift <- mkReg(0);
  Reg#(Bool) done <- mkReg(False);

  // 在 CS 拉低后延迟 1 个周期再开始传输，
  // 让从机能在第一次上升沿采样前准备好首位 MISO。
  rule launchTransfer (startPending);
    startPending <= False;
    active <= True;
  endrule

  rule doTransfer (active);
    if (!highPhase) begin
      r_sclk <= True;
      highPhase <= True;
      rxShift <= {rxShift[6:0], pack(w_miso)};
    end
    else begin
      r_sclk <= False;
      highPhase <= False;
      if (bitIdx < 7) begin
        r_mosi <= unpack(txShift[7]);
        txShift <= {txShift[6:0], 1'b0};
        bitIdx <= bitIdx + 1;
      end
      else begin
        active <= False;
        r_cs_n <= True;
        done <= True;
      end
    end
  endrule

  interface SPIMasterPinsIfc pins;
    method Bool mosi() = r_mosi;
    method Bool sclk() = r_sclk;
    method Bool cs_n() = r_cs_n;
    method Action miso(Bool v);
      w_miso <= v;
    endmethod
  endinterface

  method Action startTransfer(Bit#(8) txData) if (!active && !startPending && !done);
    startPending <= True;
    r_cs_n <= False;
    r_sclk <= False;
    highPhase <= False;
    bitIdx <= 0;

    // 第一位在第一次上升沿之前先驱动到 MOSI。
    r_mosi <= unpack(txData[7]);
    txShift <= {txData[6:0], 1'b0};
    rxShift <= 0;
  endmethod

  method ActionValue#(Bit#(8)) getRxData() if (done);
    done <= False;
    return rxShift;
  endmethod
endmodule

endpackage