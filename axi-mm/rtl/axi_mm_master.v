`timescale 1ns / 1ps

module axi_mm_master #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter ID_WIDTH   = 4
)(
    input  wire                   ACLK,
    input  wire                   ARESETn,

    // User Interface - Write Control
    input  wire                   user_awvalid,
    output wire                   user_awready,
    input  wire [ADDR_WIDTH-1:0]  user_awaddr,
    input  wire [7:0]             user_awlen,

    // User Interface - Write Data
    input  wire                   user_wvalid,
    output wire                   user_wready,
    input  wire [DATA_WIDTH-1:0]  user_wdata,
    input  wire                   user_wlast,

    // User Interface - Write Response
    output wire                   user_bvalid,
    input  wire                   user_bready,

    // User Interface - Read Control
    input  wire                   user_arvalid,
    output wire                   user_arready,
    input  wire [ADDR_WIDTH-1:0]  user_araddr,
    input  wire [7:0]             user_arlen,

    // User Interface - Read Data
    output wire                   user_rvalid,
    input  wire                   user_rready,
    output wire [DATA_WIDTH-1:0]  user_rdata,
    output wire                   user_rlast,

    // ==========================================
    // AXI4 Interface
    // ==========================================
    
    // AW Channel
    output wire [ID_WIDTH-1:0]    m_axi_awid,
    output wire [ADDR_WIDTH-1:0]  m_axi_awaddr,
    output wire [7:0]             m_axi_awlen,
    output wire [2:0]             m_axi_awsize,
    output wire [1:0]             m_axi_awburst,
    output wire                   m_axi_awvalid,
    input  wire                   m_axi_awready,

    // W Channel
    output wire [DATA_WIDTH-1:0]  m_axi_wdata,
    output wire [(DATA_WIDTH/8)-1:0] m_axi_wstrb,
    output wire                   m_axi_wlast,
    output wire                   m_axi_wvalid,
    input  wire                   m_axi_wready,

    // B Channel
    input  wire [ID_WIDTH-1:0]    m_axi_bid,
    input  wire [1:0]             m_axi_bresp,
    input  wire                   m_axi_bvalid,
    output wire                   m_axi_bready,

    // AR Channel
    output wire [ID_WIDTH-1:0]    m_axi_arid,
    output wire [ADDR_WIDTH-1:0]  m_axi_araddr,
    output wire [7:0]             m_axi_arlen,
    output wire [2:0]             m_axi_arsize,
    output wire [1:0]             m_axi_arburst,
    output wire                   m_axi_arvalid,
    input  wire                   m_axi_arready,

    // R Channel
    input  wire [ID_WIDTH-1:0]    m_axi_rid,
    input  wire [DATA_WIDTH-1:0]  m_axi_rdata,
    input  wire [1:0]             m_axi_rresp,
    input  wire                   m_axi_rlast,
    input  wire                   m_axi_rvalid,
    output wire                   m_axi_rready
);

    // ==========================================
    // AW Channel (Write Address)
    // ==========================================
    assign m_axi_awid    = {ID_WIDTH{1'b0}};
    assign m_axi_awaddr  = user_awaddr;
    assign m_axi_awlen   = user_awlen;
    assign m_axi_awsize  = 3'b010; // 4 bytes (32-bit)
    assign m_axi_awburst = 2'b01;  // INCR mode
    assign m_axi_awvalid = user_awvalid;
    assign user_awready  = m_axi_awready;

    // ==========================================
    // W Channel (Write Data)
    // ==========================================
    assign m_axi_wdata   = user_wdata;
    assign m_axi_wstrb   = {(DATA_WIDTH/8){1'b1}}; // All bytes valid
    assign m_axi_wlast   = user_wlast;
    assign m_axi_wvalid  = user_wvalid;
    assign user_wready   = m_axi_wready;

    // ==========================================
    // B Channel (Write Response)
    // ==========================================
    assign user_bvalid   = m_axi_bvalid;
    assign m_axi_bready  = user_bready;

    // ==========================================
    // AR Channel (Read Address)
    // ==========================================
    assign m_axi_arid    = {ID_WIDTH{1'b0}};
    assign m_axi_araddr  = user_araddr;
    assign m_axi_arlen   = user_arlen;
    assign m_axi_arsize  = 3'b010; // 4 bytes (32-bit)
    assign m_axi_arburst = 2'b01;  // INCR mode
    assign m_axi_arvalid = user_arvalid;
    assign user_arready  = m_axi_arready;

    // ==========================================
    // R Channel (Read Data)
    // ==========================================
    assign user_rvalid   = m_axi_rvalid;
    assign user_rdata    = m_axi_rdata;
    assign user_rlast    = m_axi_rlast;
    assign m_axi_rready  = user_rready;

endmodule
