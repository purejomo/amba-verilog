# AMBA Verilog Design Project - Common IP

본 디렉토리(`common_ip`)는 AXI4, AXI4-Stream, AHB, APB 등 다양한 버스 프로토콜 인터페이스에 범용적으로 적용할 수 있는 **기초 하드웨어 파이프라인 IP 컴포넌트**를 보관합니다.

## 설계 목적 및 배경
FPGA/ASIC 시스템 설계 시, 단위 모듈 간 논리적/물리적 거리가 먼 상태에서 Point-to-Point 연결을 구성할 경우 긴 라우팅 지연 시간으로 인해 **Setup Timing Violation**이 발생할 확률이 매우 높습니다. 특히 AXI-Stream과 같이 핸드셰이크가 발생하는 구조에서는 `TREADY` 신호의 Combinational Logic 역전파가 Critical Path로 작용합니다.

이를 해결하기 위해 모듈과 모듈 사이에 **Skid Buffer(Register Slice)** 또는 **FIFO**를 삽입하여 Combinational Path를 pipelining하고 Timing Slack을 확보합니다. 
해당 컴포넌트들은 특정 프로토콜에 종속되지 않는 범용 RTL 설계이므로, 본 디렉토리로 독립 설계하여 **Reusability**를 구조적으로 보장합니다.

## 📦 컴포넌트 목록
### 1. Skid Buffer (Register Slice)
- **Architecture**: 1-Stage 또는 2-Stage 깊이를 지원하는 파이프라인 레지스터.
- **Function**: 수신부의 Back-pressure(`TREADY`) 피드백이 송신부로 반환되는 Combinational Path를 완전히 차단(Decoupling)하여 Timing Violation을 방지하고, 전체 시스템의 동작 주파수를 향상시킵니다.

## 📖 핵심 용어
하드웨어 파이프라인 및 데이터 플로우 설계에서 전 세계적으로 통용되는 표준 실무 체계입니다. 

*   **Upstream (상류 / 송신측)**
    *   **의미**: 실제 데이터(`TDATA`, `TVALID`)가 흘러나오는 출처 방향입니다. 
    *   **관계**: 버퍼(Buffer) 모듈의 입장에서, 자신에게 데이터를 건네주는 **Master** 모듈 방향을 의미합니다.
*   **Downstream (하류 / 수신측)**
    *   **의미**: 데이터가 최종적으로 도착해야 할 목적지 방향입니다.
    *   **관계**: 버퍼 모듈의 입장에서, 자신이 데이터를 쏟아부어야 할 **Slave** 모듈 방향을 의미합니다.
*   **Back-pressure**
    *   **의미**: Downstream에 병목이 발생하여 꽉 찼을 때, Upstream를 향해 "더 이상 데이터를 보내지 마라!"고 역방향으로 압력을 가하는 방어 매커니즘을 뜻합니다.
    *   **관계**: AXI 프로토콜에서는 수신 모듈이 송신 모듈 쪽으로 `TREADY = 0` 신호를 쏘아 올려 시스템을 정지시키는 행위 자체가 Back-pressure에 해당합니다.