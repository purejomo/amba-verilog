`ifndef AXIS_DRIVER_SV
`define AXIS_DRIVER_SV

`timescale 1ns / 1ps

class axis_driver;
    virtual axis_if vif;
    mailbox #(axis_transaction) gen2drv;
    
    function new(virtual axis_if vif, mailbox #(axis_transaction) gen2drv);
        this.vif = vif;
        this.gen2drv = gen2drv;
    endfunction
    
    // Called each clock cycle
    task run();
        vif.user_valid <= 0;
        vif.user_data  <= 0;
        vif.user_last  <= 0;
        
        forever begin
            axis_transaction tr;
            gen2drv.get(tr);
            
            @(posedge vif.clk);
            #1;
            vif.user_valid <= 1;
            vif.user_data  <= tr.data;
            vif.user_last  <= tr.last;
            
            // Wait until user_ready is asserted (master accepts the data)
            // [Verilator Workaround] Reading user_ready from vif.obs_user_ready 
            // instead of 'ref logic' to satisfy Verilator's strict type checking.
            do begin
                @(posedge vif.clk);
                #1;
            end while (vif.obs_user_ready !== 1'b1);
            
            vif.user_valid <= 0;
        end
    endtask
endclass

`endif
