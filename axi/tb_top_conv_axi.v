`timescale 1ns/10ps
`include "top_conv_axi.v"

module tb_top_conv_axi; 

localparam OKAY     = 2'b00,
           EXOKAY   = 2'b01,
           SLVERR   = 2'b10,
           DECERR   = 2'b11;

localparam integer   KERNEL_SIZE   = 5,
                     WEIGHT_BW     = 8,
                     DATA_BW       = 8,
                     ADDR_BW       = 5,
                     SUM_BW        = 16,
                     KERNEL_BW     = 5,
                     DATA_SIZE     = 32,
                     STRIDE        = 1,
                     AXI_ID_BW     = 10,
                     AXI_CID_BW    = 0,
                     AXI_SID_BW    = (AXI_ID_BW+AXI_CID_BW),
                     AXI_ADDR_BW   = 16,
                     AXI_DATA_BW   = 32,
                     AXI_STRB_BW   = (AXI_DATA_BW/8);
                 
reg     ACLK, ARESETn;

reg [AXI_SID_BW-1 : 0]      AWID;
reg [AXI_ADDR_BW-1 : 0]     AWADDR;
reg [7:0]                   AWLEN;    // axi4
reg [2:0]                   AWSIZE;
reg [1:0]                   AWBURST;
reg                         AWLOCK;   // axi4
reg [3:0]                   AWCACHE;
reg [2:0]                   AWPROT;
reg [3:0]                   AWQOS;
reg [3:0]                   AWREGION;
reg                         AWVALID;
wire                        AWREADY;

reg [AXI_DATA_BW-1 : 0]     WDATA;
reg [AXI_STRB_BW-1 : 0]     WSTRB;
reg                         WLAST;
reg                         WVALID;
wire                        WREADY;

reg                         BREADY;
wire [AXI_SID_BW-1 : 0]     BID;
wire [2:0]                  BRESP;
wire                        BVALID;

reg [AXI_SID_BW-1 : 0]      ARID;
reg [AXI_ADDR_BW-1 : 0]     ARADDR;
reg [7:0]                   ARLEN;           // axi4
reg [2:0]                   ARSIZE;
reg [1:0]                   ARBURST;
reg                         ARLOCK;         // axi4
reg [3:0]                   ARCACHE;
reg [2:0]                   ARPROT;
reg [3:0]                   ARQOS;
reg [3:0]                   ARREGION;
reg                         ARVALID;
wire                        ARREADY;

wire [AXI_SID_BW-1 : 0]     RID;
wire [AXI_DATA_BW-1 : 0]    RDATA;
wire [2:0]                  RRESP;
wire                        RLAST;
wire                        RVALID;
reg                         RREADY;
wire o_done;
reg i_w_done;

integer fo;
top_conv_axi # (
    .KERNEL_SIZE    (KERNEL_SIZE    ),
    .WEIGHT_BW      (WEIGHT_BW      ),
    .DATA_BW        (DATA_BW        ),
    .ADDR_BW        (ADDR_BW        ),
    .SUM_BW         (SUM_BW         ),
    .KERNEL_BW      (KERNEL_BW      ),
    .DATA_SIZE      (DATA_SIZE      ),
    .STRIDE         (STRIDE         ),
    .S_ID_BW        (AXI_ID_BW      ),
    .S_CID_BW       (AXI_CID_BW     ),
    .S_SID_BW       (AXI_SID_BW     ),
    .S_ADDR_BW      (AXI_ADDR_BW    ),
    .S_DATA_BW      (AXI_DATA_BW    ),
    .S_STRB_BW      (AXI_STRB_BW    )
) U_TOP_AXI 
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

    .o_done         (o_done         ),
    .i_w_done       (i_w_done       )
);


