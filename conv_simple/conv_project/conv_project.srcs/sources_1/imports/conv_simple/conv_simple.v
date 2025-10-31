`timescale 1ns/10ps

module conv_simple #
(
    parameter integer KERNEL_SIZE   = 5,
    parameter integer WEIGHT_BW     = 8,
    parameter integer DATA_BW       = 8,
    parameter integer ADDR_BW       = 5,
    parameter integer SUM_BW        = 16,
    parameter integer KERNEL_BW     = 5,
    parameter integer DATA_SIZE     = 32,
    parameter integer STRIDE        = 1
)
(
	input	wire		            clk,
	input	wire		            rst_n,
	input	wire [DATA_BW-1 : 0] 	i_x,
	input	wire [WEIGHT_BW-1 : 0]	i_w,
	input	wire [ADDR_BW-1 : 0]	i_addr,
	input	wire		            i_w_en,
    input   wire                    i_valid,
	output	wire [SUM_BW-1 : 0]     o_y,
	output	wire		            o_valid
);

localparam DELAY_NB     = DATA_SIZE - KERNEL_SIZE,
           DELAY_NB_CON = DELAY_NB*(KERNEL_SIZE-1) + KERNEL_SIZE**2;

wire signed [SUM_BW-1 : 0]      w_psum[0:KERNEL_SIZE-2];
wire signed [SUM_BW-1 : 0]      w_psum_d[0:KERNEL_SIZE-2];
wire signed [DATA_BW - 1 : 0]   w_x;
wire signed [SUM_BW - 1 : 0]    w_y;
wire                            w_valid;

assign o_y = o_valid ? w_y : 0;

data_preprocessing # (
    .DATA_BW        (DATA_BW        )
) PREPROCESSING
(
    .clk            (clk            ),
    .rst_n          (rst_n          ),
    .i_x            (i_x            ),

    // output
    .o_x_d          (w_x            )
);

genvar i;
generate
    for (i = 0; i < KERNEL_SIZE; i=i+1) begin : CONV_SINGLE
        if (i == 0) begin
            conv_single_row # (
                .KERNEL_SIZE    (KERNEL_SIZE    ),
                .WEIGHT_BW      (WEIGHT_BW      ),
                .DATA_BW        (DATA_BW        ),
                .SUM_BW         (SUM_BW         ),
                .ADDR_BW        (ADDR_BW        ),
                .CONV_ADDR      (i              )
            ) conv_single
            (
                .clk            (clk            ),
                .rst_n          (rst_n          ),
                .i_w_en         (i_w_en         ),
                .i_addr         (i_addr         ),
                .i_x            (w_x            ),
                .i_psum         ({SUM_BW{1'b0}} ),
                .i_w            (i_w            ),
                
                //output
                .o_psum         (w_psum[i]      )
            );
            delay # (
                .DELAY_NB       (DELAY_NB       ),
                .SUM_BW         (SUM_BW         )
            ) DLY
            (
                .clk            (clk            ),
                .rst_n          (rst_n          ),
                .i_psum         (w_psum[i]      ),
                
                // output
                .o_psum         (w_psum_d[i]    )
            );
        end
        else if (i == KERNEL_SIZE-1) begin
            conv_single_row # (
                .KERNEL_SIZE    (KERNEL_SIZE    ),
                .WEIGHT_BW      (WEIGHT_BW      ),
                .DATA_BW        (DATA_BW        ),
                .SUM_BW         (SUM_BW         ),
                .ADDR_BW        (ADDR_BW        ),
                .CONV_ADDR      (i              )
            ) conv_single
            (
                .clk            (clk            ),
                .rst_n          (rst_n          ),
                .i_w_en         (i_w_en         ),
                .i_x            (w_x            ),
                .i_addr         (i_addr         ),
                .i_psum         (w_psum_d[i-1]  ),
                .i_w            (i_w            ),
                
                //output
                .o_psum         (w_y            )
            );
        end
        else begin
            conv_single_row # (
                .KERNEL_SIZE    (KERNEL_SIZE    ),
                .WEIGHT_BW      (WEIGHT_BW      ),
                .DATA_BW        (DATA_BW        ),
                .SUM_BW         (SUM_BW         ),
                .ADDR_BW        (ADDR_BW        ),
                .CONV_ADDR      (i              )
            ) conv_single
            (
                .clk            (clk            ),
                .rst_n          (rst_n          ),
                .i_w_en         (i_w_en         ),
                .i_x            (w_x            ),
                .i_addr         (i_addr         ),
                .i_psum         (w_psum_d[i-1]  ),
                .i_w            (i_w            ),
                
                //output
                .o_psum         (w_psum[i]      )
            );
            delay # (
                .DELAY_NB       (DELAY_NB       ),
                .SUM_BW         (SUM_BW         )
            ) DLY
            (
                .clk            (clk            ),
                .rst_n          (rst_n          ),
                .i_psum         (w_psum[i]      ),
                
                // output
                .o_psum         (w_psum_d[i]    )
            );
        end
    end
endgenerate

control_unit # (
    .DATA_SIZE      (DATA_SIZE      ),
    .KERNEL_SIZE    (KERNEL_SIZE    ),
    .KERNEL_BW      (KERNEL_BW      ),
    .STRIDE         (STRIDE         )
) CONTROL
(
    .clk            (clk            ),
    .rst_n          (rst_n          ),
    .i_valid        (i_valid        ),
    .o_valid        (w_valid        )
);

delay # (
    .DELAY_NB       (DELAY_NB_CON   ),
    .SUM_BW         (1'b1           )
) DLY_CON
(
    .clk            (clk            ),
    .rst_n          (rst_n          ),
    .i_psum         (w_valid        ),
    .o_psum         (o_valid        )
);

endmodule
