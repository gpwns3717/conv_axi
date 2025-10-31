`timescale 1ns/10ps

module saturation #
(
    parameter integer I_SUM_BW  = 21,
    parameter integer O_SUM_BW  = 16
)
(
    input   wire  signed    [I_SUM_BW - 1 : 0] i_psum,
    output  reg   signed    [O_SUM_BW - 1 : 0] o_psum
);

always @(*) begin
    if (i_psum[I_SUM_BW-1] == 0) begin                       // if i_psum >= 0
        if (i_psum >= {1'b0, {(O_SUM_BW-1){1'b1}}}) begin    // if i_psum is over the threshold
            o_psum  = {1'b0, {(O_SUM_BW-1){1'b1}}};          // It vaule is cliped.
        end
        else begin
            o_psum  = i_psum;
        end
    end
    else begin                                               // if i_psum < 0
        if (i_psum <= {1'b1, {(O_SUM_BW-1){1'b0}}}) begin    // if i_psum is under the threshold
            o_psum  = {1'b1, {(O_SUM_BW-1){1'b0}}};          // It value is cliped.
        end
        else begin
            o_psum  = i_psum;
        end
    end
end
endmodule
