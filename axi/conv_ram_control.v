module conv_ram_control #(
    parameter integer AXI_ADDR_BW = 12,
    parameter integer AXI_DATA_BW = 12,
    parameter integer KERNEL_SIZE = 5,
    parameter integer DATA_BW     = 8,
    parameter integer WEIGHT_BW   = 8,
    parameter integer ADDR_BW     = 5,
    parameter integer SUM_BW      = 16,
    parameter integer DEPTH_WIDTH = 6,
    parameter integer DEPTH_BW    = 3,
    parameter integer DATA_SIZE   = 32
) (
    input ACLK,
    input ARESETn,

    input  wire i_w_done,
    output reg  o_done,

    // read weight and data signal
    input  wire [AXI_DATA_BW-1:0] i_r_data,
    output reg  [AXI_ADDR_BW-1:0] o_r_addr,
    output reg                    o_r_en,
    output reg  [AXI_DATA_BW-1:0] o_w_data,
    output reg  [AXI_ADDR_BW-1:0] o_w_addr,
    output reg                    o_w_en,

    // using conv signal
    output reg                  o_valid,
    output reg                  o_w_valid,
    output reg  [  DATA_BW-1:0] o_x,
    output reg  [WEIGHT_BW-1:0] o_w,
    output reg  [  ADDR_BW-1:0] o_addr,
    input  wire [   SUM_BW-1:0] i_y,
    input  wire                 i_valid
);

  localparam IDLE = 3'b000, ADDR_ACCESS = 3'b001, READ_WEIGHT = 3'b010, PROCESSING = 3'b011, DONE = 3'b100;

  reg [AXI_ADDR_BW-1:0] c_r_waddr;
  reg [AXI_ADDR_BW-1:0] c_r_xaddr;
  reg [AXI_ADDR_BW-1:0] c_w_yaddr;
  reg [9:0] data_cnt;
  reg [DEPTH_BW-1:0] depth_cnt;
  reg [7:0] done_cnt;

  reg [2:0] c_state;
  always @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      c_state <= IDLE;
    end else begin
      case (c_state)
        IDLE: begin
          if (i_w_done) begin
            c_state <= ADDR_ACCESS;
          end else begin
            c_state <= IDLE;
          end
        end

        ADDR_ACCESS: begin
          c_state <= READ_WEIGHT;
        end

        READ_WEIGHT: begin
          if (o_addr < KERNEL_SIZE ** 2 - 1) begin
            c_state <= READ_WEIGHT;
          end else begin
            c_state <= PROCESSING;
          end
        end

        PROCESSING: begin
          if (depth_cnt <= DEPTH_WIDTH - 1) begin
            if (data_cnt < DATA_SIZE ** 2 - 1) c_state <= PROCESSING;
            else c_state <= ADDR_ACCESS;
          end else begin
            if (data_cnt < DATA_SIZE ** 2 - 1) begin
              c_state <= PROCESSING;
            end else begin
              c_state <= DONE;
            end
          end
        end

        DONE: begin
          c_state <= DONE;
        end
      endcase
    end
  end

  always @(*) begin
    o_r_addr = 0;
    o_r_en   = 1'b0;
    case (c_state)
      IDLE: begin
        o_r_addr = 0;
        o_r_en   = 1'b0;
      end

      ADDR_ACCESS: begin
        o_r_addr = c_r_waddr;
        o_r_en   = 1'b1;
      end

      READ_WEIGHT: begin
        if (o_addr < KERNEL_SIZE ** 2 - 1) begin
          o_r_addr = c_r_waddr;
          o_r_en   = 1'b1;
        end else begin
          o_r_addr = c_r_xaddr;
          o_r_en   = 1'b1;
        end
      end

      PROCESSING: begin
        if (data_cnt <= DATA_SIZE ** 2 - 1) begin
          o_r_addr = c_r_xaddr;
          o_r_en   = 1'b1;
        end
      end

      DONE: begin
        o_r_en   = 1'b0;
        o_r_addr = o_r_addr;
      end
    endcase
  end

  always @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      o_addr <= 0;
    end else if (c_state == READ_WEIGHT) begin
      o_addr <= o_addr + 1'b1;
    end else begin
      o_addr <= 0;
    end
  end

  always @(*) begin
    if (c_state == READ_WEIGHT) begin
      o_w       = i_r_data[WEIGHT_BW-1:0];
      o_w_valid = 1'b1;
    end else begin
      o_w       = 0;
      o_w_valid = 1'b0;
    end
  end

  always @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      data_cnt <= 0;
    end else if (c_state == PROCESSING) begin
      o_x <= i_r_data[DATA_BW-1:0];
      if (data_cnt < DATA_SIZE ** 2) begin
        data_cnt <= data_cnt + 1'b1;
      end else begin
        data_cnt <= 0;
      end
    end else data_cnt <= 0;
  end

  always @(*) begin
    if (c_state == PROCESSING) begin
      o_x     = i_r_data[DATA_BW-1:0];
      o_valid = 1'b1;
    end else begin
      o_x     = 0;
      o_valid = 1'b0;
    end
  end
  always @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) depth_cnt <= 0;
    else if (c_state == READ_WEIGHT) if (o_addr >= KERNEL_SIZE ** 2 - 1) depth_cnt <= depth_cnt + 1'b1;
  end

  always @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      c_r_waddr <= 0;
    end else if (c_state == READ_WEIGHT || c_state == ADDR_ACCESS) begin
      if (o_addr < KERNEL_SIZE ** 2 - 1) c_r_waddr <= c_r_waddr + 1;
      else c_r_waddr <= c_r_waddr;
    end
  end

  always @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      c_r_xaddr <= 160;
    end else if (c_state == READ_WEIGHT) begin
      if (o_addr < KERNEL_SIZE ** 2 - 1) begin
        c_r_xaddr <= 160;
      end else begin
        c_r_xaddr <= c_r_xaddr + 1'b1;
      end
    end else if (c_state == PROCESSING) begin
      c_r_xaddr <= c_r_xaddr + 1'b1;
    end
  end


  always @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      c_w_yaddr <= 1280;
    end else if (i_valid) begin
      c_w_yaddr <= c_w_yaddr + 2;
    end
  end

  always @(*) begin
    if (i_valid) begin
      o_w_en   = 1'b1;
      o_w_addr = c_w_yaddr;
      o_w_data = i_y;
    end else begin
      o_w_en   = 1'b0;
      o_w_addr = c_w_yaddr;
      o_w_data = 0;
    end
  end

  always @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      done_cnt <= 0;
      o_done   <= 0;
    end else if (c_state == DONE) begin
      if (done_cnt >= 133) begin
        o_done   <= 1'b1;
        done_cnt <= done_cnt;
      end else begin
        done_cnt <= done_cnt + 1;
      end
    end else begin
      done_cnt <= 0;
      o_done   <= 1'b0;
    end
  end
endmodule
