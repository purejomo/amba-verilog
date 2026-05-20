/**
 * Module: skid_buffer (Register Slice)
 *
 * [목적 및 필요성]
 * 모듈 간 물리적 라우팅 거리가 길어질 때 발생하는 Setup Timing Violation을 방지하기 위함입니다.
 * 특히 AXI-Stream 버스에서 수신부의 TREADY 피드백 신호가 송신부로 이어지는 긴 조합 회로
 * Combinational Path를 타이밍적으로 Decoupling시켜, 전체 시스템의 동작 주파수를 향상시킵니다.
 *
 * [구현 방식]
 * Master 모듈과 Slave 모듈의 중간에 삽입됩니다.
 * 내부적으로 2-Stage 레지스터를 두어, Slave가 수신을 거부하는 Back-pressure 상황이 발생하더라도, 
 * 앞단(Master)에서 들어오는 1클럭 분량의 초과 유효 데이터를 Skid 레지스터에 캐싱함으로써 데이터 유실 없이 파이프라인 정지 타이밍을 확보합니다.
 */

`timescale 1ns / 1ps

module skid_buffer #(
    parameter DATA_WIDTH = 32
)(
    input  wire                   ACLK,
    input  wire                   ARESETn,

    // Upstream (Master Interface)
    input  wire                   s_axis_tvalid,
    output wire                   s_axis_tready,
    input  wire [DATA_WIDTH-1:0]  s_axis_tdata,
    input  wire                   s_axis_tlast,

    // Downstream (Slave Interface)
    output wire                   m_axis_tvalid,
    input  wire                   m_axis_tready,
    output reg  [DATA_WIDTH-1:0]  m_axis_tdata,
    output reg                    m_axis_tlast
);

    // 내부 레지스터 선언 (2-Stage Pipeline)
    reg                   main_valid;
    
    reg                   skid_valid;
    reg  [DATA_WIDTH-1:0] skid_data;
    reg                   skid_last;

    // 핸드셰이크 제어 신호
    wire insert = s_axis_tvalid && s_axis_tready;
    wire remove = m_axis_tvalid && m_axis_tready;

    // TREADY Combinational Path Decoupling
    // s_axis_tready는 m_axis_tready에 논리적으로 직결되지 않으며, 내부 레지스터(skid_valid) 상태에만 의존함.
    assign s_axis_tready = !skid_valid;
    
    assign m_axis_tvalid = main_valid;

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            main_valid   <= 1'b0;
            skid_valid   <= 1'b0;
            m_axis_tdata <= {DATA_WIDTH{1'b0}};
            m_axis_tlast <= 1'b0;
            skid_data    <= {DATA_WIDTH{1'b0}};
            skid_last    <= 1'b0;
        end else begin
            // 상태 1: 데이터 수신만 발생 (Downstream이 막힌 상태)
            if (insert && !remove) begin
                if (!main_valid) begin
                    main_valid   <= 1'b1;
                    m_axis_tdata <= s_axis_tdata;
                    m_axis_tlast <= s_axis_tlast;
                end else begin
                    skid_valid   <= 1'b1;
                    skid_data    <= s_axis_tdata;
                    skid_last    <= s_axis_tlast;
                end
            end
            
            // 상태 2: 데이터 출력만 발생 (Downstream 병목 해소됨)
            else if (!insert && remove) begin
                if (skid_valid) begin
                    m_axis_tdata <= skid_data;
                    m_axis_tlast <= skid_last;
                    skid_valid   <= 1'b0;
                end else begin
                    main_valid   <= 1'b0;
                end
            end
            
            // 상태 3: 수신 및 출력 동시 발생 (Bypass)
            else if (insert && remove) begin
                m_axis_tdata <= s_axis_tdata;
                m_axis_tlast <= s_axis_tlast;
            end
        end
    end

endmodule
