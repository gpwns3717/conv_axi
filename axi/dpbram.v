`include "./dpbram_core.v"

module dpbram #(
    parameter integer ADDR_BW = 10,
    parameter integer DATA_BW = 32
) (
    input wire clk,
    input wire rst_n,

    input  wire                 i_w_en_p0,
    input  wire [ADDR_BW-1 : 0] i_w_addr_p0,
    input  wire [DATA_BW-1 : 0] i_w_data_p0,
    input  wire                 i_r_en_p0,
    input  wire [ADDR_BW-1 : 0] i_r_addr_p0,
    output wire [DATA_BW-1 : 0] o_r_data_p0,

    input  wire                 i_w_en_p1,
    input  wire [ADDR_BW-1 : 0] i_w_addr_p1,
    input  wire [DATA_BW-1 : 0] i_w_data_p1,
    input  wire                 i_r_en_p1,
    input  wire [ADDR_BW-1 : 0] i_r_addr_p1,
    output wire [DATA_BW-1 : 0] o_r_data_p1
);

  localparam BYTE_OFFSET = clogb2(DATA_BW / 8);

  wire [DATA_BW-1 : 0] w_r_data_p0, w_r_data_p1;
  wire [DATA_BW-1 : 0] w_w_data_p0, w_w_data_p1;
  reg [BYTE_OFFSET-1:0] p0_r_offset, p1_r_offset;

  assign o_r_data_p0 = w_r_data_p0 >> (p0_r_offset * 8);
  assign o_r_data_p1 = w_r_data_p1 >> (p1_r_offset * 8);

  always @(posedge clk) begin
    if (!rst_n) begin
      p0_r_offset <= 0;
      p1_r_offset <= 0;
    end else begin
      p0_r_offset <= i_r_addr_p0[BYTE_OFFSET-1:0];
      p1_r_offset <= i_r_addr_p1[BYTE_OFFSET-1:0];
    end
  end

  wire [DATA_BW/8-1:0] p0_w_offset = {(DATA_BW / 8) {1'b1}} << i_w_addr_p0[BYTE_OFFSET-1:0];
  wire [DATA_BW/8-1:0] p1_w_offset = {(DATA_BW / 8) {1'b1}} << i_w_addr_p1[BYTE_OFFSET-1:0];

  assign w_w_data_p0 = i_w_data_p0 << (i_w_addr_p0[BYTE_OFFSET-1:0] * 8);
  assign w_w_data_p1 = i_w_data_p1 << (i_w_addr_p1[BYTE_OFFSET-1:0] * 8);

  genvar i;
  generate
    for (i = 0; i < DATA_BW / 8; i = i + 1) begin : BRAM_CORE
      dpbram_core #(
          .ADDR_BW(ADDR_BW - BYTE_OFFSET)
      ) DPBRAM_CORE (
          .clk        (clk),
          .i_w_en_p0  (i_w_en_p0 & p0_w_offset[i]),
          .i_w_addr_p0(i_w_addr_p0[ADDR_BW-1:BYTE_OFFSET]),
          .i_w_data_p0(w_w_data_p0[i*8+7:i*8]),
          .i_r_en_p0  (i_r_en_p0),
          .i_r_addr_p0(i_r_addr_p0[ADDR_BW-1:BYTE_OFFSET]),
          .o_r_data_p0(w_r_data_p0[i*8+7:i*8]),

          .i_w_en_p1  (i_w_en_p1 & p1_w_offset[i]),
          .i_w_addr_p1(i_w_addr_p1[ADDR_BW-1:BYTE_OFFSET]),
          .i_w_data_p1(w_w_data_p1[i*8+7:i*8]),
          .i_r_en_p1  (i_r_en_p1),
          .i_r_addr_p1(i_r_addr_p1[ADDR_BW-1:BYTE_OFFSET]),
          .o_r_data_p1(w_r_data_p1[i*8+7:i*8])
      );
    end
  endgenerate

  function integer clogb2;
    input [31:0] value;
    begin
      value = value - 1;
      for (clogb2 = 0; value > 0; clogb2 = clogb2 + 1) begin
        value = value >> 1;
      end
    end
  endfunction

endmodule
