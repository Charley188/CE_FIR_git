`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2025/03/11 19:43:58
// Design Name:
// Module Name: dev_reset_module
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


module dev_reset_module
(
    // input           sys_clk,
    input           clk_10M,
    // input           sys_rstn,

    // output reg      delay_sys_rstn,     //对系统复位延时输出
    input           glb_rstn,
    output reg      clk_dev_rstn,   //时钟发送器硬复位
    output reg      clk_dev_rdy,    //时钟发送器复位完成，准备配置
    input           clk_dev_cfg_done,
    output reg      adc_dac_dev_rstn,
    output reg      adc_dac_dev_rdy

);

localparam DLY_100US_CNT = 14'd12500;   //125Mhz下 100us
localparam DELAY_10US_CNT = 8'd200;  //20MHz
localparam DELAY_5US_CNT = 8'd100;  //20MHz
localparam DELAY_2US_CNT = 8'd40;  //20MHz
localparam DELAY_1US_CNT = 8'd20;  //20MHz

localparam S_RST_1 = 2'd0;      //产生时钟发生器的复位信号
localparam S_WAIT_1 = 2'd1;      //等待时钟发生器的配置完成信号
localparam S_RST_2 = 2'd2;      //产生AD/DA的复位信号
localparam S_WAIT_2 = 2'd3;      //等待AD/DA的配置完成信号

reg [1:0]       state;
reg [1:0]       next_state;

reg [7:0]       clk_cnt;
reg [13:0]      delay_sys_rstn_delay_cnt;

// //延时系统复位
// always @(posedge sys_clk) begin
//    if (!sys_rstn) begin
//        delay_sys_rstn_delay_cnt <= 'd0;
//    end
//    else if(delay_sys_rstn_delay_cnt < DLY_100US_CNT - 'd1)begin
//     // if(delay_sys_rstn_delay_cnt < DLY_CNT - 'd1) begin
//         delay_sys_rstn_delay_cnt <= delay_sys_rstn_delay_cnt + 'd1;
//     end
//     else begin
//         delay_sys_rstn_delay_cnt <= delay_sys_rstn_delay_cnt;
//     end
// end

// always @(posedge sys_clk) begin
//    if (!sys_rstn) begin
//        delay_sys_rstn <= 'd1;
//    end
//    else if(delay_sys_rstn_delay_cnt < DLY_100US_CNT - 'd1)begin
//     // if(delay_sys_rstn_delay_cnt < DLY_CNT - 'd1) begin
//         delay_sys_rstn <= 'd0;
//     end
//     else begin
//         delay_sys_rstn <= 'd1;
//     end
// end

always @(posedge clk_10M) begin
    if (!glb_rstn) begin
        state <= S_RST_1;
    end else begin
        state <= next_state;
    end
end

always @(*) begin
    case (state)
        S_RST_1:
            if (clk_cnt == DELAY_10US_CNT - 'd1) begin
                next_state = S_WAIT_1;
            end else begin
                next_state = S_RST_1;
            end
        S_WAIT_1:
            if (clk_dev_cfg_done) begin
                next_state = S_RST_2;
            end else begin
                next_state = S_WAIT_1;
            end
        S_RST_2:
            if (clk_cnt == DELAY_10US_CNT - 'd1) begin
                next_state = S_WAIT_2;
            end else begin
                next_state = S_RST_2;
            end
        S_WAIT_2:
            next_state = S_WAIT_2;
        default:
            next_state = S_RST_1;
    endcase
end

always @(posedge clk_10M) begin
    if (!glb_rstn) begin
        clk_cnt <= 'd0;
    end
    else if (state == S_RST_1 || state == S_RST_2) begin
        clk_cnt <= clk_cnt + 'd1;
    end
    else begin
        clk_cnt <= 'd0;
    end
end

always @(posedge clk_10M) begin
    if (!glb_rstn) begin
        clk_dev_rstn <= 'd1;
    end
    else if ((clk_cnt > DELAY_1US_CNT - 'd1) && (clk_cnt < DELAY_5US_CNT - 'd1) && state == S_RST_1) begin
        clk_dev_rstn <= 'd0;
    end
    else begin
        clk_dev_rstn <= 'd1;
    end
end

always @(posedge clk_10M) begin
    if (!glb_rstn) begin
        clk_dev_rdy <= 'd0;
    end
    else if (clk_cnt == DELAY_10US_CNT - 'd1 && state == S_RST_1) begin
        clk_dev_rdy <= 'd1;
    end else begin
        clk_dev_rdy <= clk_dev_rdy;
    end
end

always @(posedge clk_10M) begin
    if (!glb_rstn) begin
        adc_dac_dev_rstn <= 'd1;
    end
    else if ((clk_cnt > DELAY_1US_CNT - 'd1) && (clk_cnt < DELAY_5US_CNT - 'd1) && state == S_RST_2) begin
        adc_dac_dev_rstn <= 'd0;
    end
    else begin
        adc_dac_dev_rstn <= 'd1;
    end
end

always @(posedge clk_10M) begin
    if (!glb_rstn) begin
        adc_dac_dev_rdy <= 'd0;
    end
    else if (clk_cnt == DELAY_10US_CNT - 'd1 && state == S_RST_2) begin
        adc_dac_dev_rdy <= 'd1;
    end else begin
        adc_dac_dev_rdy <= adc_dac_dev_rdy;
    end
end




endmodule
