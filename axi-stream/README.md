# AMBA Verilog Design Project - AXI4-Stream 기초

본 디렉토리는 AXI4-Stream 프로토콜의 가장 뼈대가 되는 **송신단(Master)과 수신단(Slave)의 1:1 직결(Point-to-Point) 통신 구조**를 이해하고 구현해 본 기초 로직 모음입니다.

## 🎯 주요 달성 목표 및 구현 사항 (Phase 1 ~ 3 완료)
1. **프로토콜 핸드셰이크 이해**: `TVALID`, `TREADY`, `TDATA`, `TLAST` 등 AXI-Stream의 핵심 핀 역할을 철저히 분리하여 `axis_master.v`와 `axis_slave.v` 로직 설계 완료.
2. **Back-pressure (배압) 방어 설계**: 수신단(Slave)이 거부(`TREADY=0`)했을 때, 송신단(Master)이 데이터를 잃어버리지 않고 무한 대기(Hold)하며 상위 Application 에도 `user_ready_o=0`을 발생시켜 연쇄 방어하는 메커니즘 검증.
3. **모던 검증 환경 구축 (Verilator 5)**: 불편한 C++ Wrapper 방식 대신, 최긴 Verilator 5의 `--timing` 플래그 및 `--binary` 빌드 방식을 도입하여 **100% SystemVerilog 네이티브 테스트벤치**(`tb_axis_master.sv`)로 End-to-End 시나리오 시뮬레이션 성공.

## 📁 디렉토리 구조 및 역할
- `rtl/`: 핵심 하드웨어 설계 모듈
  - `axis_slave.v`: 데이터 수신 및 TLAST 기반 패킷 수 집계
  - `axis_master.v`: 상위 User 인터페이스로부터 데이터를 받아 AXI 버스로 패키징하여 내보내는 우체부
- `tb/`: SystemVerilog 기반의 최상위 테스트벤치 (`tb_axis_master.sv` 등)
- `include/`: 공용 매크로 및 파라미터 헤더 (`axis_defines.vh`)
- `docs/`: 프로토콜 타이밍 다이어그램 등 학습 정리 문서 (`protocol_notes.md`)
- `sim/`: 시뮬레이션 파형 출력 폴더 (.vcd)
- `obj_dir/`: Verilator 컴파일 중간 산출물 폴더 (📌 **.gitignore 대상**)

## 🚀 시뮬레이션 구동 방법
`Makefile`을 통해 모든 컴파일과 빌드, 시뮬레이션 실행이 한 방에 자동화되어 있습니다.
```bash
make clean && make sim
```
> **결과 확인**: 실행 시 터미널 로그를 통해, 고의로 `TREADY`를 0으로 끌어내려 막힌 구간에서 Master가 어떻게 상위 계층에 역방향 통제(Back-pressure 전파)를 수행하는지 확인하세요. 시뮬레이션이 종료되면 `sim/dump.vcd` 파일을 **GTKWave**로 열어 눈으로 직접 타이밍 파형을 검증하실 수 있습니다.
