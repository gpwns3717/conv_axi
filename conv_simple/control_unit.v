`timescale 1ns/10ps

module control_unit #
(
   parameter integer DATA_SIZE       = 32,
   parameter integer KERNEL_SIZE     = 5,
   parameter integer KERNEL_BW       = 5,
   parameter integer STRIDE          = 1
)
(
    input   wire                    clk,
    input   wire                    rst_n,
    input   wire                    i_valid,
    output  reg                     o_valid
);

reg                   valid;
reg [KERNEL_BW-1 : 0] i, j;

always @(*) begin
    if (valid) begin
        o_valid <= 1'b0;
        if ((i+KERNEL_SIZE-1 < DATA_SIZE) && (j+KERNEL_SIZE-1 < DATA_SIZE)) begin
            if (i%STRIDE == 0 && j%STRIDE == 0) begin
                o_valid <= 1'b1;
            end
        end
    end
    else begin
        o_valid <= 1'b0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        valid   <= 0;
    end
    else if (i_valid) begin
        valid   <= i_valid;
    end
    else if (o_valid) begin
        valid   <= 0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        i   <= 0;   // x location
        j   <= 0;   // y location
    end
    else if (valid) begin
        if ((i == (DATA_SIZE-1) && j == (DATA_SIZE-1))) begin
            i   <= 0;
            j   <= 0;
        end
        else if (j == (DATA_SIZE-1)) begin
            i   <= i + 1;
            j   <= 0;
        end
        else begin
            i   <= i;
            j   <= j + 1;
        end
    end
end

endmodule
 
