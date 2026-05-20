VERILATOR = verilator
VERILATOR_FLAGS = -Wall --trace --timing -Wno-fatal --binary

RTL_DIR = rtl
TB_DIR = tb
OBJ_DIR = obj_dir

RTL_FILES = $(RTL_DIR)/skid_buffer.v
TB_FILES = $(TB_DIR)/tb_skid_buffer.sv

TOP_MODULE = tb_skid_buffer
SIM_BIN = $(OBJ_DIR)/V$(TOP_MODULE)

all: sim

sim: build
	@echo ""
	@echo "========================================"
	@echo "[STEP 2] Running Verilator Simulation..."
	@echo "========================================"
	./$(SIM_BIN)
	@echo "========================================"
	@echo "[SUCCESS] Waveform saved at sim/dump.vcd"

build: $(RTL_FILES) $(TB_FILES)
	@mkdir -p sim
	@echo "========================================"
	@echo "[STEP 1] Compiling with Verilator..."
	@echo "========================================"
	$(VERILATOR) $(VERILATOR_FLAGS) --top-module $(TOP_MODULE) $(RTL_FILES) $(TB_FILES)

clean:
	rm -rf $(OBJ_DIR) sim
