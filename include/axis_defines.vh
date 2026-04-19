`ifndef AXIS_DEFINES_VH
`define AXIS_DEFINES_VH

// 기본 AXI4-Stream 파라미터 정의
`define TDATA_WIDTH 32
`define TKEEP_WIDTH (`TDATA_WIDTH/8)
`define TUSER_WIDTH 1
`define TID_WIDTH   8
`define TDEST_WIDTH 8

`endif // AXIS_DEFINES_VH
