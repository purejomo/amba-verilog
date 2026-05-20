`timescale 1ns / 1ps

// axis_if: AXI-Stream signal bundle for verification environment.
// Signals that are outputs of pure combinational 'assign' in RTL (tready, user_ready)
// are intentionally excluded from this interface to avoid Verilator DIDNOTCONVERGE.
interface axis_if(input logic clk, input logic rst_n);
    // User-side Signals (TB -> DUT Master)
    logic        user_valid;
    logic [31:0] user_data;
    logic        user_last;

    // AXI-Stream Data Signals (DUT Master -> DUT Slave)
    logic [31:0] tdata;
    logic [3:0]  tkeep;
    logic        tlast;
    logic        tuser;
    logic [7:0]  tid;
    logic [7:0]  tdest;

    // Slave Back-pressure Control (TB -> DUT Slave)
    logic        enable_rx;

    // Observation signals for testbench read-only access.
    // [Verilator Workaround] Verilator strictly forbids passing module 'wire' signals 
    // as 'ref logic' arguments into classes (causes %Error-PROCASSWIRE).
    // Therefore, we declare logic variables here and continuously assign them in the top module.
    logic        obs_tvalid;
    logic        obs_tready;
    logic        obs_user_ready;

    initial begin
        user_valid = 0;
        user_data  = 0;
        user_last  = 0;
        tdata      = 0;
        tkeep      = 0;
        tlast      = 0;
        tuser      = 0;
        tid        = 0;
        tdest      = 0;
        enable_rx  = 1;
    end
endinterface
