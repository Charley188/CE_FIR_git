`timescale 1ns / 1ps

module complex_interp12_top (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         s_valid,
    output wire         s_ready,
    input  wire [31:0]  s_data,
    output wire         m_valid,
    input  wire         m_ready,
    output wire [383:0] m_data
);

    wire stage1_valid;
    wire stage1_ready;
    wire [95:0] stage1_data;
    wire stage2_valid;
    wire stage2_ready;
    wire [191:0] stage2_data;

    interp3_ssr_wrapper stage1_inst (
        .clk(clk), .rst_n(rst_n),
        .s_valid(s_valid), .s_ready(s_ready), .s_data(s_data),
        .m_valid(stage1_valid), .m_ready(stage1_ready), .m_data(stage1_data)
    );

    halfband_interp2_ssr3_wrapper stage2_inst (
        .clk(clk), .rst_n(rst_n),
        .s_valid(stage1_valid), .s_ready(stage1_ready), .s_data(stage1_data),
        .m_valid(stage2_valid), .m_ready(stage2_ready), .m_data(stage2_data)
    );

    halfband_interp2_ssr6_wrapper stage3_inst (
        .clk(clk), .rst_n(rst_n),
        .s_valid(stage2_valid), .s_ready(stage2_ready), .s_data(stage2_data),
        .m_valid(m_valid), .m_ready(m_ready), .m_data(m_data)
    );

`ifndef SYNTHESIS
    reg previous_valid;
    reg previous_ready;
    reg [383:0] previous_data;
    always @(posedge clk) begin
        if (!rst_n) begin
            previous_valid <= 1'b0;
            previous_ready <= 1'b0;
            previous_data <= 384'b0;
        end else begin
            if (previous_valid && !previous_ready &&
                ((!m_valid) || (m_data !== previous_data)))
                $fatal(1, "Interpolation top output changed under backpressure");
            previous_valid <= m_valid;
            previous_ready <= m_ready;
            previous_data <= m_data;
        end
    end
`endif

endmodule
