`include "fir_ip_layout.vh"
module complex_fir_calibration #(
    parameter integer DATA_WIDTH = 16,
    parameter integer COEF_WIDTH = 18,
    parameter integer COEF_FRAC  = 16,
    parameter integer NTAPS      = 300
) (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        in_valid,
    output wire        in_ready,
    input  wire [31:0] in_data,
    output wire        out_valid,
    output wire [31:0] out_data
);

    // Generated FIR IP interfaces are fixed at 16/18/Q2.16/300; retain plan-mandated parameters only as guarded API fields.
`ifndef SYNTHESIS
    initial begin : validate_fixed_ip_parameters
        if ((DATA_WIDTH != 16) || (COEF_WIDTH != 18) ||
            (COEF_FRAC != 16) || (NTAPS != 300)) begin
            $fatal(1, "complex_fir_calibration generated IP requires DATA_WIDTH=16, COEF_WIDTH=18, COEF_FRAC=16, NTAPS=300");
        end
    end
`endif

    // A 300-tap impulse real filter and zero imaginary filter can differ by 153 cycles.
    localparam integer JOIN_DEPTH = (NTAPS > 64) ? 256 : 64;
    localparam integer JOIN_PTR_WIDTH = $clog2(JOIN_DEPTH);
`ifndef SYNTHESIS
    initial begin
        if (`FIR_RE_TDATA_WIDTH < 16 || `FIR_RE_TDATA_WIDTH > 40 ||
            `FIR_IM_TDATA_WIDTH < 16 || `FIR_IM_TDATA_WIDTH > 40)
            $fatal(1, "FIR layout width outside supported 16..40 bits");
    end
