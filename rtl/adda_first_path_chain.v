`timescale 1ns / 1ps

module adda_first_path_chain (
    input wire update_hold,coeff_we,
    input wire [10:0] coeff_addr,
    input wire [17:0] coeff_re,coeff_im,
    output wire coeff_match,load_quiet,path_running,reload_fault,
    input  wire         clk_adc0,
    input  wire         clk_200m,
    input  wire         clk_dac0,
    input  wire         pl_rstn,
    input  wire         rf_adc_axis_rstn,
    input  wire         clk_200m_locked,
    input  wire         rf_dac_axis_rstn,
    input  wire [15:0] m00_axis_tdata,
    input  wire         m00_axis_tvalid,
    output wire         m00_axis_tready,
    input  wire [15:0] m01_axis_tdata,
    input  wire         m01_axis_tvalid,
    output wire         m01_axis_tready,
    output wire [31:0] s00_axis_tdata,
    output wire         s00_axis_tvalid,
    input  wire         s00_axis_tready,
    output wire         fifo_overflow,
    output wire         fifo_underflow
);

    wire base_arst_n = pl_rstn & rf_adc_axis_rstn &
                        clk_200m_locked & rf_dac_axis_rstn;
    wire reload_running,ip_rst_n;
    wire [3:0] reload_valid,reload_ready,config_valid,config_ready,reload_missing,reload_unexpected;
    wire reload_last;
    wire [23:0] reload_re,reload_im;
    wire chain_arst_n=base_arst_n && reload_running && !update_hold;
    assign path_running=reload_running && alg_rst_n;
    ce_fir_reload reload_inst(
        .clk(clk_200m),.arst_n(base_arst_n),.update_hold(update_hold),
        .coeff_we(coeff_we),.coeff_addr(coeff_addr),.coeff_re(coeff_re),.coeff_im(coeff_im),
        .coeff_match(coeff_match),.load_quiet(load_quiet),.running(reload_running),.fault(reload_fault),
        .ip_rst_n(ip_rst_n),.reload_valid(reload_valid),.reload_ready(reload_ready),
        .reload_last(reload_last),.reload_re(reload_re),.reload_im(reload_im),
        .config_valid(config_valid),.config_ready(config_ready),
        .reload_missing(reload_missing),.reload_unexpected(reload_unexpected));
    wire adc_rst_n;
    wire alg_rst_n;
    wire dac_rst_n;

    wire pair_valid = m00_axis_tvalid && m01_axis_tvalid;
    wire pair_ready;
    wire adc_pair_ready;
    wire adc_pair_valid;
    wire adc_fifo_ready;
    wire [31:0] adc_pair_data;
    wire fifo_rd_valid;
    wire fifo_rd_ready;
    wire [31:0] fifo_rd_data;
    wire [5:0] fifo_rd_level;
    wire fir_in_ready;
    reg fir_stream_started;
    wire cal_valid;
    wire cal_ready;
    wire [31:0] cal_data;
    wire dac_fifo_valid;
    wire [31:0] dac_fifo_data;
    wire [5:0] dac_fifo_level;
    reg dac_started;
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

    assign pair_ready = adc_rst_n && adc_pair_ready;
    assign m00_axis_tready = pair_ready && m01_axis_tvalid;
    assign m01_axis_tready = pair_ready && m00_axis_tvalid;

    // RFDC already decimates by 24: one I/Q pair per 200 MHz beat.
    assign adc_pair_ready = adc_fifo_ready;
    assign adc_pair_valid = adc_rst_n && pair_valid;
    assign adc_pair_data = {m01_axis_tdata, m00_axis_tdata};

    complex_sample_async_fifo sample_fifo_inst (
        .rst(!adc_rst_n),
        .wr_clk(clk_adc0),
        .wr_valid(adc_pair_valid),
        .wr_ready(adc_fifo_ready),
        .wr_data(adc_pair_data),
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
        .ip_rst_n(ip_rst_n),.reload_valid(reload_valid),.config_valid(config_valid),
        .reload_ready(reload_ready),.config_ready(config_ready),.reload_last(reload_last),
        .reload_re(reload_re),.reload_im(reload_im),
        .reload_missing(reload_missing),.reload_unexpected(reload_unexpected),

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

    // RFDC performs interpolation. Cross one complex sample per beat.
    complex_sample_async_fifo dac_fifo_inst (
        .rst(!alg_rst_n), .wr_clk(clk_200m),
        .wr_valid(cal_valid), .wr_ready(cal_ready), .wr_data(cal_data),
        .rd_clk(clk_dac0), .rd_valid(dac_fifo_valid),
        .rd_ready(dac_started && s00_axis_tready), .rd_data(dac_fifo_data),
        .rd_level(dac_fifo_level),
        .overflow(block_fifo_overflow), .underflow(block_fifo_underflow)
    );
    always @(posedge clk_dac0) begin
        if (!dac_rst_n) dac_started <= 1'b0;
        else if (dac_fifo_level >= 6'd4) dac_started <= 1'b1;
    end
    assign s00_axis_tvalid = dac_rst_n && dac_started && dac_fifo_valid;
    assign s00_axis_tdata = dac_fifo_data;
    assign fifo_overflow = sample_fifo_overflow | fir_fifo_overflow |
                           block_fifo_overflow;
    assign fifo_underflow = sample_fifo_underflow | fir_fifo_underflow |
                            block_fifo_underflow;

endmodule
