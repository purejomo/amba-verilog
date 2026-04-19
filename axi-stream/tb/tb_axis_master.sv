`timescale 1ns / 1ps

module tb_axis_master ();

    // 클럭 & 리셋
    reg ACLK;
    reg ARESETn;

    // 상위 제어 신호 (Testbench -> Master)
    reg         user_valid_i;
    wire        user_ready_o;
    reg  [31:0] user_data_i;
    reg         user_last_i;

    // 수신단 제어 신호 (Testbench -> Slave)
    reg         enable_rx_i;
    wire        done_o;
    wire [31:0] data_count_o;

    // AXI-Stream 버스 신호 (Master와 Slave를 이어주는 내부 전선들)
    wire        axis_tvalid;
    wire        axis_tready;
    wire [31:0] axis_tdata;
    wire [3:0]  axis_tkeep;
    wire        axis_tlast;
    wire        axis_tuser;
    wire [7:0]  axis_tid;
    wire [7:0]  axis_tdest;

    // 1. 송신단 (Master) 인스턴스화
    axis_master u_axis_master (
        .ACLK(ACLK),
        .ARESETn(ARESETn),
        
        .user_valid_i(user_valid_i),
        .user_ready_o(user_ready_o),
        .user_data_i(user_data_i),
        .user_last_i(user_last_i),
        
        .m_axis_tvalid(axis_tvalid),
        .m_axis_tready(axis_tready),
        .m_axis_tdata(axis_tdata),
        .m_axis_tkeep(axis_tkeep),
        .m_axis_tlast(axis_tlast),
        .m_axis_tuser(axis_tuser),
        .m_axis_tid(axis_tid),
        .m_axis_tdest(axis_tdest)
    );

    // 2. 수신단 (Slave) 인스턴스화
    axis_slave u_axis_slave (
        .ACLK(ACLK),
        .ARESETn(ARESETn),
        
        .enable_rx_i(enable_rx_i),
        .done_o(done_o),
        .data_count_o(data_count_o),
        
        .s_axis_tvalid(axis_tvalid),
        .s_axis_tready(axis_tready),
        .s_axis_tdata(axis_tdata),
        .s_axis_tkeep(axis_tkeep),
        .s_axis_tlast(axis_tlast),
        .s_axis_tuser(axis_tuser),
        .s_axis_tid(axis_tid),
        .s_axis_tdest(axis_tdest)
    );

    // 10ns 주기 클럭 생성
    initial begin
        ACLK = 0;
        forever #5 ACLK = ~ACLK;
    end

    // 기초 시뮬레이션 시나리오 뼈대
    initial begin
        // 파형 생성 로그용
        $dumpfile("sim/dump.vcd");
        $dumpvars(0, tb_axis_master);

        // 신호 초기화
        ARESETn = 0;
        user_valid_i = 0;
        user_data_i = 0;
        user_last_i = 0;
        enable_rx_i = 1; // 기본적으로 Slave는 수신 허용 상태로 시작

        #25;
        // 리셋 해제
        ARESETn = 1;
        $display("[%0t ns] Reset Released!", $time);

        // ----------------------------------------------------
        // [시나리오 1] 단순 1패킷 정상 전송 (User -> Master -> Slave)
        // ----------------------------------------------------
        $display("\n[%0t ns] === Scenario 1: Normal Transfer ===", $time);
        @(posedge ACLK);
        user_valid_i = 1;
        user_data_i  = 32'h1111_AAAA;
        user_last_i  = 1; // 단발성이므로 마지막 데이터라고 명시!
        
        // 시뮬레이션 상에서는 Master가 받을 준비(user_ready_o==1)가 되어있을 때만 다음 클럭으로 넘어가도록 구현
        while (user_ready_o == 0) @(posedge ACLK);
        
        @(posedge ACLK); 
        user_valid_i = 0; // Master가 데이터를 가져갔으므로 user는 off

        #40; // 잠시 휴식

        // ----------------------------------------------------
        // [시나리오 2] Back-pressure 역전파 및 복구 후 연속 전송
        // ----------------------------------------------------
        $display("\n[%0t ns] === Scenario 2: Back-pressure & Recovery ===", $time);
        
        // 1. 갑자기 Slave 측 수신 스위치(TREADY)를 내려서 톨게이트를 닫아버립니다!
        @(posedge ACLK);
        enable_rx_i = 0; 
        $display("[%0t ns] [WARNING] Slave is Disabled! (TREADY=0)", $time);

        // 2. 이 사실을 모르는 User Logic은 평소처럼 첫 번째 데이터를 Master에게 맡깁니다.
        @(posedge ACLK);
        user_valid_i = 1;
        user_data_i  = 32'h2222_BBBB;
        user_last_i  = 0;
        
        // Master는 현재 빈 통이므로 2222_BBBB를 일단 기분 좋게 꿀꺽 삼킵니다.
        while (user_ready_o == 0) @(posedge ACLK); 
        @(posedge ACLK);
        
        // 3. User Logic은 이어서 두 번째 데이터를 넣으려고 핀에 값을 올립니다.
        user_data_i  = 32'h3333_CCCC;
        user_last_i  = 1;
        
        // 하지만! Master는 첫 번째 데이터(2222_BBBB)를 버스에 올렸지만 톨게이트(Slave)가 닫혀있어 꽉 막혀있습니다.
        // Master는 더 이상 짐을 받을 수 없으므로, 위쪽으로 올리던 user_ready_o 핀을 '0'으로 내려버릴 것입니다! (Back-pressure 전파)
        #1;
        $display("[%0t ns] User logic wants to send 3333_CCCC, but Master's user_ready_o is %b", $time, user_ready_o);
        
        // 4. 강제로 4클럭 동안 톨게이트가 고장난 상태를 유지합니다.
        // User Logic은 user_ready_o가 1이 될 때까지 무한정 기다리는 while문에 갇히게 됩니다!
        fork
            begin
                // Thread A: User Logic은 ready가 될 때까지 손가락 빨며 대기
                while (user_ready_o == 0) @(posedge ACLK);
                @(posedge ACLK);
                user_valid_i = 0;
                $display("[%0t ns] Master finally accepted 3333_CCCC!", $time);
            end
            begin
                // Thread B: 신적인 권한으로 40ns 뒤에 톨게이트 수리 완료!
                #40;
                $display("[%0t ns] [REPAIRED] Enabling Slave again (TREADY=1)", $time);
                enable_rx_i = 1;
            end
        join

        #50;
        
        $display("[%0t ns] Simulation Finish!", $time);
        $finish;
    end

endmodule
