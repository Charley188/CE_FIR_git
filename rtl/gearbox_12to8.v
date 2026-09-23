`timescale 1ns / 1ps

module gearbox_12to8 (
    input  wire         clk,
    input  wire         rst,

    input  wire         s_valid,
    output wire         s_ready,
    input  wire [383:0] s_data,

    output wire         m_valid,
    input  wire         m_ready,
    output reg  [255:0] m_data
);

    localparam [2:0] LOAD_A = 3'd0;
    localparam [2:0] LOAD_B = 3'd1;
    localparam [2:0] SEND_0 = 3'd2;
    localparam [2:0] SEND_1 = 3'd3;
    localparam [2:0] SEND_2 = 3'd4;

    reg [2:0] state;
    reg [383:0] block_a;
    reg [383:0] block_b;
    reg prefetched_a;

    assign m_valid = !rst &&
                     ((state == SEND_0) || (state == SEND_1) ||
                      (state == SEND_2));

    // During SEND_1/SEND_2 an input is accepted only on the same edge that
    // releases the register it replaces. This keeps the three output beats
    // continuous when the FIFO has data, without overwriting a referenced
    // A/B block under output backpressure.
    assign s_ready = !rst &&
                     (((state == LOAD_A) || (state == LOAD_B)) ||
                      (((state == SEND_1) || (state == SEND_2)) && m_ready));

    always @* begin
        case (state)
            SEND_0: m_data = block_a[255:0];
            SEND_1: m_data = {block_b[127:0], block_a[383:256]};
            SEND_2: m_data = block_b[383:128];
            default: m_data = 256'b0;
        endcase
    end

    always @(posedge clk) begin
        if (rst) begin
            state <= LOAD_A;
            block_a <= 384'b0;
            block_b <= 384'b0;
            prefetched_a <= 1'b0;
        end else begin
            case (state)
                LOAD_A: begin
                    if (s_valid && s_ready) begin
                        block_a <= s_data;
                        state <= LOAD_B;
                    end
                end

                LOAD_B: begin
                    if (s_valid && s_ready) begin
                        block_b <= s_data;
                        prefetched_a <= 1'b0;
                        state <= SEND_0;
                    end
                end

                SEND_0: begin
                    if (m_valid && m_ready)
                        state <= SEND_1;
                end

                SEND_1: begin
                    if (m_valid && m_ready) begin
                        if (s_valid && s_ready) begin
                            block_a <= s_data;
                            prefetched_a <= 1'b1;
                        end else begin
                            prefetched_a <= 1'b0;
                        end
                        state <= SEND_2;
                    end
                end

                SEND_2: begin
                    if (m_valid && m_ready) begin
                        if (s_valid && s_ready) begin
                            if (prefetched_a) begin
                                block_b <= s_data;
                                prefetched_a <= 1'b0;
                                state <= SEND_0;
                            end else begin
                                block_a <= s_data;
                                state <= LOAD_B;
                            end
                        end else if (prefetched_a) begin
                            prefetched_a <= 1'b0;
                            state <= LOAD_B;
                        end else begin
                            state <= LOAD_A;
                        end
                    end
                end

                default: begin
                    state <= LOAD_A;
                    prefetched_a <= 1'b0;
                end
            endcase
        end
    end

endmodule
