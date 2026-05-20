`ifndef AXIS_SCOREBOARD_SV
`define AXIS_SCOREBOARD_SV

`timescale 1ns / 1ps

class axis_scoreboard;
    mailbox #(axis_transaction) mon2scb_in;
    mailbox #(axis_transaction) mon2scb_out;
    
    int match_count;
    int error_count;
    
    function new(mailbox #(axis_transaction) mon2scb_in, mailbox #(axis_transaction) mon2scb_out);
        this.mon2scb_in = mon2scb_in;
        this.mon2scb_out = mon2scb_out;
        this.match_count = 0;
        this.error_count = 0;
    endfunction
    
    task run();
        forever begin
            axis_transaction tr_in, tr_out;
            mon2scb_in.get(tr_in);
            mon2scb_out.get(tr_out);
            
            if (tr_in.compare(tr_out)) begin
                match_count++;
                $display("[%0t ns] [SCOREBOARD] MATCH: Expected=%h, Actual=%h", $time, tr_in.data, tr_out.data);
            end else begin
                error_count++;
                $display("[%0t ns] [SCOREBOARD] ERROR! Expected data=%h, Actual data=%h", $time, tr_in.data, tr_out.data);
            end
        end
    endtask
    
    function void report();
        $display("========================================");
        $display(" SCOREBOARD REPORT");
        $display("========================================");
        $display(" Total Matches : %0d", match_count);
        $display(" Total Errors  : %0d", error_count);
        if (error_count == 0) $display(" -> TEST PASSED! All data correctly verified.");
        else $display(" -> TEST FAILED! Data mismatch detected.");
        $display("========================================");
    endfunction
endclass

`endif
