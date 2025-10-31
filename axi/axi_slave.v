module axi_slave #
(
    parameter integer       S_ID_BW     = 4,
    parameter integer       S_CID_BW    = 0,
    parameter integer       S_SID_BW    = (S_ID_BW+S_CID_BW),
    parameter integer       S_ADDR_BW   = 32,
    parameter integer       S_DATA_BW   = 32,
    parameter integer       S_STRB_BW   = (S_DATA_BW/8),
    parameter integer       S_BUS_BYTES = (S_DATA_BW/8)
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
    output  reg                         AWREADY,

    // Write Data Signals
    input   wire [S_DATA_BW-1 : 0]      WDATA,
    input   wire [S_STRB_BW-1 : 0]      WSTRB,
    input   wire                        WLAST,
    input   wire                        WVALID,
    output  reg                         WREADY,

    // Write Response Signals
    input   wire                        BREADY,
    output  reg [S_SID_BW-1 : 0]        BID,
    output  reg [2:0]                   BRESP,
    output  reg                         BVALID,

    // Read Address Signals
    input   wire [S_SID_BW-1 : 0]       ARID,
    input   wire [S_ADDR_BW-1 : 0]      ARADDR,
    input   wire [7:0]                  ARLEN,          // axi4
    input   wire [2:0]                  ARSIZE,
    input   wire [1:0]                  ARBURST,
    input   wire                        ARLOCK,         // axi4
    input   wire [3:0]                  ARCACHE,
    input   wire [2:0]                  ARPROT,
    input   wire [3:0]                  ARQOS,
    input   wire [3:0]                  ARREGION,
    input   wire                        ARVALID,
    output  reg                         ARREADY,

    // Read Signals
    input   wire                        RREADY,
    output  reg [S_SID_BW-1 : 0]        RID,
    output  reg [S_DATA_BW-1 : 0]       RDATA,
    output  reg [2:0]                   RRESP,
    output  reg                         RLAST,
    output  reg                         RVALID,

    // Custom Signals
    output  reg                         o_w_en,
    output  reg [S_ADDR_BW-1 : 0]       o_w_addr,
    output  reg [S_DATA_BW-1 : 0]       o_w_data,
    output  reg [S_STRB_BW-1 : 0]       o_w_strb,
    output  reg                         o_r_en,
    output  reg [S_ADDR_BW-1 : 0]       o_r_addr,
    input   wire [S_DATA_BW-1 : 0]      i_r_data,

    input   wire                        i_done
);

/******************** Parameter Definition  ********************/
localparam  W_IDLE = 2'd0,
            W_DATA = 2'd1,
            W_RESP = 2'd2;

localparam FIXED  = 2'b00,
           INCR   = 2'b01,
           WRAP   = 2'b10;

localparam OKAY   = 2'b00,
           EXOKAY = 2'b01,
           SLVERR = 2'b10,
           DECERR = 2'b11;

/******************** Write Operation  ********************/
reg [1:0]   c_wstate;
reg [S_SID_BW-1 : 0]    r_awid;
reg [S_ADDR_BW-1 : 0]   r_awaddr;
reg [8:0]               r_awlen;
reg [7:0]               r_awsize;
reg [1:0]               r_awburst;
reg                     r_awlock;
reg [3:0]               r_awcache;
reg [2:0]               r_awprot;
reg [3:0]               r_awqos;
reg [3:0]               r_awregion;

reg [7:0]               wbeats_cnt;

always @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
        c_wstate       <= W_IDLE;

        r_awid         <= 0;
        r_awaddr       <= 0;
        r_awsize       <= 0;
        r_awlen        <= 0;
        r_awburst      <= 0;
        r_awlock       <= 0;
        r_awcache      <= 0;
        r_awprot       <= 0;
        r_awqos        <= 0;
        r_awregion     <= 0;

        AWREADY        <= 1'b0;
        WREADY         <= 1'b0;
        BRESP          <= OKAY;
        BVALID         <= 1'b0;
        BID            <= 0;
    end else begin
        case (c_wstate)
            W_IDLE : begin
                if (AWVALID && AWREADY) begin
                    // information store
                    r_awid       <= AWID;
                    r_awaddr     <= AWADDR;
                    r_awlen      <= (AWLEN + 1);
                    r_awsize     <= (1<<AWSIZE);
                    r_awburst    <= AWBURST;
                    r_awlock     <= AWLOCK;
                    r_awcache    <= AWCACHE;
                    r_awprot     <= AWPROT;
                    r_awqos      <= AWQOS;
                    r_awregion   <= AWREGION;
                    
                    AWREADY      <= 1'b0;
                    c_wstate     <= W_DATA;
                end else
                    AWREADY      <= 1'b1;
            end

            W_DATA : begin
                if (WREADY && WVALID) begin
                    if (r_awlen-1 <= wbeats_cnt) begin
                        if (WLAST) 
                            BRESP  <= OKAY;
                        else
                            BRESP  <= SLVERR;

                        c_wstate   <= W_RESP;
                        WREADY     <= 1'b0;
                        BID        <= r_awid;
                    end
                end else begin
                    WREADY <= 1'b1;
                end
            end

            W_RESP : begin
                if (BREADY && BVALID) begin
                    BVALID     <= 1'b0;
                    AWREADY    <= 1'b1;
                    c_wstate   <= W_IDLE;
                end else
                    BVALID      <= 1'b1;
            end
        endcase
    end
