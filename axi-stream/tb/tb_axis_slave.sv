`timescale 1ns / 1ps

module tb_axis_slave ();

    // 클럭 & 리셋
    reg ACLK;
    reg ARESETn;

    // 사용자 제어 신호
    reg enable_rx_i;
    wire done_o;
    wire [31:0] data_count_o;

    // AXI-Stream 신호
    reg s_axis_tvalid;
    wire s_axis_tready;
    reg [31:0] s_axis_tdata;
    reg [3:0] s_axis_tkeep;
    reg s_axis_tlast;
    reg s_axis_tuser;
    reg [7:0] s_axis_tid;
    reg [7:0] s_axis_tdest;

    // DUT(Design Under Test) 인스턴스화
    axis_slave u_axis_slave (
        .ACLK(ACLK),
        .ARESETn(ARESETn),
        .enable_rx_i(enable_rx_i),
        .done_o(done_o),
        .data_count_o(data_count_o),
        
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tkeep(s_axis_tkeep),
        .s_axis_tlast(s_axis_tlast),
        .s_axis_tuser(s_axis_tuser),
        .s_axis_tid(s_axis_tid),
        .s_axis_tdest(s_axis_tdest)
    );

    // 10ns 주기 클럭 생성
    initial begin
        ACLK = 0;
        forever #5 ACLK = ~ACLK;
    end

    // 메인 테스트 시퀀스 뼈대
    initial begin
        // 파형 생성 로그용 (Verilator에서 C++ Wrapper가 대신 하므로 생략 가능)
        $dumpfile("sim/dump.vcd");
        $dumpvars(0, tb_axis_slave);

        // 신호 초기화
        ARESETn = 0;
        enable_rx_i = 1;
        s_axis_tvalid = 0;
        s_axis_tdata = 0;
        s_axis_tkeep = 4'b1111;
        s_axis_tlast = 0;
        s_axis_tuser = 0;
        s_axis_tid = 0;
        s_axis_tdest = 0;

        // 리셋 해제
        #25;
        ARESETn = 1;
        $display("[%0t ns] Reset Released!", $time);

        // ----------------------------------------------------
        // [시나리오 1] 기본 정상 수신 테스트 (TREADY 항상 High 상태)
        // ----------------------------------------------------
        $display("\n[%0t ns] === Scenario 1: Normal Transfer ===", $time);
        @(posedge ACLK); 
        s_axis_tvalid = 1;           // 나 데이터 줄게!
        s_axis_tdata  = 32'hDEADBEEF;
        @(posedge ACLK);             // 다음 상승 엣지에서 전송(Sample) 발생
        s_axis_tvalid = 0;           // 전송 끝났으니 내림
        
        #30; // 휴식

        // ----------------------------------------------------
        // [시나리오 2] 연속 패킷 수신 테스트 (TLAST 확인)
        // ----------------------------------------------------
        $display("\n[%0t ns] === Scenario 2: Packet Transfer with TLAST ===", $time);
        @(posedge ACLK);
        s_axis_tvalid = 1;
        s_axis_tdata  = 32'hAAAA_0001;
        @(posedge ACLK);
        s_axis_tdata  = 32'hAAAA_0002;
        @(posedge ACLK);
        s_axis_tdata  = 32'hAAAA_0003;
        s_axis_tlast  = 1;           // 이게 마지막 데이터야!
        @(posedge ACLK);
        s_axis_tvalid = 0;
        s_axis_tlast  = 0;

        #30;

        // ----------------------------------------------------
        // [시나리오 3] Back-pressure 테스트 (수신 측 TREADY 제어)
        // ----------------------------------------------------
        $display("\n[%0t ns] === Scenario 3: Back-pressure (TREADY delay) ===", $time);
        @(posedge ACLK);
        s_axis_tvalid = 1;
        s_axis_tdata  = 32'hBBBB_1111;
        
        // 앗! Slave의 스위치를 꺼버렸다! (TREADY = 0 이 됨)
        enable_rx_i = 0; 
        
        @(posedge ACLK);
        // Master는 규정상 TREADY가 0이면 TVALID와 TDATA를 바꿀 수 없고 무한정 홀드해야 합니다.
        $display("[%0t ns] Master waiting for TREADY... (holding data)", $time);
        
        #40; // 4 사이클 동안 강제로 통신 지연 발생..
        
        @(posedge ACLK);
        enable_rx_i = 1; // Slave가 데이터 받을 공간 확보! 스위치 On (TREADY = 1)
        $display("[%0t ns] Slave is ready now! (TREADY=1)", $time);
        
        @(posedge ACLK); // 교집합 성립! 드디어 전송 완료
        s_axis_tvalid = 0;

        #50;
        
        $display("[%0t ns] Simulation Finish!", $time);
        $finish;
    end

endmodule
