`timescale 1ns / 1ps

module complex_block_async_fifo (
    input  wire         rst,

    input  wire         wr_clk,
    input  wire         wr_valid,
    output wire         wr_ready,
    input  wire [383:0] wr_data,

    input  wire         rd_clk,
    output wire         rd_valid,
    input  wire         rd_ready,
    output wire [383:0] rd_data,

    output wire         overflow,
    output wire         underflow
);

    wire full;
    wire empty;
    wire wr_rst_busy;
    wire rd_rst_busy;
    wire [5:0] wr_data_count_unused;
    wire [5:0] rd_data_count_unused;
    wire data_valid_unused;
    wire prog_full_unused;
    wire prog_empty_unused;
    wire almost_full_unused;
    wire almost_empty_unused;
    wire wr_ack_unused;
    wire sbiterr_unused;
    wire dbiterr_unused;

    assign wr_ready = !rst && !full && !wr_rst_busy;
    // rst is synchronous to wr_clk; read-side recovery is rd_clk-local.
    assign rd_valid = !empty && !rd_rst_busy;

    xpm_fifo_async #(
        .FIFO_MEMORY_TYPE    ("auto"),
        .ECC_MODE            ("no_ecc"),
        .RELATED_CLOCKS      (0),
        .SIM_ASSERT_CHK      (1),
        .CASCADE_HEIGHT      (0),
        .FIFO_WRITE_DEPTH    (32),
        .WRITE_DATA_WIDTH    (384),
        .WR_DATA_COUNT_WIDTH (6),
        .PROG_FULL_THRESH    (24),
        .FULL_RESET_VALUE    (0),
        .USE_ADV_FEATURES    ("0505"),
        .READ_MODE           ("fwft"),
        .FIFO_READ_LATENCY   (0),
        .READ_DATA_WIDTH     (384),
        .RD_DATA_COUNT_WIDTH (6),
        .PROG_EMPTY_THRESH   (4),
        .DOUT_RESET_VALUE    ("0"),
        .CDC_SYNC_STAGES     (2),
        .WAKEUP_TIME         (0)
    ) fifo_inst (
        .sleep         (1'b0),
        .rst           (rst),

        .wr_clk        (wr_clk),
        .wr_en         (wr_valid && wr_ready),
        .din           (wr_data),
        .full          (full),
        .prog_full     (prog_full_unused),
        .wr_data_count (wr_data_count_unused),
        .overflow      (overflow),
        .wr_rst_busy   (wr_rst_busy),
        .almost_full   (almost_full_unused),
        .wr_ack        (wr_ack_unused),

        .rd_clk        (rd_clk),
        .rd_en         (rd_valid && rd_ready),
        .dout          (rd_data),
        .empty         (empty),
        .prog_empty    (prog_empty_unused),
        .rd_data_count (rd_data_count_unused),
        .underflow     (underflow),
        .rd_rst_busy   (rd_rst_busy),
        .almost_empty  (almost_empty_unused),
        .data_valid    (data_valid_unused),

        .injectsbiterr (1'b0),
        .injectdbiterr (1'b0),
        .sbiterr       (sbiterr_unused),
        .dbiterr       (dbiterr_unused)
    );

`ifndef SYNTHESIS
    always @(posedge wr_clk) begin
        if (!rst && overflow)
            $fatal(1, "384-bit asynchronous FIFO overflow");
    end

    always @(posedge rd_clk) begin
        if (!rst && underflow)
            $fatal(1, "384-bit asynchronous FIFO underflow");
    end
`endif

endmodule