end

// Beats Conunt
always @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn)
        wbeats_cnt   <= 0;
    else if (c_wstate != W_DATA)
        wbeats_cnt   <= 0;
    else 
        if (WVALID && WREADY) 
            wbeats_cnt   <= wbeats_cnt + 1'b1;
end

wire [11:0]            awblock_size          = r_awburst == WRAP ? r_awlen * r_awsize : 0;
wire [S_ADDR_BW-1 : 0] awlower_wrap_boundary = r_awburst == WRAP ? r_awaddr/awblock_size * awblock_size : 0,
                       awupper_wrap_boundary = r_awburst == WRAP ? awlower_wrap_boundary + awblock_size : 0;

reg  [S_ADDR_BW-1 : 0]  n_awaddr;
reg                     awaligned;
reg  [S_ADDR_BW-1 : 0]  awaligned_addr;

always @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
        n_awaddr                <= 0;
        awaligned_addr          <= 0;
        awaligned               <= 0;
    end else if (c_wstate == W_IDLE) begin
        if (AWVALID && AWREADY) begin
            n_awaddr            <= AWADDR;
            awaligned_addr      <= (AWADDR / (1 << AWSIZE)) * (1 << AWSIZE);
            awaligned           <= ((AWADDR / (1 << AWSIZE)) * (1 << AWSIZE) == AWADDR);
        end
    end else if (c_wstate == W_DATA) begin
        if (WVALID && WREADY) begin
            case (r_awburst)
                FIXED : n_awaddr      <= n_awaddr;
                INCR  : begin
                    if (awaligned) 
                        n_awaddr      <= n_awaddr + r_awsize; 
                    else begin
                        n_awaddr      <= awaligned_addr + r_awsize;
                        awaligned     <= 1'b1;
                    end
                end
                WRAP : begin
                    if (awaligned) begin
                        if (n_awaddr >= awupper_wrap_boundary)
                            n_awaddr  <= awlower_wrap_boundary;
                        else
                            n_awaddr  <= n_awaddr + r_awsize;
                    end else begin
                        n_awaddr      <= awaligned_addr + r_awsize;
                        awaligned     <= 1'b1;
                    end
                end
                default : n_awaddr    <= n_awaddr;
            endcase
        end
    end
end

// Custom Operation
always @(*) begin
    case(c_wstate)
        W_DATA : begin
            if (WVALID && WREADY) begin
                o_w_en      <= 1'b1;
                o_w_addr    <= n_awaddr;
                o_w_data    <= WDATA;
                o_w_strb    <= WSTRB;
            end else begin
                o_w_en      <= 1'b0;
                o_w_addr    <= 0;
                o_w_data    <= 0;
                o_w_strb    <= 0;
            end
        end

        default : begin
            o_w_en      <= 1'b0;
            o_w_addr    <= 0;
            o_w_data    <= 0;
            o_w_strb    <= 0;
        end
    endcase
end


/********************************************************/

/******************** Read Operation  ********************/
localparam R_IDLE   = 2'b00,
           R_ACCESS = 2'b01,
           R_DATA   = 2'b10;

reg [S_SID_BW-1 : 0]      r_arid;
reg [S_ADDR_BW-1 : 0]     r_araddr;
reg [8:0]                 r_arlen;
reg [7:0]                 r_arsize;
reg [1:0]                 r_arburst;
reg                       r_arlock;
reg [3:0]                 r_arcache;
reg [2:0]                 r_arprot;
reg [3:0]                 r_arqos;
reg [3:0]                 r_arregion;

reg [7:0]                 rbeats_cnt;
reg [1:0]                 c_rstate;

