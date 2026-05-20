`ifndef AXIS_ENV_SV
`define AXIS_ENV_SV

`timescale 1ns / 1ps
`include "axis_transaction.sv"
`include "axis_driver.sv"
`include "axis_monitor.sv"
`include "axis_scoreboard.sv"

class axis_env;
    virtual axis_if vif;
    
    // [Verilator Workaround]
    // Previously, 'tvalid', 'tready', and 'user_ready' were passed as 'ref logic' arguments. 
    // Since Verilator doesn't support 'ref wire', we now access them exclusively through 'vif.obs_*' interface logic signals.
    
    mailbox #(axis_transaction) gen2drv;
    mailbox #(axis_transaction) mon2scb_in;
    mailbox #(axis_transaction) mon2scb_out;
    
    axis_driver driver;
    axis_monitor monitor;
    axis_scoreboard scb;
    
    int num_transactions;
    
    function new(virtual axis_if vif);
        this.vif = vif;
        gen2drv      = new();
        mon2scb_in   = new();
        mon2scb_out  = new();
        
        driver  = new(vif, gen2drv);
        monitor = new(vif, mon2scb_in, mon2scb_out);
        scb     = new(mon2scb_in, mon2scb_out);
        num_transactions = 1000;
    endfunction
    
    task gen_transactions();
        for (int i = 0; i < num_transactions; i++) begin
            axis_transaction tr = new();
            void'(tr.randomize());
            if (i % 10 == 9) tr.last = 1'b1;
            else             tr.last = 1'b0;
            gen2drv.put(tr);
            if (i % 10 == 0) @(posedge vif.clk);
        end
    endtask
    
    task run();
        fork
            gen_transactions();
            driver.run();
            monitor.run();
            scb.run();
        join_any
        
        wait(scb.match_count + scb.error_count == num_transactions);
        #100;
        scb.report();
    endtask
endclass

`endif
