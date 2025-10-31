`timescale 1ns/10ps

module tb_conv_simple;

localparam KERNEL_SIZE  = 5,
           WEIGHT_BW    = 8,
           DATA_BW      = 8,
           ADDR_BW      = 5,
           SUM_BW       = 16,
           KERNEL_BW    = 5,
           DATA_SIZE    = 32,
           STRIDE       = 1;

reg                             clk;
reg                             rst_n;
reg signed [DATA_BW-1 : 0]      i_x;
reg signed [WEIGHT_BW-1 : 0]    i_w;
reg        [ADDR_BW-1 : 0]      i_addr;
reg                             i_w_en;
reg                             i_valid;

// for output signal
wire signed [SUM_BW-1 : 0]      o_y;
wire                            o_valid;

integer fd_x, fd_w, fo;
integer h_x, h_w;
integer i, j;

conv_simple #
(   
    .WEIGHT_BW      (WEIGHT_BW      ),
    .DATA_BW        (DATA_BW        ),
    .ADDR_BW        (ADDR_BW        ),
    .SUM_BW         (SUM_BW         ),
    .KERNEL_BW      (KERNEL_BW      ),
    .KERNEL_SIZE    (KERNEL_SIZE    ),
    .DATA_SIZE      (DATA_SIZE      ),
    .STRIDE         (STRIDE         )
) TOP
(
    .clk            (clk            ),
    .rst_n          (rst_n          ),
    .i_x            (i_x            ),
    .i_w            (i_w            ),
    .i_addr         (i_addr         ),
    .i_w_en         (i_w_en         ),
    .i_valid        (i_valid        ),
    .o_y            (o_y            ),
    .o_valid        (o_valid        )
);

initial begin
$display("simulation start");
$dumpfile("output.vcd");
$dumpvars(0, tb_conv_simple);
end

initial begin
    fd_w    = $fopen("./testvector/w_in_1s.dat","r");
    fo      = $fopen("./testvector/y_rtl_1s.dat", "w");
    clk     = 0;
    rst_n   = 0;
    i_x     = 0;
    i_w     = 0;
    i_addr  = 0;
    i_w_en  = 0;
    i_valid = 0;
    
    @(posedge clk);
    #1 rst_n = 1;
    @(posedge clk);
    #1 i_valid = 1;
       i_w_en = 1;
       for(j=0; j<6; j=j+1) begin
           fd_x = $fopen("./testvector/x_in_1s.dat","r");
           for(i=0; i<1024; i=i+1) begin 
               if(i<=24) begin
                #1 i_w_en = 1;
                   i_addr = i;
                   h_w = $fscanf(fd_w, "%d\n", i_w);
                   h_x = $fscanf(fd_x, "%d\n", i_x);
               end
               else begin
                #1 i_w_en = 0;
                   i_addr = 0;
                   i_w = 0;
                   h_x = $fscanf(fd_x, "%d\n", i_x);
               end
               @(posedge clk);
           end
       end
       repeat(3)@(posedge clk);
       i_valid = 0;
       repeat(10) @(posedge clk);
       $fclose(fd_x);
       $fclose(fd_w);
       $fclose(fo);
       $finish;

end

always #5 clk = ~clk;

always@(posedge clk) begin
    if(o_valid) begin
        $fwrite(fo,"%0d\n", o_y);
    end
end

endmodule
