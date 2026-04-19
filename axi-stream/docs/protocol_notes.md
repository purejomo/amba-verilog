# AXI4-Stream Protocol Notes

## 1. Handshake Mechanism (TVALID & TREADY)
- 데이터 전송은 클럭의 Rising Edge에서 **TVALID와 TREADY가 모두 High(1)**일 때 발생한다.
- **절대적 룰**: 한 번 TVALID가 1이 되어 데이터 전송을 시도했다면, TREADY가 1이 되어 전송이 완료될 때까지 TVALID를 0으로 내리거나 TDATA를 변경해서는 안 된다.
- **Back-pressure**: Slave가 데이터를 받을 준비가 되지 않았다면 TREADY를 0으로 내려 데이터 유입을 막을 수 있다.

## 2. Key Signals
| Signal | Direction | Description |
|:---|:---|:---|
| ACLK | Input | 클럭 신호 |
| ARESETn | Input | Active-Low 리셋 신호 |
| TVALID | Master->Slave | Master 측의 유효 데이터 출력 플래그 |
| TREADY | Slave->Master | Slave 측의 데이터 수신 가능 플래그 |
| TDATA | Master->Slave | 전송되는 페이로드 (기본 32-bit 등) |
| TLAST | Master->Slave | 통신 패킷의 경계 (마지막 데이터)를 나타냄 |
| TKEEP | Master->Slave | Byte qualifier: 해당 바이트가 의미 있는 데이터(1)인지, 무시할 Null 바이트(0)인지 표기 |
| TSTRB | Master->Slave | Byte qualifier: Data 바이트(1) vs Position 바이트(0). (스트림에서는 주로 생략되거나 TKEEP와 유사한 역할로 대체되기도 함) |
| TUSER | Master->Slave | User-defined 라우팅 사이드밴드 신호 |
| TID | Master->Slave | 스트림 식별자 |
| TDEST | Master->Slave | 라우팅 목적지 주소 |

## 3. TKEEP vs TSTRB 주의사항
TKEEP는 실제 유효한 데이터가 쓰여 있는 바이트를 표시하기 위해 가장 많이 사용된다. 통신 패킷의 경우 마지막 전송 시 TDATA 전체 비트가 유효하지 않을 수 있으므로 (예: 32bit 버스에서 1바이트만 전송), 에러를 방지하기 위해 TKEEP 처리가 중요하다.

## 4. Common Pitfalls (초보자 흔한 실수)
1. TREADY가 0인데 TVALID 값을 0으로 내려버리는 프로토콜 위반.
2. `(TVALID == 1 && TREADY == 1)` 조건 교집합을 확인하지 않고 데이터를 막 캡처하거나 넘기는 오류.
3. 패킷 기반 시스템에서 패킷 경계를 구획하는 `TLAST` 신호를 누락하여 수신단 데드락을 유발.
