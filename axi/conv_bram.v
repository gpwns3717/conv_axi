`include "./conv_simple.v"
`include "./conv_ram_control.v"

module conv_bram #(
    parameter integer AXI_ADDR_BW = 8,
    parameter integer AXI_DATA_BW = 32
) (
    input wire ACLK,
    input wire ARESETn,

    input  wire [AXI_DATA_BW-1:0] i_r_data,
    output wire [AXI_ADDR_BW-1:0] o_r_addr,
    output wire                   o_r_en,

    output wire [AXI_DATA_BW-1:0] o_w_data,
    output wire [AXI_ADDR_BW-1:0] o_w_addr,
    output wire                   o_w_en,

    input  wire i_w_done,
    output wire o_done
);

  localparam KERNEL_SIZE = 5, WEIGHT_BW = 8, DATA_BW = 8, ADDR_BW = 5, SUM_BW = 16, KERNEL_BW = 5, DATA_SIZE = 32, STRIDE = 1, DEPTH_WIDTH = 6, DEPTH_BW = 3;

  wire signed [  DATA_BW-1 : 0] w_x;
  wire signed [WEIGHT_BW-1 : 0] w_w;
  wire        [  ADDR_BW-1 : 0] w_addr;
  wire                          w_w_en;
  wire                          w_i_valid;

  wire signed [   SUM_BW-1 : 0] w_y;
  wire                          w_valid;

  conv_simple #(
      .WEIGHT_BW  (WEIGHT_BW),
      .DATA_BW    (DATA_BW),
      .ADDR_BW    (ADDR_BW),
      .SUM_BW     (SUM_BW),
      .KERNEL_BW  (KERNEL_BW),
      .KERNEL_SIZE(KERNEL_SIZE),
      .DATA_SIZE  (DATA_SIZE),
      .STRIDE     (STRIDE)
  ) CONV (
      .clk    (ACLK),
      .rst_n  (ARESETn),
      .i_x    (w_x),
      .i_w    (w_w),
      .i_addr (w_addr),
      .i_w_en (w_w_en),
      .i_valid(w_i_valid),
      .o_y    (w_y),
      .o_valid(w_valid)
  );

  conv_ram_control #(
      .AXI_ADDR_BW(AXI_ADDR_BW),
      .AXI_DATA_BW(AXI_DATA_BW),
      .KERNEL_SIZE(KERNEL_SIZE),
      .DATA_BW    (DATA_BW),
      .WEIGHT_BW  (WEIGHT_BW),
      .ADDR_BW    (ADDR_BW),
      .SUM_BW     (SUM_BW),
      .DEPTH_WIDTH(DEPTH_WIDTH),
      .DEPTH_BW   (DEPTH_BW),
      .DATA_SIZE  (DATA_SIZE)
  ) CONV_RAM (
      .ACLK   (ACLK),
      .ARESETn(ARESETn),

      .i_w_done(i_w_done),
      .o_done  (o_done),

      .i_r_data(i_r_data),
      .o_r_addr(o_r_addr),
      .o_r_en  (o_r_en),
      .o_w_data(o_w_data),
      .o_w_addr(o_w_addr),
      .o_w_en  (o_w_en),

      .o_x      (w_x),
      .o_w      (w_w),
      .o_addr   (w_addr),
      .o_w_valid(w_w_en),
      .o_valid  (w_i_valid),
      .i_y      (w_y),
      .i_valid  (w_valid)

  );

endmodule
