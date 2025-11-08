module processing_element #(
    parameter integer WEIGHT_BW    = 8,
    parameter integer DATA_BW      = 8,
    parameter integer SUM_BW       = 16,
    parameter integer ADDR_BW      = 5,
    parameter integer ELEMENT_ADDR = 0
) (
    input  wire                          clk,
    input  wire                          rst_n,
    input  wire                          i_w_en,
    input  wire        [  ADDR_BW-1 : 0] i_addr,
    input  wire signed [WEIGHT_BW-1 : 0] i_w,
    input  wire signed [  DATA_BW-1 : 0] i_x,
    input  wire signed [   SUM_BW-1 : 0] i_psum,
    output reg signed  [     SUM_BW : 0] o_psum
);

  reg signed [WEIGHT_BW-1 : 0] weight;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      weight <= 0;
    end else if (i_w_en) begin
      if (ELEMENT_ADDR == i_addr) begin
        weight <= i_w;
      end
    end
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      o_psum <= 0;
    end else begin
      o_psum <= i_psum + (weight * i_x);
    end
  end

endmodule

