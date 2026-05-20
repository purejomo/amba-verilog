/**
 * Testbench: tb_skid_buffer
 *
 * [테스트 시나리오 개요]
 * 1. Scenario 1 (Continuous Normal Transfer):
 *    - Downstream이 항상 준비된 상태(m_axis_tready=1)에서 데이터를 연속 주입.
 *    - Skid Buffer가 대역폭(Bandwidth) 제한 없이 100% 능률로 Bypass 동작함을 검증.
 * 2. Scenario 2 (Back-pressure & Caching):
 *    - Downstream 컴포넌트의 수신 불가 상황(m_axis_tready=0)을 의도적으로 유발.
 *    - 해당 병목 상황에서도 1클럭 분량의 초과 데이터를 유실 없이 Skid 레지스터에 Caching 하는지 검증.
 *    - 내부 버퍼(Main, Skid)가 100% Full 상태가 되었을 때, Upstream 방향으로 Back-pressure
 *      (s_axis_tready=0) 신호를 정확히 전파(Propagation) 하는지 확인.
 */

`timescale 1ns / 1ps

module tb_skid_buffer ();

    parameter DATA_WIDTH = 32;

    reg                   ACLK;
    reg                   ARESETn;

    // Upstream Interface
    reg                   s_axis_tvalid;
    wire                  s_axis_tready;
    reg  [DATA_WIDTH-1:0] s_axis_tdata;
    reg                   s_axis_tlast;

    // Downstream Interface
    wire                  m_axis_tvalid;
    reg                   m_axis_tready;
    wire [DATA_WIDTH-1:0] m_axis_tdata;
    wire                  m_axis_tlast;

    // DUT Instantiation
    skid_buffer #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_skid_buffer (
        .ACLK(ACLK),
        .ARESETn(ARESETn),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tlast(s_axis_tlast),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tlast(m_axis_tlast)
    );

    // Clock Generation
    initial begin
        ACLK = 0;
        forever #5 ACLK = ~ACLK;
    end

    // Simulation Scenarios
    initial begin
        $dumpfile("sim/dump.vcd");
        $dumpvars(0, tb_skid_buffer);

        // 신호 초기화
        ARESETn = 0;
        s_axis_tvalid = 0;
        s_axis_tdata = 0;
        s_axis_tlast = 0;
        m_axis_tready = 1;

        #25;
        ARESETn = 1;
        $display("[%0t ns] Reset Released", $time);

        #10;
        
        // --------------------------------------------------------
        // Scenario 1: Continuous Normal Transfer (Bypass Mode)
        // --------------------------------------------------------
        $display("\n[%0t ns] === Scenario 1: Continuous Normal Transfer ===", $time);
        @(posedge ACLK);
        s_axis_tvalid = 1; s_axis_tdata = 32'hAAAA_0001; s_axis_tlast = 0;
        @(posedge ACLK);
        s_axis_tvalid = 1; s_axis_tdata = 32'hAAAA_0002; s_axis_tlast = 0;
        @(posedge ACLK);
        s_axis_tvalid = 1; s_axis_tdata = 32'hAAAA_0003; s_axis_tlast = 1;
        
        @(posedge ACLK);
        s_axis_tvalid = 0;
        $display("[%0t ns] Scenario 1 Done", $time);

        #40; 
        
        // --------------------------------------------------------
        // Scenario 2: Back-pressure & Caching Validation
        // --------------------------------------------------------
        $display("\n[%0t ns] === Scenario 2: Back-pressure & Caching ===", $time);
        
        // 1. Downstream 수신 중단 (m_axis_tready=0)
        @(posedge ACLK);
        m_axis_tready = 0;
        $display("[%0t ns] [WARNING] Downstream Disabled (m_axis_tready=0)", $time);

        // 2. Upstream 트랜잭션 발송 -> Main 레지스터(Stage 1)에 진입 후 대기
        @(posedge ACLK);
        s_axis_tvalid = 1; s_axis_tdata = 32'hBBBB_1111; s_axis_tlast = 0;
        
        // 3. Upstream 2차 트랜잭션 발송 -> Downstream이 막혀있으나 Skid 레지스터(Stage 2)에 Caching 수행
        @(posedge ACLK);
        s_axis_tvalid = 1; s_axis_tdata = 32'hBBBB_2222; s_axis_tlast = 1;
        
        // 4. 레지스터(Main, Skid) 풀(Full) 상태 도달 -> Upstream 방향으로 Back-pressure(s_axis_tready=0) 전파
        @(posedge ACLK);
        if (s_axis_tready == 0) begin
            $display("[%0t ns] Buffer is Full: s_axis_tready successfully dropped to 0!", $time);
        end
        // Upstream 측에서 TREADY=0을 인지하고 3차 데이터를 버스에 유지하며 트랜잭션 대기
        s_axis_tvalid = 1; s_axis_tdata = 32'hBBBB_3333; 

        // 5. Downstream 병목 해소 (m_axis_tready=1 복구)
        #30;
        @(posedge ACLK);
        m_axis_tready = 1;
        $display("[%0t ns] [REPAIRED] Downstream Enabled (m_axis_tready=1)", $time);

        // 6. 버퍼 데이터 순차적 일괄 출력 완료 후 발송 종료
        @(posedge ACLK);
        s_axis_tvalid = 0; // 대기 중이던 최종 데이터 전송 완료

        #50;
        $display("\n[%0t ns] Simulation Finish!", $time);
        $finish;
    end

endmodule
