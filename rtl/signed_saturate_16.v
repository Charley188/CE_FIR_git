module signed_saturate_16 #(parameter integer WIDTH=41) (
    input  wire signed [WIDTH-1:0] in_value,
    output reg  signed [15:0] out_value
);

    reg signed [WIDTH-1:0] scaled_value;

    always @* begin
        // Keep the input signed so >>> propagates its sign through the required 16-bit fixed-point scaling.
        scaled_value = in_value >>> 16;

        // Compare the full shifted value before narrowing; values beyond signed16 clamp at the representable edges.
        if (scaled_value > 41'sd32767) begin
            out_value = 16'sd32767;
        end else if (scaled_value < -41'sd32768) begin
            out_value = -16'sd32768;
        end else begin
            out_value = scaled_value[15:0];
        end
    end

endmodule
