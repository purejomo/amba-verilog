# AMBA Verilog Design Project - AXI4-Stream

본 프로젝트는 AXI4-Stream 프로토콜의 하드웨어 구조를 이해하고 직접 Verilog RTL로 설계하여 검증하는 프로젝트입니다.

## 진행 목적
프로토콜 스펙의 철저한 이해와 Verilator를 활용한 C++ Testbench 환경 조성을 목표로 합니다.

## 디렉토리 구조
- `rtl/`: 핵심 Verilog 설계 모듈 (axis_master.v, axis_slave.v 등)
- `tb/`: 검증용 C++ 테스트벤치 (Verilator 사용)
- `include/`: 공용 매크로 및 파라미터 헤더
- `docs/`: 프로토콜 학습 정리 문서
- `sim/`: 시뮬레이션 파형 및 실행 파일 출력 공간
- `scripts/`: 자동화 스크립트

*(현재 Phase 1 진행 중이며 기능 확장에 따라 내용이 지속적으로 추가될 예정입니다.)*
