`timescale 1ns/1ps
// Second RFDC path: one 16-bit I and Q sample per 200 MHz beat.
module ad_data_cdc (
    input wire clk_adc, clk_dac, arst_n,
    input wire [15:0] m0_axis_tdata, m1_axis_tdata,
    input wire m0_axis_tvalid, m1_axis_tvalid,
    output wire m0_axis_tready, m1_axis_tready,
    output wire [31:0] s_axis_tdata,
    output wire s_axis_tvalid,
    input wire s_axis_tready,
    output wire overflow, underflow
);
    wire adc_rst_n, dac_rst_n, wr_ready, rd_valid;
    wire [5:0] rd_level;
    reg started;
    reset_sync_n adc_reset (.clk(clk_adc), .arst_n(arst_n), .srst_n(adc_rst_n));
    reset_sync_n dac_reset (.clk(clk_dac), .arst_n(arst_n), .srst_n(dac_rst_n));
    assign m0_axis_tready = adc_rst_n && wr_ready && m1_axis_tvalid;
    assign m1_axis_tready = adc_rst_n && wr_ready && m0_axis_tvalid;
    complex_sample_async_fifo fifo_inst (
        .rst(!adc_rst_n), .wr_clk(clk_adc),
        .wr_valid(adc_rst_n && m0_axis_tvalid && m1_axis_tvalid),
        .wr_ready(wr_ready), .wr_data({m1_axis_tdata,m0_axis_tdata}),
        .rd_clk(clk_dac), .rd_valid(rd_valid),
        .rd_ready(dac_rst_n && started && s_axis_tready), .rd_data(s_axis_tdata),
        .rd_level(rd_level), .overflow(overflow), .underflow(underflow)
    );
    always @(posedge clk_dac) begin
        if (!dac_rst_n) started <= 1'b0;
        else if (rd_level >= 6'd4) started <= 1'b1;
    end
    assign s_axis_tvalid = dac_rst_n && started && rd_valid;
endmodule
