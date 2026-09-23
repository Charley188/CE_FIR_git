`timescale 1ns / 1ps

module rfdc_8lane_decimator12 (
    input  wire         clk,
    input  wire         rst_n,

    input  wire         s_valid,
    output wire         s_ready,
    input  wire [127:0] s_i_tdata,
    input  wire [127:0] s_q_tdata,

    output wire         m_valid,
    input  wire         m_ready,
    output wire [31:0]  m_data
);

    // Three accepted RFDC beats contain 24 chronological samples. Retain
    // beat-phase 0/lane0 and beat-phase 1/lane4, then discard phase 2.
    reg [1:0] phase;

    wire phase_has_output = (phase != 2'd2);
    wire [15:0] selected_i = (phase == 2'd0) ?
                             s_i_tdata[15:0] : s_i_tdata[79:64];
    wire [15:0] selected_q = (phase == 2'd0) ?
                             s_q_tdata[15:0] : s_q_tdata[79:64];

    assign m_valid = rst_n && s_valid && phase_has_output;
    assign m_data = {selected_q, selected_i};

    // A discarded beat never needs downstream storage. Output-producing
    // phases stall until the selected sample can be accepted.
    assign s_ready = rst_n && (!phase_has_output || m_ready);

    always @(posedge clk) begin
        if (!rst_n) begin
            phase <= 2'd0;
        end else if (s_valid && s_ready) begin
            if (phase == 2'd2) begin
                phase <= 2'd0;
            end else begin
                phase <= phase + 1'b1;
            end
        end
    end

endmodule
