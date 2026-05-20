# 프로젝트 기본 설정
VERILATOR = verilator

# 최신 Verilator 5의 --binary 옵션: C++ Wrapper 자동 생성부터 빌드/링킹까지 한 방에 해결!
VERILATOR_FLAGS = -Wall --trace --timing -Iinclude -Wno-fatal --binary

# 경로 정의
RTL_DIR = rtl
TB_DIR = tb
OBJ_DIR = obj_dir

# 컴파일 대상 파일들
RTL_FILES = $(RTL_DIR)/axi_mm_slave.v $(RTL_DIR)/axi_mm_master.v
TB_FILES = $(TB_DIR)/tb_axi_mm_top.sv

# 최상위 테스트벤치 모듈명
TOP_MODULE = tb_axi_mm_top
SIM_BIN = $(OBJ_DIR)/V$(TOP_MODULE)

all: sim

sim: build
	@echo ""
	@echo "========================================"
	@echo "[STEP 2] Running Verilator Simulation..."
	@echo "========================================"
	./$(SIM_BIN)
	@echo "========================================"
	@echo "[SUCCESS] Simulation finished. Waveforms saved in sim/ directory."
	@echo "Use GTKWave to view: gtkwave sim/dump.vcd"

build: $(RTL_FILES) $(TB_FILES)
	@echo "========================================"
	@echo "[STEP 1] Compiling with Verilator..."
	@echo "========================================"
	$(VERILATOR) $(VERILATOR_FLAGS) --top-module $(TOP_MODULE) $(RTL_FILES) $(TB_FILES)

clean:
	rm -rf $(OBJ_DIR) sim/*.vcd
