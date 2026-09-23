`timescale 1ns / 1ps

module fir_full_precision_saturate #(
    parameter integer IN_WIDTH = 34
) (
    input  wire signed [IN_WIDTH-1:0] in_value,
    output wire signed [15:0]         out_value
);

    wire signed [IN_WIDTH-1:0] shifted = in_value >>> 16;
    localparam signed [IN_WIDTH-1:0] MAX_VALUE = 32767;
    localparam signed [IN_WIDTH-1:0] MIN_VALUE = -32768;

    assign out_value = (shifted > MAX_VALUE) ? 16'sh7fff :
                       (shifted < MIN_VALUE) ? 16'sh8000 : shifted[15:0];

endmodule
