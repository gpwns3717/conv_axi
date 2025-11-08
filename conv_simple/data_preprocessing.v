`timescale 1ns / 10ps

module data_preprocessing #(
    parameter integer DATA_BW = 8
) (
    input  wire                          clk,
    input  wire                          rst_n,
    input  wire signed [DATA_BW - 1 : 0] i_x,
    output reg signed  [DATA_BW - 1 : 0] o_x_d
);

  // This 1 cycle latency is intend for temporal sync with kernel
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      o_x_d <= 0;
    end else begin
      o_x_d <= i_x;
    end
  end

endmodule
