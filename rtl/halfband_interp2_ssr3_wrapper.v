`timescale 1ns / 1ps
`include "interp12_ip_layout.vh"

module halfband_interp2_ssr3_wrapper (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         s_valid,
    output wire         s_ready,
    input  wire [95:0]  s_data,
    output wire         m_valid,
    input  wire         m_ready,
    output wire [191:0] m_data
);

    localparam integer META_DEPTH = 64;
    reg [31:0] delay_sample [0:5];
    reg [95:0] even_fifo [0:META_DEPTH-1];
    reg [5:0] even_wr_ptr;
    reg [5:0] even_rd_ptr;
    reg [6:0] even_count;
    integer reset_index;

    wire [95:0] even_for_input;
    assign even_for_input[31:0] = delay_sample[0];
    assign even_for_input[63:32] = delay_sample[1];
    assign even_for_input[95:64] = delay_sample[2];

    wire [`HB2_STAGE2_M_AXIS_TDATA_BITS-1:0] ip_m_data;
    wire ip_m_valid;
    wire ip_m_ready;
    wire ip_s_valid;
    wire ip_s_ready;
    wire pop_even;
    wire metadata_space;
    wire push_even;
    wire [95:0] even_head = even_fifo[even_rd_ptr];

    assign m_valid = rst_n && ip_m_valid && (even_count != 0);
    assign pop_even = m_valid && m_ready;
    assign metadata_space = (even_count < META_DEPTH) || pop_even;
    assign ip_s_valid = rst_n && s_valid && metadata_space;
    assign s_ready = rst_n && ip_s_ready && metadata_space;
    assign push_even = ip_s_valid && ip_s_ready;
    assign ip_m_ready = rst_n && (even_count != 0) && m_ready;

    interp2_stage2_odd fir_ip (
        .aresetn            (rst_n),
        .aclk               (clk),
        .s_axis_data_tvalid (ip_s_valid),
        .s_axis_data_tready (ip_s_ready),
        .s_axis_data_tdata  (s_data),
        .m_axis_data_tvalid (ip_m_valid),
        .m_axis_data_tready (ip_m_ready),
        .m_axis_data_tdata  (ip_m_data)
    );

    always @(posedge clk) begin
        if (!rst_n) begin
            even_wr_ptr <= 0;
            even_rd_ptr <= 0;
            even_count <= 0;
            for (reset_index = 0; reset_index < 6; reset_index = reset_index + 1)
                delay_sample[reset_index] <= 0;
        end else begin
            if (push_even) begin
                even_fifo[even_wr_ptr] <= even_for_input;
                even_wr_ptr <= even_wr_ptr + 1'b1;
                delay_sample[0] <= delay_sample[3];
                delay_sample[1] <= delay_sample[4];
                delay_sample[2] <= delay_sample[5];
                delay_sample[3] <= s_data[31:0];
                delay_sample[4] <= s_data[63:32];
                delay_sample[5] <= s_data[95:64];
            end
            if (pop_even)
                even_rd_ptr <= even_rd_ptr + 1'b1;
            case ({push_even, pop_even})
                2'b10: even_count <= even_count + 1'b1;
                2'b01: even_count <= even_count - 1'b1;
                default: even_count <= even_count;
            endcase
        end
    end

    genvar sample_index;
    generate
        for (sample_index = 0; sample_index < `HB2_STAGE2_SAMPLES;
             sample_index = sample_index + 1) begin : unpack_stage2
            wire signed [32:0] full_i;
            wire signed [32:0] full_q;
            wire signed [15:0] sat_i;
            wire signed [15:0] sat_q;
            assign full_i = ip_m_data[(2*sample_index)*`HB2_STAGE2_FIELD_BITS +: 33];
            assign full_q = ip_m_data[(2*sample_index+1)*`HB2_STAGE2_FIELD_BITS +: 33];
            fir_full_precision_saturate #(.IN_WIDTH(33)) sat_i_inst (
                .in_value(full_i), .out_value(sat_i)
            );
            fir_full_precision_saturate #(.IN_WIDTH(33)) sat_q_inst (
                .in_value(full_q), .out_value(sat_q)
            );
            assign m_data[64*sample_index +: 32] = even_head[32*sample_index +: 32];
            assign m_data[64*sample_index+32 +: 16] = sat_i;
            assign m_data[64*sample_index+48 +: 16] = sat_q;
        end
    endgenerate

`ifndef SYNTHESIS
    initial begin
        if (`HB2_STAGE2_LATENCY != 12)
            $fatal(1, "Stage-2 generated latency contract changed from 12 cycles");
    end
    always @(posedge clk) begin
        if (rst_n && ip_m_valid && (even_count == 0))
            $fatal(1, "Stage-2 odd output has no aligned delayed-even transaction");
        if (rst_n && ip_m_valid && (^ip_m_data === 1'bx))
            $fatal(1, "Stage-2 FIR Compiler produced an unknown output field");
        if (rst_n && (even_count > META_DEPTH))
            $fatal(1, "Stage-2 alignment FIFO credit overflow");
    end
`endif

endmodule
