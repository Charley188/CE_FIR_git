`timescale 1ns / 1ps

module complex_fir_stream_buffer (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        s_valid,
    output wire        s_ready,
    input  wire [31:0] s_data,
    output wire        m_valid,
    input  wire        m_ready,
    output wire [31:0] m_data,
    output wire        fifo_overflow_error,
    output wire        fifo_underflow_error
);

    // 300-tap FIR Compiler latency is 309 cycles.  Keep the in-flight credit
    // window larger than the pipeline so continuous 200 MHz traffic can fill it.
    localparam integer FIFO_DEPTH = 512;
    localparam integer FIFO_COUNT_WIDTH = $clog2(FIFO_DEPTH) + 1;
    wire core_in_ready;
    wire core_out_valid;
    wire [31:0] core_out_data;
    wire fifo_full;
    wire fifo_empty;
    wire fifo_wr_rst_busy;
    wire fifo_rd_rst_busy;
    wire fifo_overflow;
    wire fifo_underflow;
    wire [FIFO_COUNT_WIDTH-1:0] fifo_wr_count;
    wire [FIFO_COUNT_WIDTH-1:0] fifo_rd_count;
    wire fifo_prog_full;
    wire fifo_prog_empty;
    wire fifo_almost_full;
    wire fifo_almost_empty;
    wire fifo_wr_ack;
    wire fifo_data_valid;
    wire fifo_sbiterr;
    wire fifo_dbiterr;
    wire accept_input;
    wire consume_output;
    wire credit_available;
    wire core_in_valid;
    reg [FIFO_COUNT_WIDTH-1:0] outstanding_credit;

    assign credit_available = (outstanding_credit < FIFO_DEPTH);
    assign core_in_valid = rst_n && !fifo_wr_rst_busy && !fifo_rd_rst_busy &&
                           s_valid && credit_available;
    assign s_ready = rst_n && !fifo_wr_rst_busy && !fifo_rd_rst_busy &&
                     core_in_ready && credit_available;
    assign accept_input = core_in_valid && core_in_ready;
    assign m_valid = rst_n && !fifo_empty && !fifo_rd_rst_busy;
    assign consume_output = m_valid && m_ready;
    assign fifo_overflow_error = fifo_overflow;
    assign fifo_underflow_error = fifo_underflow;

    complex_fir_calibration core_inst (
        .clk(clk), .rst_n(rst_n),
        .in_valid(core_in_valid), .in_ready(core_in_ready), .in_data(s_data),
        .out_valid(core_out_valid), .out_data(core_out_data)
    );

    xpm_fifo_sync #(
        .FIFO_MEMORY_TYPE("auto"),
        .ECC_MODE("no_ecc"),
        .SIM_ASSERT_CHK(1),
        .CASCADE_HEIGHT(0),
        .FIFO_WRITE_DEPTH(FIFO_DEPTH),
        .WRITE_DATA_WIDTH(32),
        .WR_DATA_COUNT_WIDTH(FIFO_COUNT_WIDTH),
        .PROG_FULL_THRESH(FIFO_DEPTH-16),
        .FULL_RESET_VALUE(0),
        .USE_ADV_FEATURES("0707"),
        .READ_MODE("fwft"),
        .FIFO_READ_LATENCY(0),
        .READ_DATA_WIDTH(32),
        .RD_DATA_COUNT_WIDTH(FIFO_COUNT_WIDTH),
        .PROG_EMPTY_THRESH(5),
        .DOUT_RESET_VALUE("0"),
        .WAKEUP_TIME(0)
    ) output_fifo (
        .sleep(1'b0), .rst(!rst_n), .wr_clk(clk),
        .wr_en(core_out_valid && !fifo_full && !fifo_wr_rst_busy),
        .din(core_out_data), .full(fifo_full), .prog_full(fifo_prog_full),
        .wr_data_count(fifo_wr_count), .overflow(fifo_overflow),
        .wr_rst_busy(fifo_wr_rst_busy), .almost_full(fifo_almost_full),
        .wr_ack(fifo_wr_ack),
        .rd_en(consume_output), .dout(m_data), .empty(fifo_empty),
        .prog_empty(fifo_prog_empty), .rd_data_count(fifo_rd_count),
        .underflow(fifo_underflow), .rd_rst_busy(fifo_rd_rst_busy),
        .almost_empty(fifo_almost_empty), .data_valid(fifo_data_valid),
        .injectsbiterr(1'b0), .injectdbiterr(1'b0),
        .sbiterr(fifo_sbiterr), .dbiterr(fifo_dbiterr)
    );

    always @(posedge clk) begin
        if (!rst_n) begin
            outstanding_credit <= 0;
        end else begin
            case ({accept_input, consume_output})
                2'b10: outstanding_credit <= outstanding_credit + 1'b1;
                2'b01: outstanding_credit <= outstanding_credit - 1'b1;
                default: outstanding_credit <= outstanding_credit;
            endcase
        end
    end

`ifndef SYNTHESIS
    always @(posedge clk) begin
        if (rst_n && core_out_valid && (fifo_full || fifo_wr_rst_busy))
            $fatal(1, "Calibration FIR produced output while its depth-%0d FIFO could not accept it", FIFO_DEPTH);
        if (rst_n && (outstanding_credit > FIFO_DEPTH))
            $fatal(1, "Calibration outstanding-credit guard overflowed");
        if (rst_n && (fifo_overflow || fifo_underflow))
            $fatal(1, "Calibration synchronous FIFO overflow/underflow");
    end
`endif

endmodule
