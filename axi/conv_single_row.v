<<<<<<< HEAD
`timescale 1ns/10ps
=======
`include "./processing_element.v"
`include "./saturation.v"
>>>>>>> axi/master

module conv_single_row #
(
    parameter integer KERNEL_SIZE   = 5,
    parameter integer WEIGHT_BW     = 8,
    parameter integer DATA_BW       = 8,
    parameter integer SUM_BW        = 16,
    parameter integer ADDR_BW       = 5,
    parameter integer CONV_ADDR     = 0
)
(
    input   wire                               clk,
    input   wire                               rst_n,
    input   wire                               i_w_en,
    input   wire signed [DATA_BW-1 : 0]        i_x,
    input   wire        [ADDR_BW-1 : 0]        i_addr,
    input   wire signed [SUM_BW-1:0]           i_psum,
    input   wire signed [WEIGHT_BW-1 : 0]      i_w,
    output  wire signed [SUM_BW-1 :0]          o_psum
);

wire signed [SUM_BW+KERNEL_SIZE-1 : 0] psum[0 : KERNEL_SIZE-1]; 

genvar i;

generate
    for (i = 0; i < KERNEL_SIZE; i=i+1) begin : PE
        if (i == 0) begin
            processing_element # (
                .WEIGHT_BW      (WEIGHT_BW              ),
                .DATA_BW        (DATA_BW                ),
                .SUM_BW         (SUM_BW+i               ),
                .ADDR_BW        (ADDR_BW                ),
                .ELEMENT_ADDR   (CONV_ADDR*KERNEL_SIZE+i)
            ) pe
            (
                // input
                .clk        (clk                        ),
                .rst_n      (rst_n                      ),
                .i_w_en     (i_w_en                     ),
                .i_addr     (i_addr                     ),
                .i_w        (i_w                        ),
                .i_x        (i_x                        ),
                .i_psum     (i_psum                     ),
                
                // output
                .o_psum     (psum[i]                    )
            );
        end
        else begin
            processing_element # (
                .WEIGHT_BW      (WEIGHT_BW              ),
                .DATA_BW        (DATA_BW                ),
                .SUM_BW         (SUM_BW+i               ),
                .ADDR_BW        (ADDR_BW                ),
                .ELEMENT_ADDR   (CONV_ADDR*KERNEL_SIZE+i)
            ) pe
            (
                // input
                .clk        (clk                        ),
                .rst_n      (rst_n                      ),
                .i_w_en     (i_w_en                     ),
                .i_addr     (i_addr                     ),
                .i_w        (i_w                        ),
                .i_x        (i_x                        ),
                .i_psum     (psum[i-1]                  ),
                
                // output
                .o_psum     (psum[i]                    )
            );
        end
    end
endgenerate

saturation # (
    .I_SUM_BW               (SUM_BW+KERNEL_SIZE     ),
    .O_SUM_BW               (SUM_BW                 )
) SAT
(
    // input
    .i_psum                 (psum[KERNEL_SIZE-1]    ),

    // output
    .o_psum                 (o_psum                 )
);

endmodule
