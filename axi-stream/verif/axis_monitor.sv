`ifndef AXIS_MONITOR_SV
`define AXIS_MONITOR_SV

`timescale 1ns / 1ps

class axis_monitor;
    virtual axis_if vif;
    mailbox #(axis_transaction) mon2scb_in;  // User-side input capture
    mailbox #(axis_transaction) mon2scb_out; // AXI-Stream bus-side capture
    
    function new(virtual axis_if vif,
                 mailbox #(axis_transaction) mon2scb_in,
                 mailbox #(axis_transaction) mon2scb_out);
        this.vif = vif;
        this.mon2scb_in  = mon2scb_in;
        this.mon2scb_out = mon2scb_out;
    endfunction
    
    // Monitor user-side input: capture when user_valid && user_ready (accepted by master)
    // [Verilator Workaround] Using vif.obs_user_ready instead of a 'ref logic' task argument.
    task run_in();
        forever begin
            @(posedge vif.clk);
            #1;
            if (vif.user_valid && vif.obs_user_ready) begin
                axis_transaction tr = new();
                tr.data = vif.user_data;
                tr.last = vif.user_last;
                $display("[%0t ns] [MON_IN] Captured data=%h", $time, tr.data);
                mon2scb_in.put(tr);
            end
        end
    endtask
    
    // Monitor AXI-Stream bus: capture when tvalid && tready (bus handshake)
    // [Verilator Workaround] Using vif.obs_tvalid and vif.obs_tready instead of 'ref logic'.
    task run_out();
        forever begin
            @(posedge vif.clk);
            #1;
            if (vif.obs_tvalid && vif.obs_tready) begin
                axis_transaction tr = new();
                tr.data = vif.tdata;
                tr.last = vif.tlast;
                mon2scb_out.put(tr);
            end
        end
    endtask
    
    task run();
        fork
            run_in();
            run_out();
        join
    endtask
endclass

`endif
