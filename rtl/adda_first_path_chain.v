`timescale 1ns / 1ps

module adda_first_path_chain (
    input wire update_hold,coeff_we,
    input tri0 diagnostic_bypass,
    output wire [127:0] diag_adc,diag_alg,diag_dac,
    input wire [10:0] coeff_addr,
    input wire [17:0] coeff_re,coeff_im,
    output wire coeff_match,load_quiet,path_running,reload_fault,
    input  wire         clk_adc0,
    input  wire         clk_alg,
    input  wire         clk_dac0,
    input  wire         pl_rstn,
    input  wire         rf_adc_axis_rstn,
    input  wire         alg_clk_locked,
    input  wire         rf_dac_axis_rstn,
    input  wire [31:0] m00_axis_tdata,
    input  wire         m00_axis_tvalid,
    output wire         m00_axis_tready,
    input  wire [31:0] m01_axis_tdata,
    input  wire         m01_axis_tvalid,
    output wire         m01_axis_tready,
    output wire [63:0] s00_axis_tdata,
    output wire         s00_axis_tvalid,
    input  wire         s00_axis_tready,
    output wire         fifo_overflow,
    output wire         fifo_underflow
);

    wire base_arst_n = pl_rstn & rf_adc_axis_rstn &
                        alg_clk_locked & rf_dac_axis_rstn;
    wire reload_running,ip_rst_n;
    wire [3:0] reload_valid,reload_ready,config_valid,config_ready,reload_missing,reload_unexpected;
    wire reload_last;
    wire [23:0] reload_re,reload_im;
    // Register the algorithm-domain run/hold decision before distributing reset.
    // External reset still asserts asynchronously; each domain releases locally.
    reg chain_arst_n;
    always @(posedge clk_alg or negedge base_arst_n)
        if (!base_arst_n) chain_arst_n <= 1'b0;
        else chain_arst_n <= reload_running && !update_hold;
    // CONFIG only queues the FIR configuration. Prime every startup with one
    // zero beat and discard its output before releasing ADC/DAC. This commits
    // the pending reload even if VIO changes before external data arrives.
    reg fir_primed,prime_sent;
    wire stream_arst_n = chain_arst_n && fir_primed;
    assign path_running=reload_running && alg_rst_n && fir_primed;
    ce_fir_reload reload_inst(
        .clk(clk_alg),.arst_n(base_arst_n),.update_hold(update_hold),
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
    wire [63:0] adc_pair_data;
    wire fifo_rd_valid;
    wire fifo_rd_ready;
    wire [63:0] fifo_rd_data;
    wire [5:0] fifo_rd_level;
    wire fir_in_ready;
    reg fir_stream_started;
    wire cal_valid;
    wire cal_ready;
    wire dac_write_ready;
    wire [63:0] cal_data;
    wire dac_fifo_valid;
    wire [63:0] dac_fifo_data;
    wire [5:0] dac_fifo_level;
    reg dac_started;
    wire sample_fifo_overflow;
    wire sample_fifo_underflow;
    wire fir_fifo_overflow;
    wire fir_fifo_underflow;
    wire block_fifo_overflow;
    wire block_fifo_underflow;
    reg sample_overflow_sticky;
    reg block_underflow_sticky;
    wire sample_overflow_alg;
    wire block_underflow_alg;
    wire dac_starved = dac_rst_n && dac_started && s00_axis_tready && !dac_fifo_valid;
    reg adc_monitor_started;
    always @(posedge clk_adc0 or negedge adc_rst_n)
        if (!adc_rst_n) adc_monitor_started <= 1'b0;
        else if (adc_fifo_ready) adc_monitor_started <= 1'b1;
    wire adc_stalled = adc_rst_n && adc_monitor_started && pair_valid && !adc_fifo_ready;
    reg [31:0] dac_starved_cycles,adc_stalled_cycles;
    always @(posedge clk_dac0 or negedge dac_rst_n)
        if (!dac_rst_n) dac_starved_cycles <= 0;
        else if (dac_starved && !(&dac_starved_cycles)) dac_starved_cycles <= dac_starved_cycles+1'b1;
    always @(posedge clk_adc0 or negedge adc_rst_n)
        if (!adc_rst_n) adc_stalled_cycles <= 0;
        else if (adc_stalled && !(&adc_stalled_cycles)) adc_stalled_cycles <= adc_stalled_cycles+1'b1;
    // Each diagnostic bus is sampled only by an ILA in its native clock domain.
    assign diag_adc = {26'b0,adc_rst_n,sample_overflow_sticky,adc_stalled,adc_fifo_ready,
                       m01_axis_tvalid,m00_axis_tvalid,adc_stalled_cycles,adc_pair_data};
    assign diag_alg = {51'b0,fir_primed,diagnostic_bypass,alg_rst_n,fir_stream_started,
                       fifo_rd_ready,fifo_rd_valid,cal_valid,fifo_rd_level,fifo_rd_data};
    assign diag_dac = {21'b0,dac_rst_n,block_underflow_sticky,dac_starved,
                       s00_axis_tready,s00_axis_tvalid,dac_fifo_level,dac_starved_cycles,s00_axis_tdata};

    // Preserve single-cycle remote-domain events until the next chain reset.
    // Only synchronized levels enter the algorithm-domain status/AXI controller.
    always @(posedge clk_adc0 or negedge adc_rst_n)
        if (!adc_rst_n) sample_overflow_sticky <= 1'b0;
        else if (sample_fifo_overflow || adc_stalled) sample_overflow_sticky <= 1'b1;
    always @(posedge clk_dac0 or negedge dac_rst_n)
        if (!dac_rst_n) block_underflow_sticky <= 1'b0;
        else if (block_fifo_underflow || dac_starved) block_underflow_sticky <= 1'b1;
    xpm_cdc_single #(.DEST_SYNC_FF(3), .INIT_SYNC_FF(1),
        .SIM_ASSERT_CHK(1), .SRC_INPUT_REG(0)) sample_overflow_cdc (
        .src_clk(clk_adc0), .src_in(sample_overflow_sticky),
        .dest_clk(clk_alg), .dest_out(sample_overflow_alg));
    xpm_cdc_single #(.DEST_SYNC_FF(3), .INIT_SYNC_FF(1),
        .SIM_ASSERT_CHK(1), .SRC_INPUT_REG(0)) block_underflow_cdc (
        .src_clk(clk_dac0), .src_in(block_underflow_sticky),
        .dest_clk(clk_alg), .dest_out(block_underflow_alg));

    reset_sync_n adc_reset_sync_inst (
        .clk(clk_adc0), .arst_n(stream_arst_n), .srst_n(adc_rst_n)
    );

    reset_sync_n alg_reset_sync_inst (
        .clk(clk_alg), .arst_n(chain_arst_n), .srst_n(alg_rst_n)
    );

    reset_sync_n dac_reset_sync_inst (
        .clk(clk_dac0), .arst_n(stream_arst_n), .srst_n(dac_rst_n)
    );

    assign pair_ready = adc_rst_n && adc_pair_ready;
    assign m00_axis_tready = pair_ready && m01_axis_tvalid;
    assign m01_axis_tready = pair_ready && m00_axis_tvalid;

    // RFDC /8: two consecutive I/Q samples per 300 MHz beat, earliest sample low.
    assign adc_pair_ready = adc_fifo_ready;
    assign adc_pair_valid = adc_rst_n && pair_valid;
    assign adc_pair_data = {m01_axis_tdata[31:16], m00_axis_tdata[31:16],
                            m01_axis_tdata[15:0], m00_axis_tdata[15:0]};

    complex_sample_async_fifo sample_fifo_inst (
        .rst(!adc_rst_n),
        .wr_clk(clk_adc0),
        .wr_valid(adc_pair_valid),
        .wr_ready(adc_fifo_ready),
        .wr_data(adc_pair_data),
        .rd_clk(clk_alg),
        .rd_valid(fifo_rd_valid),
        .rd_ready(fifo_rd_ready),
        .rd_data(fifo_rd_data),
        .rd_level(fifo_rd_level),
        .overflow(sample_fifo_overflow),
        .underflow(sample_fifo_underflow)
    );

    always @(posedge clk_alg) begin
        if (!alg_rst_n)
            fir_stream_started <= 1'b0;
        else if (!fir_stream_started && (fifo_rd_level >= 6'd4))
            fir_stream_started <= 1'b1;
    end
    assign fifo_rd_ready = fir_stream_started && (diagnostic_bypass ? dac_write_ready : fir_in_ready);
    assign cal_ready = !fir_primed || diagnostic_bypass || dac_write_ready;
    always @(posedge clk_alg) begin
        if (!alg_rst_n) begin fir_primed <= 1'b0; prime_sent <= 1'b0; end
        else if (!fir_primed) begin
            if (!prime_sent && fir_in_ready) prime_sent <= 1'b1;
            if (cal_valid) fir_primed <= 1'b1;
        end
    end

    complex_fir_stream_buffer fir_inst (
        .ip_rst_n(ip_rst_n),.reload_valid(reload_valid),.config_valid(config_valid),
        .reload_ready(reload_ready),.config_ready(config_ready),.reload_last(reload_last),
        .reload_re(reload_re),.reload_im(reload_im),
        .reload_missing(reload_missing),.reload_unexpected(reload_unexpected),

        .clk(clk_alg),
        .rst_n(alg_rst_n),
        .s_valid(!fir_primed ? !prime_sent : (!diagnostic_bypass && fir_stream_started && fifo_rd_valid)),
        .s_ready(fir_in_ready),
        .s_data(!fir_primed ? 64'b0 : fifo_rd_data),
        .m_valid(cal_valid),
        .m_ready(cal_ready),
        .m_data(cal_data),
        .fifo_overflow_error(fir_fifo_overflow),
        .fifo_underflow_error(fir_fifo_underflow)
    );

    // RFDC x8 interpolation. Cross two interleaved complex samples per beat.
    complex_sample_async_fifo dac_fifo_inst (
        .rst(!alg_rst_n), .wr_clk(clk_alg),
        .wr_valid(fir_primed && (diagnostic_bypass ? (fir_stream_started && fifo_rd_valid) : cal_valid)),
        .wr_ready(dac_write_ready), .wr_data(diagnostic_bypass ? fifo_rd_data : cal_data),
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
    // RFDC ignores TVALID: explicitly suppress data during reset/startup/starvation.
    assign s00_axis_tdata = s00_axis_tvalid ? dac_fifo_data : 64'b0;
    assign fifo_overflow = alg_rst_n && (sample_overflow_alg | fir_fifo_overflow |
                           block_fifo_overflow);
    assign fifo_underflow = alg_rst_n && (sample_fifo_underflow | fir_fifo_underflow |
                            block_underflow_alg);

endmodule
