`timescale 1ns / 1ps

module tb_axi_mm_top ();

    // ==========================================
    // Parameters & Signals
    // ==========================================
    parameter ADDR_WIDTH = 32;
    parameter DATA_WIDTH = 32;
    parameter ID_WIDTH   = 4;

    reg ACLK;
    reg ARESETn;

    // Master User Interface - Write Control
    reg                   user_awvalid;
    wire                  user_awready;
    reg  [ADDR_WIDTH-1:0] user_awaddr;
    reg  [7:0]            user_awlen;

    // Master User Interface - Write Data
    reg                   user_wvalid;
    wire                  user_wready;
    reg  [DATA_WIDTH-1:0] user_wdata;
    reg                   user_wlast;

    // Master User Interface - Write Response
    wire                  user_bvalid;
    reg                   user_bready;

    // Master User Interface - Read Control
    reg                   user_arvalid;
    wire                  user_arready;
    reg  [ADDR_WIDTH-1:0] user_araddr;
    reg  [7:0]            user_arlen;

    // Master User Interface - Read Data
    wire                  user_rvalid;
    reg                   user_rready;
    wire [DATA_WIDTH-1:0] user_rdata;
    wire                  user_rlast;

    // Slave Control
    reg                   enable_rx_i;

    // AXI Interconnect Signals
    wire [ID_WIDTH-1:0]   axi_awid;
    wire [ADDR_WIDTH-1:0] axi_awaddr;
    wire [7:0]            axi_awlen;
    wire [2:0]            axi_awsize;
    wire [1:0]            axi_awburst;
    wire                  axi_awvalid;
    wire                  axi_awready;

    wire [DATA_WIDTH-1:0] axi_wdata;
    wire [(DATA_WIDTH/8)-1:0] axi_wstrb;
    wire                  axi_wlast;
    wire                  axi_wvalid;
    wire                  axi_wready;

    wire [ID_WIDTH-1:0]   axi_bid;
    wire [1:0]            axi_bresp;
    wire                  axi_bvalid;
    wire                  axi_bready;

    wire [ID_WIDTH-1:0]   axi_arid;
    wire [ADDR_WIDTH-1:0] axi_araddr;
    wire [7:0]            axi_arlen;
    wire [2:0]            axi_arsize;
    wire [1:0]            axi_arburst;
    wire                  axi_arvalid;
    wire                  axi_arready;

    wire [ID_WIDTH-1:0]   axi_rid;
    wire [DATA_WIDTH-1:0] axi_rdata;
    wire [1:0]            axi_rresp;
    wire                  axi_rlast;
    wire                  axi_rvalid;
    wire                  axi_rready;

    // ==========================================
    // Instantiations
    // ==========================================
    axi_mm_master #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ID_WIDTH(ID_WIDTH)
    ) u_master (
        .ACLK(ACLK),
        .ARESETn(ARESETn),
        .user_awvalid(user_awvalid),
        .user_awready(user_awready),
        .user_awaddr(user_awaddr),
        .user_awlen(user_awlen),
        .user_wvalid(user_wvalid),
        .user_wready(user_wready),
        .user_wdata(user_wdata),
        .user_wlast(user_wlast),
        .user_bvalid(user_bvalid),
        .user_bready(user_bready),
        .user_arvalid(user_arvalid),
        .user_arready(user_arready),
        .user_araddr(user_araddr),
        .user_arlen(user_arlen),
        .user_rvalid(user_rvalid),
        .user_rready(user_rready),
        .user_rdata(user_rdata),
        .user_rlast(user_rlast),

        .m_axi_awid(axi_awid),
        .m_axi_awaddr(axi_awaddr),
        .m_axi_awlen(axi_awlen),
        .m_axi_awsize(axi_awsize),
        .m_axi_awburst(axi_awburst),
        .m_axi_awvalid(axi_awvalid),
        .m_axi_awready(axi_awready),
        .m_axi_wdata(axi_wdata),
        .m_axi_wstrb(axi_wstrb),
        .m_axi_wlast(axi_wlast),
        .m_axi_wvalid(axi_wvalid),
        .m_axi_wready(axi_wready),
        .m_axi_bid(axi_bid),
        .m_axi_bresp(axi_bresp),
        .m_axi_bvalid(axi_bvalid),
        .m_axi_bready(axi_bready),
        .m_axi_arid(axi_arid),
        .m_axi_araddr(axi_araddr),
        .m_axi_arlen(axi_arlen),
        .m_axi_arsize(axi_arsize),
        .m_axi_arburst(axi_arburst),
        .m_axi_arvalid(axi_arvalid),
        .m_axi_arready(axi_arready),
        .m_axi_rid(axi_rid),
        .m_axi_rdata(axi_rdata),
        .m_axi_rresp(axi_rresp),
        .m_axi_rlast(axi_rlast),
        .m_axi_rvalid(axi_rvalid),
        .m_axi_rready(axi_rready)
    );

    axi_mm_slave #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ID_WIDTH(ID_WIDTH)
    ) u_slave (
        .ACLK(ACLK),
        .ARESETn(ARESETn),
        .s_axi_awid(axi_awid),
        .s_axi_awaddr(axi_awaddr),
        .s_axi_awlen(axi_awlen),
        .s_axi_awsize(axi_awsize),
        .s_axi_awburst(axi_awburst),
        .s_axi_awvalid(axi_awvalid),
        .s_axi_awready(axi_awready),
        .s_axi_wdata(axi_wdata),
        .s_axi_wstrb(axi_wstrb),
        .s_axi_wlast(axi_wlast),
        .s_axi_wvalid(axi_wvalid),
        .s_axi_wready(axi_wready),
        .s_axi_bid(axi_bid),
        .s_axi_bresp(axi_bresp),
        .s_axi_bvalid(axi_bvalid),
        .s_axi_bready(axi_bready),
        .s_axi_arid(axi_arid),
        .s_axi_araddr(axi_araddr),
        .s_axi_arlen(axi_arlen),
        .s_axi_arsize(axi_arsize),
        .s_axi_arburst(axi_arburst),
        .s_axi_arvalid(axi_arvalid),
        .s_axi_arready(axi_arready),
        .s_axi_rid(axi_rid),
        .s_axi_rdata(axi_rdata),
        .s_axi_rresp(axi_rresp),
        .s_axi_rlast(axi_rlast),
        .s_axi_rvalid(axi_rvalid),
        .s_axi_rready(axi_rready),
        
        .enable_rx_i(enable_rx_i)
    );

    // ==========================================
    // Clock Generation
    // ==========================================
    initial begin
        ACLK = 0;
        forever #5 ACLK = ~ACLK; // 10ns 주기 (100MHz)
    end

    // ==========================================
    // Simulation Scenarios
    // ==========================================
    initial begin
        $dumpfile("sim/dump.vcd");
        $dumpvars(0, tb_axi_mm_top);

        // 신호 초기화
        ARESETn      = 0;
        enable_rx_i  = 1;
        user_awvalid = 0;
        user_wvalid  = 0;
        user_bready  = 1; // 기본적으로 Write Response 수신 허용
        user_arvalid = 0;
        user_rready  = 1; // 기본적으로 Read Data 수신 허용
        
        #25;
        ARESETn = 1;
        $display("[%0t ns] Reset Released.", $time);

        // ----------------------------------------------------
        // [시나리오 1] 단일 데이터 Write 및 Read 검증
        // ----------------------------------------------------
        $display("\n[%0t ns] === Scenario 1: Single Write & Read ===", $time);
        
        // 1. Write Address 전달
        @(posedge ACLK);
        user_awvalid = 1;
        user_awaddr  = 32'h0000_0010;
        user_awlen   = 8'd0; // 1 Beat 전송
        while (!user_awready) @(posedge ACLK);
        @(posedge ACLK);
        user_awvalid = 0;

        // 2. Write Data 전달
        user_wvalid = 1;
        user_wdata  = 32'hDEADBEEF;
        user_wlast  = 1;
        while (!user_wready) @(posedge ACLK);
        @(posedge ACLK);
        user_wvalid = 0;
        user_wlast  = 0;

        // 3. Write Response 확인 대기
        while (!user_bvalid) @(posedge ACLK);
        $display("[%0t ns] Write Response Received.", $time);
        
        #40;

        // 4. Read Address 전달
        @(posedge ACLK);
        user_arvalid = 1;
        user_araddr  = 32'h0000_0010;
        user_arlen   = 8'd0; // 1 Beat 읽기
        while (!user_arready) @(posedge ACLK);
        @(posedge ACLK);
        user_arvalid = 0;

        // 5. Read Data 수신 대기
        while (!user_rvalid) @(posedge ACLK);
        $display("[%0t ns] Read Data Received: %h", $time, user_rdata);
        if (user_rdata !== 32'hDEADBEEF) $display("[%0t ns] [ERROR] Read Data Mismatch!", $time);

        #40;

        // ----------------------------------------------------
        // [시나리오 2] Burst 연속 데이터 Write 및 Back-pressure 전파 테스트
        // ----------------------------------------------------
        $display("\n[%0t ns] === Scenario 2: Burst Write with Back-pressure ===", $time);
        
        // Slave 내부의 수신 Ready 신호 고의 지연을 위한 비활성화
        @(posedge ACLK);
        enable_rx_i = 0;
        $display("[%0t ns] Slave Write Data 수신 비활성화 (WREADY 0 강제 유지)", $time);

        // 1. Write Address (Burst Length 3 = 4 Beats) 전달
        user_awvalid = 1;
        user_awaddr  = 32'h0000_0040;
        user_awlen   = 8'd3;
        while (!user_awready) @(posedge ACLK);
        @(posedge ACLK);
        user_awvalid = 0;

        // 2. Burst Data 전송 시작
        user_wvalid = 1;
        user_wdata  = 32'h1111_1111;
        user_wlast  = 0;
        
        // WREADY가 0이므로 송신 측 로직은 상태를 유지(Stall)하며 WVALID를 1로 유지해야 함
        $display("[%0t ns] Master가 WVALID 1 출력, 그러나 Slave WREADY 0으로 인해 대기 상태 지속", $time);

        // 병렬 스레드를 활용하여 일정 시간 대기 후 Slave 재활성화 처리
        fork
            begin
                // Master 송신 Thread
                // Beat 1
                while (!user_wready) @(posedge ACLK);
                @(posedge ACLK);
                $display("[%0t ns] Beat 1 (1111_1111) 전송 성공", $time);
                
                // Beat 2
                user_wdata = 32'h2222_2222;
                while (!user_wready) @(posedge ACLK);
                @(posedge ACLK);
                $display("[%0t ns] Beat 2 (2222_2222) 전송 성공", $time);

                // Beat 3
                user_wdata = 32'h3333_3333;
                while (!user_wready) @(posedge ACLK);
                @(posedge ACLK);
                $display("[%0t ns] Beat 3 (3333_3333) 전송 성공", $time);

                // Beat 4 (Last)
                user_wdata = 32'h4444_4444;
                user_wlast = 1;
                while (!user_wready) @(posedge ACLK);
                @(posedge ACLK);
                $display("[%0t ns] Beat 4 (4444_4444, LAST) 전송 성공", $time);
                
                user_wvalid = 0;
                user_wlast  = 0;
            end
            begin
                // Slave 활성화 Thread
                // 난수를 사용한 지연 삽입 (10클럭~30클럭)
                repeat ($urandom_range(10, 30)) @(posedge ACLK);
                enable_rx_i = 1;
                $display("[%0t ns] Slave Write Data 수신 재활성화 (WREADY 복구)", $time);
            end
        join

        // Write Response 확인
        while (!user_bvalid) @(posedge ACLK);
        $display("[%0t ns] Burst Write Response Received.", $time);

        #50;
        
        $display("\n[%0t ns] Simulation Finish!", $time);
        $finish;
    end

endmodule
