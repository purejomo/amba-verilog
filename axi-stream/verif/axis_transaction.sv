`ifndef AXIS_TRANSACTION_SV
`define AXIS_TRANSACTION_SV

`timescale 1ns / 1ps

class axis_transaction;
    rand logic [31:0] data;
    rand logic        last;

    function void display(string name);
        $display("[%0t ns] %s: data=%h, last=%b", $time, name, data, last);
    endfunction
    
    function bit compare(axis_transaction tr);
        if (this.data !== tr.data) return 0;
        if (this.last !== tr.last) return 0;
        return 1;
    endfunction
endclass

`endif
