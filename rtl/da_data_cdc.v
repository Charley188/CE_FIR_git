`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2026/04/20 16:02:34
// Design Name:
// Module Name: da_data_cdc
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module da_data_cdc
(
    input                   clk_dac,
    input                   clk_300M,

    input                   rst,

    input                   adc_cdc_tvalid,
    input [255:0]           adc_cdc_tdata,

    output reg [255:0]      s_axis_tdata,
    input                   s_axis_tready,
    output reg              s_axis_tvalid
);

//fifo_da_cdc
reg             fifo_rdy_da;
reg [11:0]      delay_cnt_da;

reg             fifo_da_cdc_wr_en;
(* MARK_DEBUG="true" *) reg             fifo_da_cdc_rd_en;
wire            fifo_da_cdc_full;
(* MARK_DEBUG="true" *) wire            fifo_da_cdc_empty;
wire            fifo_da_cdc_valid;
wire [3:0]      fifo_da_cdc_rd_data_count;
wire            fifo_da_cdc_wr_rst_busy;
wire            fifo_da_cdc_rd_rst_busy;
reg [255:0]     fifo_da_cdc_din;
wire [255:0]    fifo_da_cdc_dout;

//DAC_FIFO
always @(posedge clk_300M) begin
    if (rst) begin
        fifo_da_cdc_wr_en <= 1'b0;
        fifo_da_cdc_din <= 'd0;
    end
    else begin
        fifo_da_cdc_wr_en <= adc_cdc_tvalid;
        fifo_da_cdc_din <= adc_cdc_tdata;
    end

end

fifo_generator_0 fifo_generator_da_target_cdc_inst
(
  .rst          (rst),                      // input wire rst
  .wr_clk       (clk_300M),                 // input wire wr_clk
  .rd_clk       (clk_dac),                  // input wire rd_clk
  .din          (fifo_da_cdc_din),          // input wire [255 : 0] din
  .wr_en        (fifo_da_cdc_wr_en),        // input wire wr_en
  .rd_en        (fifo_da_cdc_rd_en),       // input wire rd_en
  .dout         (fifo_da_cdc_dout),         // output wire [255 : 0] dout
  .full         (fifo_da_cdc_full),         // output wire full
  .empty        (fifo_da_cdc_empty),        // output wire empty
  .valid        (fifo_da_cdc_valid),        // output wire valid
  .rd_data_count(fifo_da_cdc_rd_data_count),  // output wire [3 : 0] rd_data_count
  .wr_rst_busy  (fifo_da_cdc_wr_rst_busy),  // output wire wr_rst_busy
  .rd_rst_busy  (fifo_da_cdc_rd_rst_busy)   // output wire rd_rst_busy
);



always @(posedge clk_dac) begin
    if (rst)
        fifo_da_cdc_rd_en <= 1'b0;
    else if (fifo_da_cdc_rd_data_count > 1'b1)
        fifo_da_cdc_rd_en <= 1'b1;
    else
        fifo_da_cdc_rd_en <= 1'b0;

end

always @(posedge clk_dac) begin
    if (s_axis_tready) begin
        s_axis_tvalid <= fifo_da_cdc_valid;
        s_axis_tdata <= fifo_da_cdc_dout;
    end else begin
        s_axis_tvalid <= 1'b0;
        s_axis_tdata <= 'd0;
    end
end

endmodule
