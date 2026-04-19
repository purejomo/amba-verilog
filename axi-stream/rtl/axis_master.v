/*
 * Module: axis_master
 * Protocol: AMBA 4 AXI4-Stream
 * 
 * Description:
 *   AXI4-Stream 인터페이스 송신단(Master) 모듈 기초 설계.
 *   
 *   - 시스템(사용자 로직)에서 전송할 데이터를 입력받아 AXI-Stream 신호로 변환하여 출력합니다.
 *   - Slave로부터의 Back-pressure(TREADY=0) 상황 발생 시, 데이터를 잃어버리거나
 *     순서가 뒤바뀌지 않도록 안전하게 대기(Hold)하는 메커니즘을 시연합니다.
 *   - 패킷의 끝은 상위 로직에서 직관적으로 파악할 수 있도록 user_last_i 핀에 1을 밀어넣어
 *     TLAST 신호로 변환되게끔 설계되었습니다.
 */
`timescale 1ns / 1ps
`include "axis_defines.vh"

module axis_master (
    input  wire                     ACLK,
    input  wire                     ARESETn,

    // User Logic에서 데이터를 받아오는 Interface
    input  wire                     user_valid_i,
    output wire                     user_ready_o,
    input  wire [31:0]              user_data_i,
    input  wire                     user_last_i,

    // AXI4-Stream Master Interface
    output reg                      m_axis_tvalid,
    input  wire                     m_axis_tready,
    output reg  [`TDATA_WIDTH-1:0]  m_axis_tdata,
    output reg  [`TKEEP_WIDTH-1:0]  m_axis_tkeep,
    output reg                      m_axis_tlast,
    output reg  [`TUSER_WIDTH-1:0]  m_axis_tuser,
    output reg  [`TID_WIDTH-1:0]    m_axis_tid,
    output reg  [`TDEST_WIDTH-1:0]  m_axis_tdest
);

    // Sideband Signals Tie-off (단일 P2P 통신용 고정)
    // - TKEEP: 모든 바이트 데이터(32bit)가 유효함(1111)으로 고정
    // - TUSER: 사용자 정의 부가 데이터 미사용(0)
    // - TID/TDEST: 1:1 직결 통신이므로 다중 라우팅 식별자 불필요(0)
    assign m_axis_tkeep = {`TKEEP_WIDTH{1'b1}};
    assign m_axis_tuser = {`TUSER_WIDTH{1'b0}};
    assign m_axis_tid   = {`TID_WIDTH{1'b0}};
    assign m_axis_tdest = {`TDEST_WIDTH{1'b0}};

    assign user_ready_o = m_axis_tready || !m_axis_tvalid;

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            m_axis_tvalid <= 1'b0;
            m_axis_tdata  <= 0;
            m_axis_tlast  <= 1'b0;
        end 
        else begin
            if (m_axis_tready || !m_axis_tvalid) begin
                m_axis_tvalid <= user_valid_i;
                if (user_valid_i) begin
                    m_axis_tdata <= user_data_i;
                    m_axis_tlast <= user_last_i;
                end
            end
        end
    end
    
endmodule