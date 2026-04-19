/*
 * Module: axis_slave
 * Protocol: AMBA 4 AXI4-Stream
 * 
 * 코드 설명:
 *   AXI4-Stream 인터페이스 수신단(Slave) 모듈 기초 설계.
 *   
 *   - 데이터 전송은 클럭 상승 엣지에서 TVALID와 TREADY가 동시에 High(1)일 때만 성립합니다.
 *   - s_axis_tready 신호는 외부에서 제어 가능한 enable_rx_i 입력과 직결되어 있어, 사용자 로직이나 테스트벤치에서 Back-pressure 상황을 임의로 발생시킬 수 있습니다.
 *   - 정상적으로 데이터가 수신(handshake_valid)될 때마다 data_count_o 값이 1씩 증가합니다.
 *   - 유효한 데이터 전송 중 s_axis_tlast 신호가 수신되면 한 패킷의 통신이 
 *     완료되었음을 알리기 위해 done_o 플래그가 1 사이클 동안 High 상태로 출력됩니다.
 */

`timescale 1ns / 1ps
`include "axis_defines.vh"

module axis_slave (
    input  wire                     ACLK,
    input  wire                     ARESETn,

    input  wire                     enable_rx_i,
    output reg                      done_o,
    output reg  [31:0]              data_count_o,

    input  wire                     s_axis_tvalid,
    output wire                     s_axis_tready,
    input  wire [`TDATA_WIDTH-1:0]  s_axis_tdata,
    input  wire [`TKEEP_WIDTH-1:0]  s_axis_tkeep,
    input  wire                     s_axis_tlast,
    input  wire [`TUSER_WIDTH-1:0]  s_axis_tuser,
    input  wire [`TID_WIDTH-1:0]    s_axis_tid,
    input  wire [`TDEST_WIDTH-1:0]  s_axis_tdest
);

    wire handshake_valid = (s_axis_tvalid && s_axis_tready);

    assign s_axis_tready = enable_rx_i;

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            data_count_o <= 32'd0;
            done_o       <= 1'b0;
        end 
        else begin
            done_o <= 1'b0;

            if (handshake_valid) begin
                data_count_o <= data_count_o + 1;

                if (s_axis_tlast == 1'b1) begin
                    done_o <= 1'b1;
                end
            end
        end
    end

endmodule
