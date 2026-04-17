package Top;

import SPICommon::*;
import SPIMaster::*;
import SPISlave::*;

(* synthesize *)
module mkTop (Empty);
  SPIMasterIfc master <- mkSPIMaster;
  SPISlaveIfc slave <- mkSPISlave;

  // 主从之间的 SPI 物理连线。
  rule connect_spi_mosi;
    slave.pins.mosi(master.pins.mosi);
  endrule

  rule connect_spi_sclk;
    slave.pins.sclk(master.pins.sclk);
  endrule

  rule connect_spi_cs;
    slave.pins.cs_n(master.pins.cs_n);
  endrule

  rule connect_spi_miso;
    master.pins.miso(slave.pins.miso);
  endrule

  Reg#(UInt#(8)) state <- mkReg(0);
  Reg#(Bit#(8)) masterRx <- mkReg(0);

  // 将从机预装载与主机启动拆成不同周期，避免调度冲突。
  rule tb_load_slave_data (state == 0);
    slave.setTxData(8'h3C);
    $display("[%0d] TB: Slave preload TX=0x3C", $time);
    state <= 1;
  endrule

  rule tb_start_transfer (state == 1);
    master.startTransfer(8'hA5);
    $display("[%0d] TB: Start SPI transfer, Master TX=0xA5", $time);
    state <= 2;
  endrule

  rule tb_get_master_rx (state == 2);
    let mRx <- master.getRxData();
    $display("[%0d] TB: Master RX=0x%0h (expect 0x3c)", $time, mRx);
    masterRx <= mRx;
    state <= 3;
  endrule

  rule tb_get_slave_rx (state == 3);
    let sRx <- slave.getRxData();
    $display("[%0d] TB: Slave  RX=0x%0h (expect 0xa5)", $time, sRx);
    if ((masterRx == 8'h3C) && (sRx == 8'hA5)) begin
      $display("[%0d] TB: PASS", $time);
    end
    else begin
      $display("[%0d] TB: FAIL", $time);
    end
    $finish(0);
  endrule
endmodule

endpackage