always @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
        r_arid         <= 0;
        r_araddr       <= 0;
        r_arlen        <= 0;
        r_arsize       <= 0;
        r_arburst      <= 0;
        r_arlock       <= 0;
        r_arcache      <= 0;
        r_arprot       <= 0;
        r_arqos        <= 0;
        r_arregion     <= 0;

        c_rstate       <= R_IDLE;
        ARREADY        <= 1'b0;
        RVALID         <= 1'b0;
        RLAST          <= 1'b0;
        RID            <= 0;
        RDATA          <= 0;
        RRESP          <= SLVERR;
    end
    case (c_rstate)
        R_IDLE : begin
            RLAST   <= 1'b0;
            RVALID  <= 1'b0;
            RID     <= 0;
            RRESP   <= SLVERR;
            if (ARVALID && ARREADY) begin
                r_arid     <= ARID;
                r_araddr   <= ARADDR;
                r_arlen    <= ARLEN + 1'b1;
                r_arsize   <= (1 << ARSIZE);
                r_arburst  <= ARBURST;
                r_arlock   <= ARLOCK;
                r_arcache  <= ARCACHE;
                r_arprot   <= ARPROT;
                r_arqos    <= ARQOS;
                r_arregion <= ARREGION;
                
                ARREADY    <= 1'b0;
                c_rstate   <= R_ACCESS;
            end else
                ARREADY    <= i_done;
        end

        R_ACCESS : begin
            c_rstate  <= R_DATA;
        end

        R_DATA : begin
            RID        <= r_arid;
            RDATA      <= i_r_data;
            RRESP      <= OKAY;
            if (RREADY && RVALID) begin
                RVALID     <= 1'b0;
                if (RLAST)
                    c_rstate   <= R_IDLE;
                else
                    c_rstate    <= R_DATA;
                if (rbeats_cnt < r_arlen-2) begin
                    RLAST      <= 1'b0;
                end else begin
                    RLAST      <= 1'b1;
                end
            end else 
                RVALID <= 1'b1;
        end
    endcase
end

always @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn)
        rbeats_cnt  <= 0;
    else if (c_rstate != R_DATA)
        rbeats_cnt  <= 0;
    else
        if (RREADY && RVALID)
            rbeats_cnt  <= rbeats_cnt + 1'b1;
end

wire [11:0]            arblock_size          = r_arburst == WRAP ? r_arlen * r_arsize : 0;
wire [S_ADDR_BW-1 : 0] arlower_wrap_boundary = r_arburst == WRAP ? r_araddr/arblock_size * arblock_size : 0,
                       arupper_wrap_boundary = r_arburst == WRAP ? arlower_wrap_boundary + arblock_size : 0;

reg  [S_ADDR_BW-1 : 0]  n_araddr;
reg                     araligned;
reg  [S_ADDR_BW-1 : 0]  araligned_addr;

always @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
        n_araddr                <= 0;
        araligned_addr          <= 0;
        araligned               <= 0;
    end else if (c_rstate == R_IDLE) begin
        if (ARVALID && ARREADY) begin
            n_araddr            <= ARADDR;
            araligned_addr      <= (ARADDR / (1 << ARSIZE)) * (1 << ARSIZE);
            araligned           <= ((ARADDR / (1 << ARSIZE)) * (1 << ARSIZE) == ARADDR);
        end
    end else begin
        if (RVALID && RREADY || (c_rstate == R_ACCESS)) begin
            case (r_arburst)
                FIXED : n_araddr      <= n_araddr;
                INCR  : begin
                    if (araligned) 
                        n_araddr      <= n_araddr + r_arsize;
                    else begin
                        n_araddr      <= araligned_addr + r_arsize;
                        araligned     <= 1'b1;
                    end
                end
                WRAP : begin
                    if (araligned) begin
                        if (n_araddr >= arupper_wrap_boundary)
                            n_araddr  <= arlower_wrap_boundary;
                        else
                            n_araddr  <= n_araddr + r_arsize;
                    end else begin
                        n_araddr      <= araligned_addr + r_arsize;
                        araligned     <= 1'b1;
                    end
                end
                default : n_araddr    <= n_araddr;
            endcase
        end
    end
end

always @(*) begin
    case (c_rstate)
        R_IDLE : begin
            if (ARADDR && ARVALID) begin
                o_r_addr    <= ARADDR;
                o_r_en      <= 1'b1;
            end else begin
                o_r_addr    <= 0;
                o_r_en      <= 1'b1;
            end
        end
        R_ACCESS : begin
            o_r_addr    <= n_araddr;
            o_r_en      <= 1'b1;
        end
        
        R_DATA : begin
            if (RVALID && RREADY) begin
                o_r_en  <= 1'b1;
                o_r_addr<= n_araddr;
            end else begin
                o_r_en  <= 1'b0;
                o_r_addr<= 0;
            end
        end

        default : begin
            o_r_en      <= 1'b0;
            o_r_addr    <= 0;
        end
    endcase
end

endmodule
