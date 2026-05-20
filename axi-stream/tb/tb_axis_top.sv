`timescale 1ns / 1ps

`include "axis_if.sv"
`include "axis_transaction.sv"
`include "axis_driver.sv"
`include "axis_monitor.sv"
`include "axis_scoreboard.sv"
`include "axis_env.sv"

module tb_axis_top ();
    logic clk = 0;
    logic rst_n;
    
    // tvalid/tready/user_ready are pure combinational assign outputs in RTL.
    // Declaring them inside an interface causes Verilator DIDNOTCONVERGE.
    // They are connected as plain module-level wires instead.
    wire  tvalid;
    wire  tready;
    wire  user_ready;
    
    // Interface (contains all non-combinational-output signals)
    axis_if vif(clk, rst_n);
    
    // [Verilator Workaround]
    // To avoid passing 'wire' outputs to class methods (which Verilator rejects),
    // we assign them to 'logic' variables inside the interface here.
    assign vif.obs_tvalid = tvalid;
    assign vif.obs_tready = tready;
    assign vif.obs_user_ready = user_ready;
    
    // DUT - Master
    axis_master u_master (
        .ACLK(clk),
        .ARESETn(rst_n),
        .user_valid_i(vif.user_valid),
        .user_ready_o(user_ready),
        .user_data_i(vif.user_data),
        .user_last_i(vif.user_last),
        
        .m_axis_tvalid(tvalid),
        .m_axis_tready(tready),
        .m_axis_tdata(vif.tdata),
        .m_axis_tkeep(vif.tkeep),
        .m_axis_tlast(vif.tlast),
        .m_axis_tuser(vif.tuser),
        .m_axis_tid(vif.tid),
        .m_axis_tdest(vif.tdest)
    );
    
    // DUT - Slave
    axis_slave u_slave (
        .ACLK(clk),
        .ARESETn(rst_n),
        .enable_rx_i(vif.enable_rx),
        .done_o(),
        .data_count_o(),
        
        .s_axis_tvalid(tvalid),
        .s_axis_tready(tready),
        .s_axis_tdata(vif.tdata),
        .s_axis_tkeep(vif.tkeep),
        .s_axis_tlast(vif.tlast),
        .s_axis_tuser(vif.tuser),
        .s_axis_tid(vif.tid),
        .s_axis_tdest(vif.tdest)
    );
    
    // Clock Generation
    initial forever #5 clk = ~clk;
    
    // Back-pressure Generation
    initial begin
        vif.enable_rx = 1;
        #100;
        forever begin
            @(negedge clk);
            vif.enable_rx = ($urandom_range(0, 1) != 0);
            repeat ($urandom_range(1, 5)) @(negedge clk);
        end
    end
    
    // Verification Environment
    axis_env env;
    
    initial begin
        $dumpfile("sim/dump.vcd");
        $dumpvars(0, tb_axis_top);
        
        rst_n = 0;
        vif.user_valid = 0;
        #27;
        rst_n = 1;
        
        $display("========================================");
        $display(" Starting Custom UVM-like Environment ");
        $display("========================================");
        
        env = new(vif);
        env.num_transactions = 1000;
        env.run();
        
        $finish;
    end
endmodule
