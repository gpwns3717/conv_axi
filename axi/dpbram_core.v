module dpbram_core #(
    parameter integer ADDR_BW = 8
) (
    input wire clk,

    // Port 0
    input  wire                 i_w_en_p0,
    input  wire [          7:0] i_w_data_p0,
    input  wire [ADDR_BW-1 : 0] i_w_addr_p0,
    input  wire                 i_r_en_p0,
    input  wire [ADDR_BW-1 : 0] i_r_addr_p0,
    output reg  [          7:0] o_r_data_p0,

    // Port 1
    input  wire                 i_w_en_p1,
    input  wire [          7:0] i_w_data_p1,
    input  wire [ADDR_BW-1 : 0] i_w_addr_p1,
    input  wire                 i_r_en_p1,
    input  wire [ADDR_BW-1 : 0] i_r_addr_p1,
    output reg  [          7:0] o_r_data_p1

);

  localparam MEM_SIZE = 1 << ADDR_BW;

  reg [7:0] mem[0 : MEM_SIZE-1];

  always @(posedge clk) begin
    if ((i_w_en_p0 && i_w_en_p1) && (i_w_addr_p0 == i_w_addr_p1)) mem[i_w_addr_p0] <= i_w_data_p0;
    else begin
      if (i_w_en_p0) mem[i_w_addr_p0] <= i_w_data_p0;
      if (i_w_en_p1) mem[i_w_addr_p1] <= i_w_data_p1;
    end
  end

  always @(posedge clk) begin
    if (i_r_en_p0) begin
      if (i_w_en_p0 && (i_r_addr_p0 == i_w_addr_p0))  // Conflict Prevention
        o_r_data_p0 <= i_w_data_p0;
      else if (i_w_en_p1 && (i_r_addr_p0 == i_w_addr_p1)) o_r_data_p0 <= i_w_data_p1;
      else o_r_data_p0 <= mem[i_r_addr_p0];
    end
  end

  always @(posedge clk) begin
    if (i_r_en_p1) begin
      if (i_w_en_p0 && (i_r_addr_p1 == i_w_addr_p0))  // Conflict Prevention
        o_r_data_p1 <= i_w_data_p0;
      else if (i_w_en_p1 && (i_r_addr_p1 == i_w_addr_p1)) o_r_data_p1 <= i_w_data_p1;
      else o_r_data_p1 <= mem[i_r_addr_p1];
    end
  end
endmodule
