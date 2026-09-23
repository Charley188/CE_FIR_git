`timescale 1ns / 1ps

module adda_first_path_chain (
    input  wire         clk_adc0,
    input  wire         clk_200m,
    input  wire         clk_dac0,
    input  wire         pl_rstn,
    input  wire         rf_adc_axis_rstn,
    input  wire         clk_200m_locked,
    input  wire         rf_dac_axis_rstn,
    input  wire [127:0] m00_axis_tdata,
    input  wire         m00_axis_tvalid,
    output wire         m00_axis_tready,
    input  wire [127:0] m01_axis_tdata,
    input  wire         m01_axis_tvalid,
    output wire         m01_axis_tready,
    output wire [255:0] s00_axis_tdata,
    output wire         s00_axis_tvalid,
    input  wire         s00_axis_tready,
    output wire         fifo_overflow,
    output wire         fifo_underflow
);

    wire chain_arst_n = pl_rstn & rf_adc_axis_rstn &
                        clk_200m_locked & rf_dac_axis_rstn;
    wire adc_rst_n;
    wire alg_rst_n;
    wire dac_rst_n;

    wire pair_valid = m00_axis_tvalid && m01_axis_tvalid;
    wire pair_ready;
    wire decimator_s_ready;
    wire decim_valid;
    wire decim_ready;
    wire [31:0] decim_data;
    wire fifo_rd_valid;
    wire fifo_rd_ready;
    wire [31:0] fifo_rd_data;
    wire [5:0] fifo_rd_level;
    wire fir_in_ready;
    reg fir_stream_started;
    wire cal_valid;
    wire cal_ready;
    wire [31:0] cal_data;
    wire interp_valid;
    wire interp_ready;
    wire [383:0] interp_data;
    wire block_fifo_valid;
    wire block_fifo_ready;
    wire [383:0] block_fifo_data;
    wire [255:0] gearbox_data;

    wire sample_fifo_overflow;
    wire sample_fifo_underflow;
    wire fir_fifo_overflow;
    wire fir_fifo_underflow;
    wire block_fifo_overflow;
    wire block_fifo_underflow;

    reset_sync_n adc_reset_sync_inst (
        .clk(clk_adc0), .arst_n(chain_arst_n), .srst_n(adc_rst_n)
    );

    reset_sync_n alg_reset_sync_inst (
        .clk(clk_200m), .arst_n(chain_arst_n), .srst_n(alg_rst_n)
    );

    reset_sync_n dac_reset_sync_inst (
        .clk(clk_dac0), .arst_n(chain_arst_n), .srst_n(dac_rst_n)
    );

    assign pair_ready = adc_rst_n && decimator_s_ready;
    assign m00_axis_tready = pair_ready && m01_axis_tvalid;
    assign m01_axis_tready = pair_ready && m00_axis_tvalid;

    rfdc_8lane_decimator12 decimator_inst (
        .clk(clk_adc0),
        .rst_n(adc_rst_n),
        .s_valid(pair_valid),
        .s_ready(decimator_s_ready),
        .s_i_tdata(m00_axis_tdata),
        .s_q_tdata(m01_axis_tdata),
        .m_valid(decim_valid),
        .m_ready(decim_ready),
        .m_data(decim_data)
    );

    complex_sample_async_fifo sample_fifo_inst (
        .rst(!adc_rst_n),
        .wr_clk(clk_adc0),
        .wr_valid(decim_valid),
        .wr_ready(decim_ready),
        .wr_data(decim_data),
        .rd_clk(clk_200m),
        .rd_valid(fifo_rd_valid),
        .rd_ready(fifo_rd_ready),
        .rd_data(fifo_rd_data),
        .rd_level(fifo_rd_level),
        .overflow(sample_fifo_overflow),
        .underflow(sample_fifo_underflow)
    );

    always @(posedge clk_200m) begin
        if (!alg_rst_n)
            fir_stream_started <= 1'b0;
        else if (!fir_stream_started && (fifo_rd_level >= 6'd4))
            fir_stream_started <= 1'b1;
    end
    assign fifo_rd_ready = fir_stream_started && fir_in_ready;

    complex_fir_stream_buffer fir_inst (
        .clk(clk_200m),
        .rst_n(alg_rst_n),
        .s_valid(fir_stream_started && fifo_rd_valid),
        .s_ready(fir_in_ready),
        .s_data(fifo_rd_data),
        .m_valid(cal_valid),
        .m_ready(cal_ready),
        .m_data(cal_data),
        .fifo_overflow_error(fir_fifo_overflow),
        .fifo_underflow_error(fir_fifo_underflow)
    );

    complex_interp12_top interpolation_inst (
        .clk(clk_200m),
        .rst_n(alg_rst_n),
        .s_valid(cal_valid),
        .s_ready(cal_ready),
        .s_data(cal_data),
        .m_valid(interp_valid),
        .m_ready(interp_ready),
        .m_data(interp_data)
    );

    complex_block_async_fifo block_fifo_inst (
        .rst(!alg_rst_n),
        .wr_clk(clk_200m),
        .wr_valid(interp_valid),
        .wr_ready(interp_ready),
        .wr_data(interp_data),
        .rd_clk(clk_dac0),
        .rd_valid(block_fifo_valid),
        .rd_ready(block_fifo_ready),
        .rd_data(block_fifo_data),
        .overflow(block_fifo_overflow),
        .underflow(block_fifo_underflow)
    );

    gearbox_12to8 gearbox_inst (
        .clk(clk_dac0),
        .rst(!dac_rst_n),
        .s_valid(block_fifo_valid),
        .s_ready(block_fifo_ready),
        .s_data(block_fifo_data),
        .m_valid(s00_axis_tvalid),
        .m_ready(s00_axis_tready),
        .m_data(gearbox_data)
    );

    assign s00_axis_tdata = gearbox_data;
    assign fifo_overflow = sample_fifo_overflow | fir_fifo_overflow |
                           block_fifo_overflow;
    assign fifo_underflow = sample_fifo_underflow | fir_fifo_underflow |
                            block_fifo_underflow;

endmodule