`endif
    localparam integer RE_WIDTH = `FIR_RE_TDATA_WIDTH;
    localparam integer IM_WIDTH = `FIR_IM_TDATA_WIDTH;

    reg         input_buffer_valid;
    reg  [31:0] input_buffer_data;
    reg  [3:0]  input_accepted;

    wire [15:0] input_i = input_buffer_data[15:0];
    wire [15:0] input_q = input_buffer_data[31:16];

    wire ready_i_cr;
    wire ready_q_ci;
    wire ready_i_ci;
    wire ready_q_cr;

    wire valid_i_cr;
    wire valid_q_ci;
    wire valid_i_ci;
    wire valid_q_cr;

    wire [RE_WIDTH-1:0] fir_i_cr;
    wire [IM_WIDTH-1:0] fir_q_ci;
    wire [IM_WIDTH-1:0] fir_i_ci;
    wire [RE_WIDTH-1:0] fir_q_cr;

    // Four real FIRs implement (I+jQ)(Cr+jCi): I*Cr-Q*Ci and I*Ci+Q*Cr.
    wire [3:0] fir_ready = {ready_q_cr, ready_i_ci, ready_q_ci, ready_i_cr};
    wire [3:0] fir_input_valid = {
        input_buffer_valid && !input_accepted[3],
        input_buffer_valid && !input_accepted[2],
        input_buffer_valid && !input_accepted[1],
        input_buffer_valid && !input_accepted[0]
    };
    wire [3:0] fir_input_handshake = fir_input_valid & fir_ready;
    wire dispatch_complete = input_buffer_valid &&
                             &(input_accepted | fir_input_handshake);
    wire accept_new_input;

    assign in_ready = rst_n && (!input_buffer_valid || dispatch_complete);
    assign accept_new_input = rst_n && in_valid && in_ready;

    always @(posedge clk) begin
        if (!rst_n) begin
            input_buffer_valid <= 1'b0;
            input_buffer_data <= 32'b0;
            input_accepted <= 4'b0;
        end else if (!input_buffer_valid) begin
            if (accept_new_input) begin
                input_buffer_valid <= 1'b1;
                input_buffer_data <= in_data;
                input_accepted <= 4'b0;
            end
        end else if (dispatch_complete) begin
            if (accept_new_input) begin
                input_buffer_valid <= 1'b1;
                input_buffer_data <= in_data;
                input_accepted <= 4'b0;
            end else begin
                input_buffer_valid <= 1'b0;
                input_accepted <= 4'b0;
            end
        end else begin
            input_accepted <= input_accepted | fir_input_handshake;
        end
    end

    fir_coef_re fir_i_cr_path (
        .aresetn            (rst_n),
        .aclk               (clk),
        .s_axis_data_tvalid (fir_input_valid[0]),
        .s_axis_data_tready (ready_i_cr),
        .s_axis_data_tdata  (input_i),
        .m_axis_data_tvalid (valid_i_cr),
        .m_axis_data_tdata  (fir_i_cr)
    );

    fir_coef_im fir_q_ci_path (
        .aresetn            (rst_n),
        .aclk               (clk),
        .s_axis_data_tvalid (fir_input_valid[1]),
        .s_axis_data_tready (ready_q_ci),
        .s_axis_data_tdata  (input_q),
        .m_axis_data_tvalid (valid_q_ci),
        .m_axis_data_tdata  (fir_q_ci)
    );

    fir_coef_im fir_i_ci_path (
        .aresetn            (rst_n),
        .aclk               (clk),
        .s_axis_data_tvalid (fir_input_valid[2]),
        .s_axis_data_tready (ready_i_ci),
        .s_axis_data_tdata  (input_i),
        .m_axis_data_tvalid (valid_i_ci),
        .m_axis_data_tdata  (fir_i_ci)
    );

    fir_coef_re fir_q_cr_path (
        .aresetn            (rst_n),
        .aclk               (clk),
        .s_axis_data_tvalid (fir_input_valid[3]),
        .s_axis_data_tready (ready_q_cr),
        .s_axis_data_tdata  (input_q),
        .m_axis_data_tvalid (valid_q_cr),
        .m_axis_data_tdata  (fir_q_cr)
    );

    wire [3:0] fir_valid = {valid_q_cr, valid_i_ci, valid_q_ci, valid_i_cr};

    // The four FIRs may accept and return a transaction on different cycles.
    // Per-path queues preserve ordering; a result is joined only when all four
    // queue heads belong to the same next transaction.
    reg [40:0] queue_i_cr [0:JOIN_DEPTH-1];
    reg [40:0] queue_q_ci [0:JOIN_DEPTH-1];
    reg [40:0] queue_i_ci [0:JOIN_DEPTH-1];
    reg [40:0] queue_q_cr [0:JOIN_DEPTH-1];
    reg [JOIN_PTR_WIDTH-1:0] wr_i_cr, wr_q_ci, wr_i_ci, wr_q_cr;
    reg [JOIN_PTR_WIDTH-1:0] rd_i_cr, rd_q_ci, rd_i_ci, rd_q_cr;
    reg [JOIN_PTR_WIDTH:0] count_i_cr, count_q_ci, count_i_ci, count_q_cr;
    wire join_available = (count_i_cr != 0) && (count_q_ci != 0) &&
                          (count_i_ci != 0) && (count_q_cr != 0);
    wire join_pop = rst_n && join_available;

    wire signed [40:0] fir_i_cr_ext = queue_i_cr[rd_i_cr];
    wire signed [40:0] fir_q_ci_ext = queue_q_ci[rd_q_ci];
    wire signed [40:0] fir_i_ci_ext = queue_i_ci[rd_i_ci];
    wire signed [40:0] fir_q_cr_ext = queue_q_cr[rd_q_cr];
    wire signed [40:0] acc_i = fir_i_cr_ext - fir_q_ci_ext;
    wire signed [40:0] acc_q = fir_i_ci_ext + fir_q_cr_ext;

    wire signed [15:0] out_i;
    wire signed [15:0] out_q;

    // The shared saturator performs the required 2^16 scaling and signed-16 clamping.
    signed_saturate_16 saturate_i (
        .in_value  (acc_i),
        .out_value (out_i)
    );

    signed_saturate_16 saturate_q (
        .in_value  (acc_q),
        .out_value (out_q)
    );

    assign out_valid = join_pop;
    // The external complex-data contract always packs Q high and I low.
    assign out_data = {out_q, out_i};

    always @(posedge clk) begin
        if (!rst_n) begin
            wr_i_cr <= 0; wr_q_ci <= 0; wr_i_ci <= 0; wr_q_cr <= 0;
            rd_i_cr <= 0; rd_q_ci <= 0; rd_i_ci <= 0; rd_q_cr <= 0;
            count_i_cr <= 0; count_q_ci <= 0;
            count_i_ci <= 0; count_q_cr <= 0;
        end else begin
            if (valid_i_cr) begin
                queue_i_cr[wr_i_cr] <= {{(41-RE_WIDTH){fir_i_cr[RE_WIDTH-1]}},fir_i_cr};
                wr_i_cr <= wr_i_cr + 1'b1;
            end
            if (valid_q_ci) begin
                queue_q_ci[wr_q_ci] <= {{(41-IM_WIDTH){fir_q_ci[IM_WIDTH-1]}},fir_q_ci};
                wr_q_ci <= wr_q_ci + 1'b1;
            end
            if (valid_i_ci) begin
                queue_i_ci[wr_i_ci] <= {{(41-IM_WIDTH){fir_i_ci[IM_WIDTH-1]}},fir_i_ci};
                wr_i_ci <= wr_i_ci + 1'b1;
            end
            if (valid_q_cr) begin
                queue_q_cr[wr_q_cr] <= {{(41-RE_WIDTH){fir_q_cr[RE_WIDTH-1]}},fir_q_cr};
                wr_q_cr <= wr_q_cr + 1'b1;
            end
            if (join_pop) begin
                rd_i_cr <= rd_i_cr + 1'b1; rd_q_ci <= rd_q_ci + 1'b1;
                rd_i_ci <= rd_i_ci + 1'b1; rd_q_cr <= rd_q_cr + 1'b1;
            end
            case ({valid_i_cr,join_pop})
                2'b10: count_i_cr <= count_i_cr + 1'b1;
                2'b01: count_i_cr <= count_i_cr - 1'b1;
                default: count_i_cr <= count_i_cr;
            endcase
            case ({valid_q_ci,join_pop})
                2'b10: count_q_ci <= count_q_ci + 1'b1;
                2'b01: count_q_ci <= count_q_ci - 1'b1;
                default: count_q_ci <= count_q_ci;
            endcase
            case ({valid_i_ci,join_pop})
                2'b10: count_i_ci <= count_i_ci + 1'b1;
                2'b01: count_i_ci <= count_i_ci - 1'b1;
                default: count_i_ci <= count_i_ci;
            endcase
            case ({valid_q_cr,join_pop})
                2'b10: count_q_cr <= count_q_cr + 1'b1;
                2'b01: count_q_cr <= count_q_cr - 1'b1;
                default: count_q_cr <= count_q_cr;
            endcase
        end
    end

`ifndef SYNTHESIS
    always @(posedge clk) begin
        if (rst_n && ((fir_input_handshake & input_accepted) != 0))
            $fatal(1, "A calibration FIR path accepted the same transaction twice");
        if (rst_n && ((count_i_cr > JOIN_DEPTH) || (count_q_ci > JOIN_DEPTH) ||
                      (count_i_ci > JOIN_DEPTH) || (count_q_cr > JOIN_DEPTH)))
            $fatal(1, "Calibration FIR output join queue overflow");
    end
`endif

endmodule
