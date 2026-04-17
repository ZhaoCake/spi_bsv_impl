TOP_MODULE = Top
BSV_SRC = bsv_src
BUILD = build
VDIR = $(BUILD)/verilog
VSRC = verilator_src

.PHONY: all bluesim verilog verilator iverilog clean help

all: bluesim

bluesim:
	@mkdir -p $(BUILD)
	bsc -sim -u -bdir $(BUILD) -info-dir $(BUILD) -simdir $(BUILD) -vdir $(BUILD) -p +:$(BSV_SRC) -g mk$(TOP_MODULE) $(BSV_SRC)/$(TOP_MODULE).bsv
	bsc -sim -e mk$(TOP_MODULE) -bdir $(BUILD) -info-dir $(BUILD) -simdir $(BUILD) -o $(BUILD)/out
	@echo "✅ Run Bluesim and generate waveform: wave.vcd"
	./$(BUILD)/out -V wave.vcd

verilog:
	@mkdir -p $(VDIR)
	bsc -verilog -vdir $(VDIR) -bdir $(BUILD) -info-dir $(BUILD) \
	    -p +:$(BSV_SRC) -g mk$(TOP_MODULE) $(BSV_SRC)/$(TOP_MODULE).bsv
	@echo "✅ Verilog: $(VDIR)/mk$(TOP_MODULE).v"

verilator: verilog
	@verilator -Wall -Wno-UNUSED -Wno-fatal --no-timing --trace --cc --exe --build \
	    $(VDIR)/mk$(TOP_MODULE).v $(VSRC)/sim_main.cpp \
	    -o sim
	@echo "✅ Run: ./obj_dir/sim"
	@./obj_dir/sim

iverilog: verilog
	@iverilog -o $(BUILD)/sim.vvp $(VDIR)/mk$(TOP_MODULE).v $(VSRC)/tb_iverilog.v
	@vvp $(BUILD)/sim.vvp
	@echo "✅ Waveform: wave.vcd"

clean:
	@rm -rf $(BUILD) *.bo *.ba *.vcd obj_dir

help:
	@echo "Bluespec SystemVerilog Makefile"
	@echo ""
	@echo "Targets:"
	@echo "  make bluesim   - Compile and run Bluesim simulation (generates wave.vcd)"
	@echo "  make verilog   - Compile BSV to Verilog"
	@echo "  make verilator - Build and run Verilator simulation"
	@echo "  make iverilog  - Build and run Icarus Verilog simulation"
	@echo "  make clean     - Remove build artifacts"
