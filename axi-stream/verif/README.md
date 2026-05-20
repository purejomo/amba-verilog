# AXI-Stream UVM-like Verification Environment

본 문서는 `amba-verilog/axi-stream/verif` 디렉토리에 구축된 UVM-like SystemVerilog 검증 환경에 대한 상세 설명서입니다. 
Verilator 5 컴파일러를 활용한 C++ 시뮬레이션 환경에서도 SystemVerilog 객체지향(OOP) 기반의 검증론이 정상적으로 동작하도록 구성되었습니다.

## 1. 검증 환경 아키텍처

```mermaid
graph TD
    subgraph Testbench [Testbench Top (tb_axis_top.sv)]
        subgraph Environment [axis_env]
            GEN[Generator<br>(gen_transactions)]
            DRV[Driver<br>(axis_driver)]
            MON[Monitor<br>(axis_monitor)]
            SCB[Scoreboard<br>(axis_scoreboard)]
            
            MBX_GEN_DRV[("gen2drv<br>(Mailbox)")]
            MBX_MON_SCB_IN[("mon2scb_in<br>(Mailbox)")]
            MBX_MON_SCB_OUT[("mon2scb_out<br>(Mailbox)")]
            
            GEN -- axis_transaction --> MBX_GEN_DRV
            MBX_GEN_DRV --> DRV
            
            MON -- Expected Tx --> MBX_MON_SCB_IN
            MON -- Actual Tx --> MBX_MON_SCB_OUT
            
            MBX_MON_SCB_IN --> SCB
            MBX_MON_SCB_OUT --> SCB
        end
        
        IFC((axis_if))
        
        DRV == Drives signals ==> IFC
        IFC == Observes signals ==> MON
        
        subgraph DUT [Design Under Test]
            MASTER[axis_master]
            SLAVE[axis_slave]
            MASTER -- AXI-Stream Bus --> SLAVE
        end
        
        IFC <--> MASTER
        IFC <--> SLAVE
    end
```

## 2. 주요 컴포넌트 설명

### 2.1. `tb_axis_top.sv` (Testbench Top)
- **기능:** 
  - 클럭(`clk`) 및 리셋(`rst_n`) 생성
  - DUT (`axis_master`, `axis_slave`) 인스턴스화 및 `axis_if` 인터페이스 연결
  - AXI-Stream Slave의 Back-pressure 환경 조성을 위해 `enable_rx` 신호를 랜덤하게 On/Off 제어
  - `axis_env` 클래스 객체를 생성하고 전체 시뮬레이션의 시작(`run()`)을 트리거합니다.

### 2.2. `axis_if.sv` (Interface)
- **Verilator Workaround:** 
  - Verilator 컴파일러는 DUT 출력으로 선언된 순수 `wire`를 Testbench 클래스의 `ref logic` 인자로 직접 전달하는 것을 금지합니다(`%Error-PROCASSWIRE` 에러 발생).
  - 이를 해결하기 위해 인터페이스 내에 `obs_tvalid`, `obs_tready`, `obs_user_ready` 와 같은 `logic` 관찰용 변수를 추가하고, `tb_axis_top.sv`에서 DUT의 출력 wire를 이 `logic` 변수에 `assign` 하는 방식으로 우회(Workaround) 설계가 적용되었습니다.

### 2.3. `axis_transaction.sv` (Transaction Object)
- **특징:** AXI-Stream의 핵심인 `data`(32bit)와 `last`(패킷 종료 플래그)를 멤버로 가지며, 객체 간 데이터 일치 여부를 판별하는 `compare` 메서드를 포함합니다.

### 2.4. `axis_env.sv` (Environment)
- **동작 흐름:**
  1. `gen_transactions()`: 지정된 횟수(`num_transactions`)만큼 `axis_transaction` 객체를 랜덤 생성하여 `gen2drv` 메일박스로 푸시합니다.
  2. `run()` 태스크에서 `fork ~ join_any`를 통해 Driver, Monitor, Scoreboard를 병렬 스레드로 동시에 실행시킵니다.
  3. 시뮬레이션 종료 시 Scoreboard의 검증 성공/실패 횟수를 취합하여 최종 결과를 출력합니다.

### 2.5. `axis_driver.sv` (Driver)
- **동작 원리:**
  - `gen2drv` 메일박스에서 트랜잭션을 꺼내 `vif.user_valid`, `vif.user_data` 등에 값을 할당합니다.
  - Master DUT가 데이터를 받아들일 준비가 되었는지 `vif.obs_user_ready` 신호를 폴링하며 대기합니다.
  - **Race Condition 방지:** Verilator 스케줄링 특성상, DUT의 Non-blocking assignment(`<=`)가 반영된 안정적인 신호를 읽기 위해 `@(posedge vif.clk);` 이후에 `#1;` 딜레이를 주어 Active/NBA Region 간의 경합을 완벽히 회피합니다.

### 2.6. `axis_monitor.sv` (Monitor)
- **내부 태스크 분리:**
  - `run_in()`: DUT(Master)의 사용자 인터페이스 단에서 `user_valid`와 `obs_user_ready`가 동시에 High가 되어 데이터가 주입된 순간을 포착(`mon2scb_in`으로 전달).
  - `run_out()`: AXI-Stream 버스 단에서 `obs_tvalid`와 `obs_tready`가 동시에 High가 되어 데이터가 Slave로 정상 전송된 순간을 포착(`mon2scb_out`으로 전달).
- **Race Condition 방지:** Driver와 마찬가지로 클럭 엣지에서 데이터가 캡처되는 순간의 안정성을 보장하기 위해 `#1;` 딜레이 후 신호를 샘플링합니다.

### 2.7. `axis_scoreboard.sv` (Scoreboard)
- **동작 원리:**
  - `mon2scb_in`에서 꺼낸 데이터(Expected Data)와 `mon2scb_out`에서 꺼낸 데이터(Actual Data)를 1:1로 비교합니다.
  - Master 내부를 통과하면서 순서가 뒤바뀌거나 누락, 혹은 중복 전송되는 데이터가 없는지 실시간으로 검사하며, 불일치 발생 시 에러 로그를 출력하고 카운트를 증가시킵니다.


## 3. 핵심 디버깅 사항 (Verilator Timing)

Event-driven 시뮬레이터(VCS, ModelSim 등)에서 제공하는 `clocking block`을 대체하기 위해 코드 레벨의 타이밍 제어가 적용되었습니다. 
DUT 내의 모든 상태 업데이트는 `@(posedge clk)`의 **Non-Blocking Assignment (`<=`)** 로 이루어집니다. 따라서 Testbench(Driver, Monitor)는 클럭이 상승하는 그 찰나의 순간에 아직 갱신되지 않은 '과거의 값'과 즉시 갱신된 '현재의 값' 사이에서 혼동을 겪을 수 있습니다.

본 환경에서는 `tb_axis_top.sv`에서 Back-pressure 변수인 `enable_rx` 값을 토글할 때 `negedge clk`에서 변경하거나, 클래스 메서드 내에서 `@(posedge clk); #1;`을 삽입함으로써 **"클럭 엣지 이후의 충분히 안정화된 상태"** 에서만 신호를 읽고 쓰도록 규격화하여, AXI-Stream Handshake 과정의 Race Condition을 원천적으로 차단했습니다.
