`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2025/03/11 08:57:37
// Design Name:
// Module Name: wire3_spi
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module wire3_spi
#(
    parameter       RW_BIT = 0,
    parameter       ADDR_BITS = 16
)
(
    //4-wire
    input           spi_sclk,
    input           spi_csn,
    input           spi_mosi,
    output          spi_miso,

    //3-wire
    inout           spi_sdio,
    output          spi_dir

);

// internal registers
reg [5:0]       spi_count;
reg             spi_rd_wr_n;
reg             spi_enable;

assign spi_dir = spi_enable;

// check on rising edge and change on falling edge
always @(posedge spi_sclk or posedge spi_csn) begin
    if (spi_csn == 1'b1) begin
        spi_count <= 6'd0;
        spi_rd_wr_n <= 1'd0;
    end else begin
        spi_count <= spi_count + 1'b1;
        if (spi_count == RW_BIT) begin
            spi_rd_wr_n <= spi_mosi;
        end
    end
end

always @(negedge spi_sclk or posedge spi_csn) begin
    if (spi_csn == 1'b1) begin
        spi_enable <= 1'b0;
    end else begin
        if ((spi_count == ADDR_BITS) && (spi_csn == 1'b0)) begin
            spi_enable <= spi_rd_wr_n;
        end
    end
end

// io buffers
assign spi_miso = spi_sdio;
assign spi_sdio = (spi_enable == 1'b1) ? 1'bz : spi_mosi;



endmodule
