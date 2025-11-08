module delay #(
    parameter integer DELAY_NB = 27,
    parameter integer SUM_BW   = 16
) (
    input  wire                         clk,
    input  wire                         rst_n,
    input  wire signed [SUM_BW - 1 : 0] i_psum,
    output wire signed [SUM_BW - 1 : 0] o_psum
);

  reg signed [SUM_BW - 1 : 0] buffer[0 : DELAY_NB-1];

  assign o_psum = buffer[DELAY_NB-1];

  genvar i;

  generate
    for (i = 0; i < DELAY_NB; i = i + 1) begin : sum_d
      if (i == 0) begin
        always @(posedge clk or negedge rst_n) begin
          if (!rst_n) begin
            buffer[i] <= 0;
          end else begin
            buffer[i] <= i_psum;
          end
        end
      end else begin
        always @(posedge clk or negedge rst_n) begin
          if (!rst_n) begin
            buffer[i] <= 0;
          end else begin
            buffer[i] <= buffer[i-1];
          end
        end
      end
    end
  endgenerate

endmodule
