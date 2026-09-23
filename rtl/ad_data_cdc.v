//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2024/11/26 13:39:34
// Design Name:
// Module Name: ad_data_cdc
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


module ad_data_cdc
(
    input                       clk_adc,
    input                       clk_300M,

    input                       rst,

    //axi_stream
    input [127:0]               m0_axis_tdata,
    output reg                  m0_axis_tready,
    input                       m0_axis_tvalid,
    input [127:0]               m1_axis_tdata,
    output reg                  m1_axis_tready,
    input                       m1_axis_tvalid,

    output reg [255:0]          adc_cdc_dout
);

reg                     m0_axis_tvalid_r;
reg                     m1_axis_tvalid_r;

reg signed [15:0]              adc_data0_i;
reg signed [15:0]              adc_data1_i;
reg signed [15:0]              adc_data2_i;
reg signed [15:0]              adc_data3_i;
reg signed [15:0]              adc_data4_i;
reg signed [15:0]              adc_data5_i;
reg signed [15:0]              adc_data6_i;
reg signed [15:0]              adc_data7_i;

reg signed [15:0]              adc_data0_q;
reg signed [15:0]              adc_data1_q;
reg signed [15:0]              adc_data2_q;
reg signed [15:0]              adc_data3_q;
reg signed [15:0]              adc_data4_q;
reg signed [15:0]              adc_data5_q;
reg signed [15:0]              adc_data6_q;
reg signed [15:0]              adc_data7_q;

//fifo_ad_cdc
reg                     fifo_rdy_ad;
reg [11:0]              delay_cnt_ad;
wire [255:0]            fifo_ad_cdc_din;
wire [255:0]            fifo_adc_cdc_dout;

wire                    fifo_ad_cdc_wr_en;
(* MARK_DEBUG="true" *) reg                     fifo_ad_cdc_rd_en;
wire                    fifo_ad_cdc_full;
(* MARK_DEBUG="true" *) wire                    fifo_ad_cdc_empty;
(* MARK_DEBUG="true" *) wire                    fifo_ad_cdc_valid;
wire [3:0]              fifo_ad_cdc_rd_data_count;
wire                    fifo_ad_cdc_wr_rst_busy;
wire                    fifo_ad_cdc_rd_rst_busy;

// always @(posedge clk_adc) begin
//     if (rst) begin
//         delay_cnt_ad <='d0;
//     end
//     else if (delay_cnt_ad < 12'd4090) begin
//         delay_cnt_ad <= delay_cnt_ad + 1'b1;
//     end
//     else begin
//         delay_cnt_ad <= delay_cnt_ad;
//     end
// end

// always @(posedge clk_adc) begin
//     if (delay_cnt_ad == 12'd4090) begin
//         fifo_rdy_ad <= 1'b1;
//     end else begin
//         fifo_rdy_ad <= 1'b0;
//     end
// end

always @(posedge clk_300M) begin
    adc_data0_i <= fifo_adc_cdc_dout[15:0];
    adc_data1_i <= fifo_adc_cdc_dout[31:16];
    adc_data2_i <= fifo_adc_cdc_dout[47:32];
    adc_data3_i <= fifo_adc_cdc_dout[63:48];
    adc_data4_i <= fifo_adc_cdc_dout[79:64];
    adc_data5_i <= fifo_adc_cdc_dout[95:80];
    adc_data6_i <= fifo_adc_cdc_dout[111:96];
    adc_data7_i <= fifo_adc_cdc_dout[127:112];
    adc_data0_q <= fifo_adc_cdc_dout[143:128];
    adc_data1_q <= fifo_adc_cdc_dout[159:144];
    adc_data2_q <= fifo_adc_cdc_dout[175:160];
    adc_data3_q <= fifo_adc_cdc_dout[191:176];
    adc_data4_q <= fifo_adc_cdc_dout[207:192];
    adc_data5_q <= fifo_adc_cdc_dout[223:208];
    adc_data6_q <= fifo_adc_cdc_dout[239:224];
    adc_data7_q <= fifo_adc_cdc_dout[255:240];
end


always @(posedge clk_300M) begin
    adc_cdc_dout <= {adc_data7_q, adc_data7_i, adc_data6_q, adc_data6_i, adc_data5_q, adc_data5_i, adc_data4_q, adc_data4_i,
                     adc_data3_q, adc_data3_i, adc_data2_q, adc_data2_i, adc_data1_q, adc_data1_i, adc_data0_q, adc_data0_i};
end

always @(posedge clk_adc) begin
    if (rst) begin
        m0_axis_tready <= 1'b0;
        m1_axis_tready <= 1'b0;
    end else begin
        m0_axis_tready <= 1'b1;
        m1_axis_tready <= 1'b1;
    end
end

always @(posedge clk_adc) begin
    m0_axis_tvalid_r <= m0_axis_tvalid;
    m1_axis_tvalid_r <= m1_axis_tvalid;
end

assign fifo_ad_cdc_wr_en = (m0_axis_tvalid_r || m1_axis_tvalid_r) ? 1'b1 : 1'b0;
assign fifo_ad_cdc_din = {m1_axis_tdata, m0_axis_tdata};

fifo_generator_0 fifo_generator_ad_cdc_inst
(
  .rst          (rst),                      // input wire rst
  .wr_clk       (clk_adc),                  // input wire wr_clk
  .rd_clk       (clk_300M),                 // input wire rd_clk
  .din          (fifo_ad_cdc_din),          // input wire [255 : 0] din
  .wr_en        (fifo_ad_cdc_wr_en),        // input wire wr_en
  .rd_en        (fifo_ad_cdc_rd_en),        // input wire rd_en
  .dout         (fifo_adc_cdc_dout),         // output wire [255 : 0] dout
  .full         (fifo_ad_cdc_full),         // output wire full
  .empty        (fifo_ad_cdc_empty),        // output wire empty
  .valid        (fifo_ad_cdc_valid),        // output wire valid
  .rd_data_count(fifo_ad_cdc_rd_data_count),  // output wire [3 : 0] rd_data_count
  .wr_rst_busy  (fifo_ad_cdc_wr_rst_busy),  // output wire wr_rst_busy
  .rd_rst_busy  (fifo_ad_cdc_rd_rst_busy)   // output wire rd_rst_busy
);

always @(posedge clk_300M) begin
    if (rst)
        fifo_ad_cdc_rd_en <= 1'b0;
    else if (fifo_ad_cdc_rd_data_count > 1'b1)
        fifo_ad_cdc_rd_en <= 1'b1;
    else
        fifo_ad_cdc_rd_en <= 1'b0;

end

endmodule
