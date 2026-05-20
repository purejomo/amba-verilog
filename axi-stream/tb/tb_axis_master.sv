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

    // AXI-Stream 인터페이스 신호
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
        user_last_i  = 1; // 패킷의 마지막 데이터 표시
        
        // Master 준비 상태(user_ready_o == 1) 대기
        while (user_ready_o == 0) @(posedge ACLK);
        
        @(posedge ACLK); 
        user_valid_i = 0; // 데이터 전송 완료 후 valid 비활성화

        #40; // 대기 시간

        // ----------------------------------------------------
        // [시나리오 2] Back-pressure 역전파 및 복구 후 연속 전송
        // ----------------------------------------------------
        $display("\n[%0t ns] === Scenario 2: Back-pressure & Recovery ===", $time);
        
        // 1. Slave 수신 비활성화 (enable_rx_i = 0으로 설정하여 TREADY 비활성화)
        @(posedge ACLK);
        enable_rx_i = 0; 
        $display("[%0t ns] [WARNING] Slave is Disabled! (TREADY=0)", $time);

        // 2. User logic에서 첫 번째 데이터 전송 시도
        @(posedge ACLK);
        user_valid_i = 1;
        user_data_i  = 32'h2222_BBBB;
        user_last_i  = 0;
        
        // Master 내부 버퍼가 비어있어 첫 번째 데이터 수락
        while (user_ready_o == 0) @(posedge ACLK); 
        @(posedge ACLK);
        
        // 3. User logic에서 두 번째 데이터 전송을 위해 입력 데이터 갱신
        user_data_i  = 32'h3333_CCCC;
        user_last_i  = 1;
        
        // Slave가 비활성화(s_axis_tready = 0)되어 Master에서 Slave로의 전송이 중단됩니다.
        // Master 버퍼가 가득 차면서 user_ready_o가 0으로 비활성화됩니다. (Back-pressure 전파)
        #1;
        $display("[%0t ns] User logic wants to send 3333_CCCC, but Master's user_ready_o is %b", $time, user_ready_o);
        
        // 4. 4클럭 주기 동안 Slave 비활성 상태 유지하며 User logic은 user_ready_o가 1이 될 때까지 대기
        fork
            begin
                // Thread A: user_ready_o가 1이 될 때까지 대기
                while (user_ready_o == 0) @(posedge ACLK);
                @(posedge ACLK);
                user_valid_i = 0;
                $display("[%0t ns] Master finally accepted 3333_CCCC!", $time);
            end
            begin
                // Thread B: 40ns 경과 후 Slave 활성화 (enable_rx_i = 1)
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
