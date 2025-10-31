`include "axi_slave.v"
`include "dpbram.v"
`include "conv_bram.v"

module top_conv_axi #
(
    parameter integer KERNEL_SIZE   = 5,
    parameter integer WEIGHT_BW     = 8,
    parameter integer DATA_BW       = 8,
    parameter integer ADDR_BW       = 5,
    parameter integer SUM_BW        = 16,
    parameter integer KERNEL_BW     = 5,
    parameter integer DATA_SIZE     = 32,
    parameter integer STRIDE        = 1,
    parameter integer S_ID_BW       = 4,
    parameter integer S_CID_BW      = 4,
    parameter integer S_SID_BW      = (S_ID_BW+S_CID_BW),
    parameter integer S_ADDR_BW     = 32,
    parameter integer S_DATA_BW     = 32,
    parameter integer S_STRB_BW     = (S_DATA_BW/8)
)
(
    // Global Signals
    input   wire                        ACLK,
    input   wire                        ARESETn,

    // Write Address Signals
    input   wire [S_SID_BW-1 : 0]       AWID,
    input   wire [S_ADDR_BW-1 : 0]      AWADDR,
    input   wire [7:0]                  AWLEN,    // axi4
    input   wire [2:0]                  AWSIZE,
    input   wire [1:0]                  AWBURST,
    input   wire                        AWLOCK,   // axi4
    input   wire [3:0]                  AWCACHE,
    input   wire [2:0]                  AWPROT,
    input   wire [3:0]                  AWQOS,
    input   wire [3:0]                  AWREGION,
    input   wire                        AWVALID,
    output  wire                        AWREADY,

    // Write Data Signals
    input   wire [S_DATA_BW-1 : 0]      WDATA,
    input   wire [S_STRB_BW-1 : 0]      WSTRB,
    input   wire                        WLAST,
    input   wire                        WVALID,
    output  wire                        WREADY,

    // Write Response Signals
    input   wire                        BREADY,
    output  wire [S_SID_BW-1 : 0]       BID,
    output  wire [2:0]                  BRESP,
    output  wire                        BVALID,

    // Read Address Signals
    input   wire [S_SID_BW-1 : 0]       ARID,
    input   wire [S_ADDR_BW-1 : 0]      ARADDR,
    input   wire [7:0]                  ARLEN,           // axi4
    input   wire [2:0]                  ARSIZE,
    input   wire [1:0]                  ARBURST,
    input   wire                        ARLOCK,         // axi4
    input   wire [3:0]                  ARCACHE,
    input   wire [2:0]                  ARPROT,
    input   wire [3:0]                  ARQOS,
    input   wire [3:0]                  ARREGION,
    input   wire                        ARVALID,
    output  wire                        ARREADY,

    // Read Signals
    output   wire [S_SID_BW-1 : 0]      RID,
    output   wire [S_DATA_BW-1 : 0]     RDATA,
    output   wire [2:0]                 RRESP,
    output   wire                       RLAST,
    output   wire                       RVALID,
    input    wire                       RREADY,
    
    input   wire                        i_w_done,
    output  wire                        o_done
);

wire [S_ADDR_BW-1:0] i_r_addr_p0, i_r_addr_p1,
                     i_w_addr_p0, i_w_addr_p1;
wire [S_DATA_BW-1:0] i_w_data_p0, i_w_data_p1,
                     o_r_data_p0, o_r_data_p1;

wire                i_w_en_p0, i_w_en_p1, i_r_en_p0, i_r_en_p1;

axi_slave # (
    .S_ID_BW        (S_ID_BW        ),
    .S_CID_BW       (S_CID_BW       ),
    .S_SID_BW       (S_SID_BW       ),
    .S_ADDR_BW      (S_ADDR_BW      ),
    .S_DATA_BW      (S_DATA_BW      ),
    .S_STRB_BW      (S_STRB_BW      )
) AXI_SLAVE
(
    .ACLK           (ACLK           ),
    .ARESETn        (ARESETn        ),

    // Write Address Signals
    .AWID           (AWID           ), 
    .AWADDR         (AWADDR         ),
    .AWLEN          (AWLEN          ),
    .AWSIZE         (AWSIZE         ),
    .AWBURST        (AWBURST        ),
    .AWLOCK         (AWLOCK         ),
    .AWCACHE        (AWCACHE        ),
    .AWPROT         (AWPROT         ),     
    .AWQOS          (AWQOS          ),
    .AWREGION       (AWREGION       ),
    .AWVALID        (AWVALID        ),
    .AWREADY        (AWREADY        ),

    // Write Data Signals
    .WDATA          (WDATA          ), 
    .WSTRB          (WSTRB          ),
    .WLAST          (WLAST          ),
    .WVALID         (WVALID         ),
    .WREADY         (WREADY         ),

    // Write Response Signals
    .BREADY         (BREADY         ),         
    .BID            (BID            ),
    .BRESP          (BRESP          ),
    .BVALID         (BVALID         ),

    // Read Address Signals
    .ARID           (ARID           ), 
    .ARADDR         (ARADDR         ),
    .ARLEN          (ARLEN          ),
    .ARSIZE         (ARSIZE         ),
    .ARBURST        (ARBURST        ),  
    .ARLOCK         (ARLOCK         ),
    .ARCACHE        (ARCACHE        ),
    .ARPROT         (ARPROT         ),
    .ARQOS          (ARQOS          ),
    .ARREGION       (ARREGION       ),
    .ARVALID        (ARVALID        ),
    .ARREADY        (ARREADY        ),

    // Read Signals
    .RID            (RID            ), 
    .RDATA          (RDATA          ),
    .RRESP          (RRESP          ),
    .RLAST          (RLAST          ),
    .RVALID         (RVALID         ),
    .RREADY         (RREADY         ),

    // Custom Signals
    .o_w_en         (i_w_en_p0      ),
    .o_w_addr       (i_w_addr_p0    ),
    .o_w_data       (i_w_data_p0    ),
    .o_r_en         (i_r_en_p0      ),
    .o_r_addr       (i_r_addr_p0    ),
    .i_r_data       (o_r_data_p0    ),
    .i_done         (o_done         )
);

dpbram # (
    .ADDR_BW        (S_ADDR_BW      ),
    .DATA_BW        (S_DATA_BW      )
) DPBRAM
(
    .clk            (ACLK           ),
    .rst_n          (ARESETn        ),

    .i_w_en_p0      (i_w_en_p0      ),
    .i_w_addr_p0    (i_w_addr_p0    ),
    .i_w_data_p0    (i_w_data_p0    ),
    .i_r_en_p0      (i_r_en_p0      ),
    .i_r_addr_p0    (i_r_addr_p0    ),
    .o_r_data_p0    (o_r_data_p0    ),

    .i_w_en_p1      (i_w_en_p1      ),
    .i_w_addr_p1    (i_w_addr_p1    ),
    .i_w_data_p1    (i_w_data_p1    ),
    .i_r_en_p1      (i_r_en_p1      ),
    .i_r_addr_p1    (i_r_addr_p1    ),
    .o_r_data_p1    (o_r_data_p1    )
);

conv_bram #
(
    .AXI_ADDR_BW    (S_ADDR_BW      ),
    .AXI_DATA_BW    (S_DATA_BW      )
) CONV
(
    .ACLK           (ACLK           ),
    .ARESETn        (ARESETn        ),

    .i_r_data       (o_r_data_p1    ),
    .o_r_addr       (i_r_addr_p1    ),
    .o_r_en         (i_r_en_p1      ),

    .o_w_data       (i_w_data_p1    ),
    .o_w_addr       (i_w_addr_p1    ),
    .o_w_en         (i_w_en_p1      ),

    .i_w_done       (i_w_done       ),
    .o_done         (o_done         )
);


endmodule
