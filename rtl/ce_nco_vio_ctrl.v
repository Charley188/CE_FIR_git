// RFDC real-time NCO transaction guard, entirely in s_axi_aclk.
// Toggle apply_toggle once after setting frequencies and channel_mask.
// VIO changes during a transaction are ignored; payload remains latched.
module ce_nco_vio_ctrl #(
    parameter integer BUSY_WIDTH = 1,
    parameter integer TIMEOUT_BITS = 24
) (
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 clk CLK", X_INTERFACE_PARAMETER = "ASSOCIATED_RESET rst_n" *)
    input wire clk,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 rst_n RST", X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
    input wire rst_n,
    input wire [47:0] freq0,
    input wire [47:0] freq1,
    input wire [1:0] channel_mask,
    input wire apply_toggle,
    input wire [BUSY_WIDTH-1:0] nco_busy,
    output reg [47:0] nco_freq0,
    output reg [47:0] nco_freq1,
    output wire [5:0] nco_en0,
    output wire [5:0] nco_en1,
    output reg nco_req,
    output wire [3:0] status,
    output reg [15:0] completed_count
);
    localparam IDLE=0, SETUP=1, WAIT_BUSY=2;
    reg [1:0] state;
    reg last_toggle;
    reg [1:0] mask;
    reg [BUSY_WIDTH-1:0] seen_busy;
    reg [TIMEOUT_BITS-1:0] timer;
    reg timeout_flag;
    // busy[0] is register update busy; DAC busy[1] is SYSREF gating,
    // not a per-channel bit. Wait for bit0 acknowledgement and all bits clear.
    assign nco_en0 = mask[0] ? 6'b000111 : 6'b000000;
    assign nco_en1 = mask[1] ? 6'b000111 : 6'b000000;
    // bit0 active, bit1 RFDC busy, bit2 timeout (payload held), bit3 ack seen.
    assign status = {(|seen_busy), timeout_flag, (|nco_busy), (state != IDLE)};
    always @(posedge clk) begin
        if (!rst_n) begin
            state <= IDLE;
            last_toggle <= apply_toggle;
            mask <= 0;
            nco_freq0 <= 0;
            nco_freq1 <= 0;
            nco_req <= 0;
            seen_busy <= 0;
            timer <= 0;
            timeout_flag <= 0;
            completed_count <= 0;
        end else begin
            last_toggle <= apply_toggle;
            nco_req <= 0;
            case (state)
                IDLE: if ((apply_toggle != last_toggle) && (|channel_mask) && !(|nco_busy)) begin
                    nco_freq0 <= freq0;
                    nco_freq1 <= freq1;
                    mask <= channel_mask;
                    seen_busy <= 0;
                    timer <= 0;
                    timeout_flag <= 0;
                    state <= SETUP;
                end
                SETUP: begin
                    nco_req <= 1;
                    state <= WAIT_BUSY;
                end
                WAIT_BUSY: begin
                    seen_busy <= seen_busy | nco_busy;
                    if (&timer) timeout_flag <= 1;
                    else timer <= timer + 1'b1;
                    if (seen_busy[0] && !(|nco_busy)) begin
                        completed_count <= completed_count + 1'b1;
                        mask <= 0;
                        state <= IDLE;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule
