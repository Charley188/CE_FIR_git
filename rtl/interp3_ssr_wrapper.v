`timescale 1ns / 1ps
`include "interp12_ip_layout.vh"

module interp3_ssr_wrapper (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        s_valid,
    output wire        s_ready,
    input  wire [31:0] s_data,
    output wire        m_valid,
    input  wire        m_ready,
    output wire [95:0] m_data
);

    wire [`INTERP3_M_AXIS_TDATA_BITS-1:0] ip_m_data;
    wire ip_m_valid;
    wire ip_s_ready;

    interp3_stage1 fir_ip (
        .aresetn            (rst_n),
        .aclk               (clk),
        .s_axis_data_tvalid (rst_n && s_valid),
        .s_axis_data_tready (ip_s_ready),
        .s_axis_data_tdata  (s_data),
        .m_axis_data_tvalid (ip_m_valid),
        .m_axis_data_tready (m_ready),
        .m_axis_data_tdata  (ip_m_data)
    );

    assign s_ready = rst_n && ip_s_ready;
    assign m_valid = rst_n && ip_m_valid;

    genvar sample_index;
    generate
        for (sample_index = 0; sample_index < `INTERP3_SAMPLES;
             sample_index = sample_index + 1) begin : unpack_stage1
            wire signed [33:0] full_i;
            wire signed [33:0] full_q;
            wire signed [15:0] sat_i;
            wire signed [15:0] sat_q;
            assign full_i = ip_m_data[(2*sample_index)*`INTERP3_FIELD_BITS +: 34];
            assign full_q = ip_m_data[(2*sample_index+1)*`INTERP3_FIELD_BITS +: 34];
            fir_full_precision_saturate #(.IN_WIDTH(34)) sat_i_inst (
                .in_value(full_i), .out_value(sat_i)
            );
            fir_full_precision_saturate #(.IN_WIDTH(34)) sat_q_inst (
                .in_value(full_q), .out_value(sat_q)
            );
            assign m_data[32*sample_index +: 16] = sat_i;
            assign m_data[32*sample_index+16 +: 16] = sat_q;
        end
    endgenerate

`ifndef SYNTHESIS
    reg previous_valid;
    reg previous_ready;
    reg [95:0] previous_data;
    always @(posedge clk) begin
        if (!rst_n) begin
            previous_valid <= 1'b0;
            previous_ready <= 1'b0;
            previous_data <= 96'b0;
        end else begin
            if (ip_m_valid && (^ip_m_data === 1'bx))
                $fatal(1, "Stage-1 FIR Compiler produced an unknown output field");
            if (previous_valid && !previous_ready &&
                ((!m_valid) || (m_data !== previous_data)))
                $fatal(1, "Stage-1 output changed under backpressure");
            previous_valid <= m_valid;
            previous_ready <= m_ready;
            previous_data <= m_data;
        end
    end
`endif

endmodule
