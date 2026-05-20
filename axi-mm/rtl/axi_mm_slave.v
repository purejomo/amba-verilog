`timescale 1ns / 1ps

module axi_mm_slave #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter ID_WIDTH   = 4,
    parameter MEM_SIZE   = 1024 // 1KB Memory
)(
    input  wire                   ACLK,
    input  wire                   ARESETn,

    // ==========================================
    // AXI4 Interface
    // ==========================================
    
    // AW Channel
    input  wire [ID_WIDTH-1:0]    s_axi_awid,
    input  wire [ADDR_WIDTH-1:0]  s_axi_awaddr,
    input  wire [7:0]             s_axi_awlen,
    input  wire [2:0]             s_axi_awsize,
    input  wire [1:0]             s_axi_awburst,
    input  wire                   s_axi_awvalid,
    output reg                    s_axi_awready,

    // W Channel
    input  wire [DATA_WIDTH-1:0]  s_axi_wdata,
    input  wire [(DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input  wire                   s_axi_wlast,
    input  wire                   s_axi_wvalid,
    output reg                    s_axi_wready,

    // B Channel
    output reg  [ID_WIDTH-1:0]    s_axi_bid,
    output reg  [1:0]             s_axi_bresp,
    output reg                    s_axi_bvalid,
    input  wire                   s_axi_bready,

    // AR Channel
    input  wire [ID_WIDTH-1:0]    s_axi_arid,
    input  wire [ADDR_WIDTH-1:0]  s_axi_araddr,
    input  wire [7:0]             s_axi_arlen,
    input  wire [2:0]             s_axi_arsize,
    input  wire [1:0]             s_axi_arburst,
    input  wire                   s_axi_arvalid,
    output reg                    s_axi_arready,

    // R Channel
    output reg  [ID_WIDTH-1:0]    s_axi_rid,
    output reg  [DATA_WIDTH-1:0]  s_axi_rdata,
    output reg  [1:0]             s_axi_rresp,
    output reg                    s_axi_rlast,
    output reg                    s_axi_rvalid,
    input  wire                   s_axi_rready,

    // Testbench Control
    input  wire                   enable_rx_i // Back-pressure generation
);

    // ==========================================
    // Memory Array
    // ==========================================
    reg [7:0] mem [0:MEM_SIZE-1];

    // ==========================================
    // Internal Registers
    // ==========================================
    reg [ADDR_WIDTH-1:0] write_addr;
    reg [ADDR_WIDTH-1:0] read_addr;
    reg [7:0]            read_len;
    reg [7:0]            read_count;

    // ==========================================
    // AW Channel & W Channel (Write Transaction)
    // ==========================================
    always @(posedge ACLK) begin
        if (!ARESETn) begin
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            write_addr    <= 0;
        end 
        else begin
            // Accept Address when AWVALID is high and AWREADY is low
            if (s_axi_awvalid && !s_axi_awready) begin
                s_axi_awready <= 1'b1;
                write_addr    <= s_axi_awaddr;
            end else begin
                s_axi_awready <= 1'b0;
            end

            // Accept Data when WVALID is high, considering Back-pressure
            if (s_axi_wvalid && !s_axi_wready && enable_rx_i) begin
                s_axi_wready <= 1'b1;
                // Simple memory write (assume 32-bit aligned for simplicity)
                if (s_axi_wstrb[0]) mem[write_addr+0] <= s_axi_wdata[7:0];
                if (s_axi_wstrb[1]) mem[write_addr+1] <= s_axi_wdata[15:8];
                if (s_axi_wstrb[2]) mem[write_addr+2] <= s_axi_wdata[23:16];
                if (s_axi_wstrb[3]) mem[write_addr+3] <= s_axi_wdata[31:24];
            end else if (s_axi_wready) begin
                s_axi_wready <= 1'b0;
                write_addr   <= write_addr + 4; // INCR burst behavior (4 bytes)
            end
        end
    end

    // ==========================================
    // B Channel (Write Response)
    // ==========================================
    always @(posedge ACLK) begin
        if (!ARESETn) begin
            s_axi_bvalid <= 1'b0;
            s_axi_bresp  <= 2'b00; // OKAY
            s_axi_bid    <= 0;
        end 
        else begin
            // Trigger Response when WLAST is accepted
            if (s_axi_wvalid && s_axi_wready && s_axi_wlast) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bid    <= s_axi_awid;
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end

    // ==========================================
    // AR Channel & R Channel (Read Transaction)
    // ==========================================
    reg r_state; // 0: IDLE, 1: BURST_READ

    always @(posedge ACLK) begin
        if (!ARESETn) begin
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rlast   <= 1'b0;
            r_state       <= 1'b0;
            read_count    <= 0;
        end 
        else begin
            // Default response
            s_axi_rresp <= 2'b00; // OKAY
            s_axi_rid   <= s_axi_arid;

            case (r_state)
                1'b0: begin // IDLE
                    s_axi_rvalid <= 1'b0;
                    s_axi_rlast  <= 1'b0;

                    if (s_axi_arvalid && !s_axi_arready) begin
                        s_axi_arready <= 1'b1;
                        read_addr     <= s_axi_araddr;
                        read_len      <= s_axi_arlen;
                        read_count    <= 0;
                        r_state       <= 1'b1; // Move to BURST_READ state
                    end else begin
                        s_axi_arready <= 1'b0;
                    end
                end

                1'b1: begin // BURST_READ
                    s_axi_arready <= 1'b0;
                    s_axi_rvalid  <= 1'b1;
                    
                    s_axi_rdata[7:0]   <= mem[read_addr+0];
                    s_axi_rdata[15:8]  <= mem[read_addr+1];
                    s_axi_rdata[23:16] <= mem[read_addr+2];
                    s_axi_rdata[31:24] <= mem[read_addr+3];

                    if (read_count == read_len) begin
                        s_axi_rlast <= 1'b1;
                    end else begin
                        s_axi_rlast <= 1'b0;
                    end

                    if (s_axi_rvalid && s_axi_rready) begin
                        if (s_axi_rlast) begin
                            s_axi_rvalid <= 1'b0;
                            r_state      <= 1'b0; // End of burst
                        end else begin
                            read_addr  <= read_addr + 4; // INCR
                            read_count <= read_count + 1;
                        end
                    end
                end
            endcase
        end
    end

endmodule