task read_address;
    input   [AXI_SID_BW - 1 : 0]    arid;
    input   [AXI_ADDR_BW - 1 : 0]   araddr;
    input   [8:0]                   arlen;
    input   [2:0]                   arsize;
    input   [1:0]                   arburst;
    begin
        @(posedge ACLK);
        ARVALID     <= #1 1;
        ARID        <= #1 arid;
        ARADDR      <= #1 araddr;
        ARLEN       <= #1 arlen - 1;
        ARSIZE      <= #1 arsize;
        ARBURST     <= #1 arburst;

        ARLOCK      <= #1 0;
        ARPROT      <= #1 0;
        ARCACHE     <= #1 0;
        ARREGION    <= #1 0;
        ARQOS       <= #1 0;

        @(posedge ACLK);
        while (ARREADY == 1'b0) @(posedge ACLK);
        ARVALID     <= #1 0;
        @(negedge ACLK);
    end
endtask

task read_data;
    input         [AXI_SID_BW - 1 : 0]    arid;
    input         [8:0]                   arlen;
    reg signed    [SUM_BW - 1 : 0]        data0, data1;
    integer i;
    begin
        @(posedge ACLK); 
        RREADY <= #1 1'b1;
        for (i = 0; i < arlen; i=i+1) begin
            @(posedge ACLK);
            while(RVALID == 1'b0) @(posedge ACLK);
            data0 = RDATA[SUM_BW-1:0];
            data1 = RDATA[SUM_BW*2-1:SUM_BW];
            $display($time, " id : %d, burst_num : %d, %0d, %0d", arid, i, data0, data1);
            $fwrite(fo, "%0d\n", data0);
            $fwrite(fo, "%0d\n", data1);
            if (arid != RID) begin
                $display("Read ID miss Error");
            end
            if (i == arlen-1) begin
                if (RLAST == 1'b0) begin
                    $display("Read LAST miss Error");
                end
            end else begin
                @(negedge ACLK);
            end
        end
         RREADY <= #1 1'b0;
        @(negedge ACLK);
    end
endtask

task read_task;
    reg     [SUM_BW -1 : 0]         rdata;
    integer i;
    begin
        for (i = 0; i <12; i=i+1) begin
            fork
                read_address(i, (1280+196*4*i), 196, 3'b010, 2'b01);
                read_data(i, 196);
            join
        end
    end
endtask

task write_address;
    input      [AXI_SID_BW - 1 : 0]     awid;
    input      [AXI_ADDR_BW - 1 : 0]    awaddr;
    input      [8:0]                    awlen;
    input      [2:0]                    awsize;
    input      [1:0]                    awburst;
    begin
        @(posedge ACLK);
        AWVALID     <= #1 1;
        AWID        <= #1 awid;
        AWADDR      <= #1 awaddr; 
        AWLEN       <= #1 awlen-1;
        AWSIZE      <= #1 awsize; 
        AWBURST     <= #1 awburst;
        AWLOCK      <= #1 0;
        AWPROT      <= #1 0; 
        AWCACHE     <= #1 0;
        AWREGION    <= #1 0;
        AWQOS       <= #1 0;
        @(posedge ACLK);
        while(AWREADY == 1'b0) @(posedge ACLK);
        AWVALID     <=  #1 0;
        @(negedge ACLK);
    end

endtask

task write_data;
    input      [8:0]                    awlen;
    input      [31:0]                   fd;
    integer i, h;
    begin
        @(posedge ACLK);
        WVALID      <= #1 1;
        for (i = 0; i < awlen; i=i+1) begin
            h       <= #1 $fscanf(fd, "%d\n", WDATA[7:0]);
            h       <= #1 $fscanf(fd, "%d\n", WDATA[15:8]);
            h       <= #1 $fscanf(fd, "%d\n", WDATA[23:16]);
            h       <= #1 $fscanf(fd, "%d\n", WDATA[31:24]);
            WSTRB   <= #1 4'b1111;
            WLAST   <= #1 (i==(awlen-1));
            @(posedge ACLK);
            while(WREADY==1'b0) @(posedge ACLK);
        end
        WLAST       <= #1 0;
        WVALID      <= #1 0;
        @(negedge ACLK);
    end
endtask

task write_response;
    input [31:0]    awid;
    begin
        BREADY <= #1 1;
        @(posedge ACLK);
        while (BVALID == 1'b0) @(posedge ACLK);
        if (BID != awid)
            $display("Write ID miss Error");
        else
            case (BRESP)
                OKAY : $display("Write Okay");
                EXOKAY : $display("Write Exclusive Okay");
                SLVERR : $display("Slave Error");
                DECERR : $display("Decode Error");
            endcase
        BREADY <= #1 1'b0;
        @(negedge ACLK);
    end
endtask

task write_task;
    reg        [AXI_DATA_BW -1 : 0]     wdata;

    integer i, j, fd_w, fd_x;
    begin
        fd_w = $fopen("./testvector/w_in_1s.dat", "r");
        fd_x = $fopen("./testvector/x_in_1s.dat", "r");
        fork        
            write_address(0, 160, 256, 3'b010, 2'b01);
            write_data(256, fd_x);
            write_response(0);
        join
        fork
            write_address(1, 0, 38, 3'b010, 2'b01);
            write_data(38, fd_w);
            write_response(1);
        join
        @(posedge ACLK);
        i_w_done <= #1 1;
        @(posedge ACLK);
        i_w_done <= #1 0;
        $fclose(fd_x);
        $fclose(fd_w);
    end
endtask


initial begin
    fo = $fopen("./testvector/y_rtl_1s.dat", "w");
    ACLK = 0; ARESETn = 1;
    @(posedge ACLK); #1; ARESETn = 0;
    @(posedge ACLK); #1; ARESETn = 1;
    fork
        read_task();
        write_task();
    join
    wait(o_done == 1'b1);
    $fclose(fo);
    $finish;
end

always #5 ACLK = ~ACLK;
endmodule
