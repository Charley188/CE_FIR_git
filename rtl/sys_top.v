//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2024/04/16 14:16:37
// Design Name:
// Module Name: sys_top
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


module sys_top
(
    input           sys_clk_p,
    input           sys_clk_n,

//hmc7044
    output          hmc7044_rst,
    output          hmc7044_sclk,
    output          hmc7044_csn,
    inout           hmc7044_sdio,

    input           rf_adc0_clk_n,
    input           rf_adc0_clk_p,
    input           rf_dac0_clk_n,
    input           rf_dac0_clk_p,
    input           pl_sysref_n,
    input           pl_sysref_p,

    input           rf_sysref_in_diff_n,
    input           rf_sysref_in_diff_p,
    input           rf_vin0_01_v_n,
    input           rf_vin0_01_v_p,
    input           rf_vin0_23_v_n,
    input           rf_vin0_23_v_p,
    output          rf_vout00_v_n,
    output          rf_vout00_v_p,
    output          rf_vout02_v_n,
    output          rf_vout02_v_p

    //test_io
//    output [3:0]        test_io_pl
);

wire            sys_rstn;
wire            glb_rstn;
wire            clk_10M;
wire            clk_100M;
wire            clk_200M;   //rf_aix_stream ref_clk
wire            clk_200m_locked;
wire            first_path_fifo_overflow;
wire            first_path_fifo_underflow;

reg             rf_user_sysref_adc;
reg             rf_user_sysref_dac;
reg             rf_user_sysref_adc_r;
reg             rf_user_sysref_dac_r;


wire            rf_adc_axis_rstn;   //(* MARK_DEBUG="true" *)
wire            rf_dac_axis_rstn; //(* MARK_DEBUG="true" *)
wire [16:0]     rf_m00_axis_tdata;
wire            rf_m00_axis_tready;//(* MARK_DEBUG="true" *)
wire            rf_m00_axis_tvalid;//(* MARK_DEBUG="true" *)
wire [16:0]     rf_m01_axis_tdata;
wire            rf_m01_axis_tready;//(* MARK_DEBUG="true" *)
wire            rf_m01_axis_tvalid;//(* MARK_DEBUG="true" *)
wire [16:0]     rf_m02_axis_tdata;
wire            rf_m02_axis_tready;//(* MARK_DEBUG="true" *)
wire            rf_m02_axis_tvalid;//(* MARK_DEBUG="true" *)
wire [16:0]     rf_m03_axis_tdata;
wire            rf_m03_axis_tready;//(* MARK_DEBUG="true" *)
wire            rf_m03_axis_tvalid;//(* MARK_DEBUG="true" *)


wire [31:0]     rf_s00_axis_tdata;
wire            rf_s00_axis_tready;
wire            rf_s00_axis_tvalid;
wire [31:0]     rf_s02_axis_tdata;
wire            rf_s02_axis_tready;
wire            rf_s02_axis_tvalid;

wire [255:0]    s_axis_tdata;
wire            s_axis_tvalid;

 wire            clk_adc0;
 wire            clk_dac0;

wire [3:0]      emio_gpio_i;
wire [3:0]      emio_gpio_o;
wire [3:0]      emio_gpio_t;


wire            pl_rstn;
wire            rst_vio;
wire            rst;

wire            spi_clk;
wire [1:0]      spi_csn;
wire            spi_miso;
wire            spi_mosi;

wire            hmc7044_mosi;
wire            hmc7044_miso;
wire            hmc7044_dev_rdy;

wire            spi_dir;

assign hmc7044_rst = ~clk_dev_rstn;

//assign rst = rst_vio;
assign rst = ~glb_rstn;
//assign test_io_pl = 4'b1010;
assign sys_rstn = 1'b1;
assign glb_rstn = 1'b1 && pl_rstn;

dev_reset_module dev_reset_module_inst
(
    .clk_10M            (clk_10M),

    .glb_rstn           (glb_rstn),
    .clk_dev_rstn       (clk_dev_rstn),   //时钟发送器硬复位
    .clk_dev_rdy        (hmc7044_dev_rdy),    //时钟发送器复位完成，准备配置
    .clk_dev_cfg_done   (hmc7044_cfg_done),
    .adc_dac_dev_rstn   (adc_dac_dev_rstn),
    .adc_dac_dev_rdy    (adc_dac_dev_rdy)

);

wire3_spi #(
    .RW_BIT             (0),
    .ADDR_BITS          (16)
) wire3_hmc7044_spi_inst
(
    //4-wire
    .spi_sclk           (hmc7044_sclk),
    .spi_csn            (hmc7044_csn),
    .spi_mosi           (hmc7044_mosi),
    .spi_miso           (hmc7044_miso),

    //3-wire
    .spi_sdio           (hmc7044_sdio),
    .spi_dir            (spi_dir)
);

hmc7044_module hmc7044_module_inst
(
    .clk                (clk_100M),        //SPI时钟10MHz，参考时钟100MHz
    .rst_n              (glb_rstn),

    .hmc7044_dev_rdy    (hmc7044_dev_rdy),
    .hmc7044_cfg_done   (hmc7044_cfg_done),

    .spi_sclk           (hmc7044_sclk),
    .spi_csn            (hmc7044_csn),
    .spi_mosi           (hmc7044_mosi),
    .spi_miso           (hmc7044_miso)
);

///////
reg [15:0]          adc0_data0_i;
reg [15:0]          adc0_data1_i;
reg [15:0]          adc0_data2_i;
reg [15:0]          adc0_data3_i;
reg [15:0]          adc0_data4_i;
reg [15:0]          adc0_data5_i;
reg [15:0]          adc0_data6_i;
reg [15:0]          adc0_data7_i;

reg [15:0]          adc0_data0_q;
reg [15:0]          adc0_data1_q;
reg [15:0]          adc0_data2_q;
reg [15:0]          adc0_data3_q;
reg [15:0]          adc0_data4_q;
reg [15:0]          adc0_data5_q;
reg [15:0]          adc0_data6_q;
reg [15:0]          adc0_data7_q;

reg [15:0]          adc1_data0_i;
reg [15:0]          adc1_data1_i;
reg [15:0]          adc1_data2_i;
reg [15:0]          adc1_data3_i;
reg [15:0]          adc1_data4_i;
reg [15:0]          adc1_data5_i;
reg [15:0]          adc1_data6_i;
reg [15:0]          adc1_data7_i;

reg [15:0]          adc1_data0_q;
reg [15:0]          adc1_data1_q;
reg [15:0]          adc1_data2_q;
reg [15:0]          adc1_data3_q;
reg [15:0]          adc1_data4_q;
reg [15:0]          adc1_data5_q;
reg [15:0]          adc1_data6_q;
reg [15:0]          adc1_data7_q;

wire                wr_en;  //(* MARK_DEBUG="true" *)
wire                full;   //(* MARK_DEBUG="true" *)
wire                empty;  //(* MARK_DEBUG="true" *)
reg                 rd_en;  //(* MARK_DEBUG="true" *)
reg [255 : 0]       fifo_din;    //(* MARK_DEBUG="true" *)
wire [255 : 0]      fifo_dout;   //(* MARK_DEBUG="true" *)

wire [39:0]         param_m_axi_araddr;
wire [2:0]          param_m_axi_arprot;
wire [0:0]          param_m_axi_arready;
wire [0:0]          param_m_axi_arvalid;
wire [39:0]         param_m_axi_awaddr;
wire [2:0]          param_m_axi_awprot;
wire [0:0]          param_m_axi_awready;
wire [0:0]          param_m_axi_awvalid;
wire [0:0]          param_m_axi_bready;
wire [1:0]          param_m_axi_bresp;
wire [0:0]          param_m_axi_bvalid;
wire [31:0]         param_m_axi_rdata;
wire [0:0]          param_m_axi_rready;
wire [1:0]          param_m_axi_rresp;
wire [0:0]          param_m_axi_rvalid;
wire [31:0]         param_m_axi_wdata;
wire [0:0]          param_m_axi_wready;
wire [3:0]          param_m_axi_wstrb;
wire [0:0]          param_m_axi_wvalid;

ila_adc ila_adc0_inst
(
    .clk(clk_adc0), // input wire clk

    .probe0(adc0_data0_i), // input wire [15:0]  probe0
    .probe1(adc0_data1_i), // input wire [15:0]  probe1
    .probe2(adc0_data2_i), // input wire [15:0]  probe2
    .probe3(adc0_data3_i), // input wire [15:0]  probe3
    .probe4(adc0_data4_i), // input wire [15:0]  probe4
    .probe5(adc0_data5_i), // input wire [15:0]  probe5
    .probe6(adc0_data6_i), // input wire [15:0]  probe6
    .probe7(adc0_data7_i), // input wire [15:0]  probe7
    .probe8(adc0_data0_q), // input wire [15:0]  probe8
    .probe9(adc0_data1_q), // input wire [15:0]  probe9
    .probe10(adc0_data2_q), // input wire [15:0]  probe10
    .probe11(adc0_data3_q), // input wire [15:0]  probe11
    .probe12(adc0_data4_q), // input wire [15:0]  probe12
    .probe13(adc0_data5_q), // input wire [15:0]  probe13
    .probe14(adc0_data6_q), // input wire [15:0]  probe14
    .probe15(adc0_data7_q)  // input wire [15:0]  probe15
);

ila_adc ila_adc1_inst
(
    .clk(clk_adc0), // input wire clk

    .probe0(adc1_data0_i), // input wire [15:0]  probe0
    .probe1(adc1_data1_i), // input wire [15:0]  probe1
    .probe2(adc1_data2_i), // input wire [15:0]  probe2
    .probe3(adc1_data3_i), // input wire [15:0]  probe3
    .probe4(adc1_data4_i), // input wire [15:0]  probe4
    .probe5(adc1_data5_i), // input wire [15:0]  probe5
    .probe6(adc1_data6_i), // input wire [15:0]  probe6
    .probe7(adc1_data7_i), // input wire [15:0]  probe7
    .probe8(adc1_data0_q), // input wire [15:0]  probe8
    .probe9(adc1_data1_q), // input wire [15:0]  probe9
    .probe10(adc1_data2_q), // input wire [15:0]  probe10
    .probe11(adc1_data3_q), // input wire [15:0]  probe11
    .probe12(adc1_data4_q), // input wire [15:0]  probe12
    .probe13(adc1_data5_q), // input wire [15:0]  probe13
    .probe14(adc1_data6_q), // input wire [15:0]  probe14
    .probe15(adc1_data7_q)  // input wire [15:0]  probe15
);

always @(posedge clk_adc0) begin
    adc0_data0_i <= rf_m00_axis_tdata[15:0];
    adc0_data1_i <= 16'd0;
    adc0_data2_i <= 16'd0;
    adc0_data3_i <= 16'd0;
    adc0_data4_i <= 16'd0;
    adc0_data5_i <= 16'd0;
    adc0_data6_i <= 16'd0;
    adc0_data7_i <= 16'd0;
    adc0_data0_q <= rf_m01_axis_tdata[15:0];
    adc0_data1_q <= 16'd0;
    adc0_data2_q <= 16'd0;
    adc0_data3_q <= 16'd0;
    adc0_data4_q <= 16'd0;
    adc0_data5_q <= 16'd0;
    adc0_data6_q <= 16'd0;
    adc0_data7_q <= 16'd0;
end

always @(posedge clk_adc0) begin
    adc1_data0_i <= rf_m02_axis_tdata[15:0];
    adc1_data1_i <= 16'd0;
    adc1_data2_i <= 16'd0;
    adc1_data3_i <= 16'd0;
    adc1_data4_i <= 16'd0;
    adc1_data5_i <= 16'd0;
    adc1_data6_i <= 16'd0;
    adc1_data7_i <= 16'd0;
    adc1_data0_q <= rf_m03_axis_tdata[15:0];
    adc1_data1_q <= 16'd0;
    adc1_data2_q <= 16'd0;
    adc1_data3_q <= 16'd0;
    adc1_data4_q <= 16'd0;
    adc1_data5_q <= 16'd0;
    adc1_data6_q <= 16'd0;
    adc1_data7_q <= 16'd0;
end


localparam TRUNCATED_DATA_WIDTH = 'd128;

wire [255:0]   adc0_cdc_dout;
wire [TRUNCATED_DATA_WIDTH-1:0]   adc0_cdc_dout_t;
wire [255:0]   adc1_cdc_dout;
wire [TRUNCATED_DATA_WIDTH-1:0]   adc1_cdc_dout_t;

wire            pl_sysref;

IBUFDS pl_sysref_i
(
    .I          (pl_sysref_p),
    .IB         (pl_sysref_n),
    .O          (pl_sysref)
);

always @(posedge clk_adc0) begin
    rf_user_sysref_adc_r <= pl_sysref;
    rf_user_sysref_adc <= rf_user_sysref_adc_r;
end

always @(posedge clk_dac0) begin
    rf_user_sysref_dac_r <= pl_sysref;
    rf_user_sysref_dac <= rf_user_sysref_dac_r;

end



wire update_hold,coeff_we,coeff_channel,coeff_match,load_quiet,path_running,reload_fault;
wire [10:0] coeff_addr;
wire [17:0] coeff_re,coeff_im;
ce_fir_coeff_control coeff_control_inst(
 .axi_clk(clk_100M),.alg_clk(clk_200M),.arst_n(pl_rstn),
 .s_awaddr(param_m_axi_awaddr),.s_awvalid(param_m_axi_awvalid),.s_awready(param_m_axi_awready),
 .s_wdata(param_m_axi_wdata),.s_wstrb(param_m_axi_wstrb),.s_wvalid(param_m_axi_wvalid),.s_wready(param_m_axi_wready),
 .s_bresp(param_m_axi_bresp),.s_bvalid(param_m_axi_bvalid),.s_bready(param_m_axi_bready),
 .s_araddr(param_m_axi_araddr),.s_arvalid(param_m_axi_arvalid),.s_arready(param_m_axi_arready),
 .s_rdata(param_m_axi_rdata),.s_rresp(param_m_axi_rresp),.s_rvalid(param_m_axi_rvalid),.s_rready(param_m_axi_rready),
 .update_hold(update_hold),.coeff_we(coeff_we),.coeff_channel(coeff_channel),
 .coeff_addr(coeff_addr),.coeff_re(coeff_re),.coeff_im(coeff_im),
 .coeff_match({1'b0,coeff_match}),.load_quiet({2{load_quiet}}),.path_running({2{path_running}}),
 .path_fault({1'b0,reload_fault | first_path_fifo_overflow | first_path_fifo_underflow}));

//first path
adda_first_path_chain first_path_chain_inst (
    .update_hold(update_hold),.coeff_we(coeff_we),.coeff_addr(coeff_addr),.coeff_re(coeff_re),.coeff_im(coeff_im),
    .coeff_match(coeff_match),.load_quiet(load_quiet),.path_running(path_running),.reload_fault(reload_fault),
    .clk_adc0(clk_adc0), .clk_200m(clk_200M), .clk_dac0(clk_dac0),
    .pl_rstn(pl_rstn),
    .rf_adc_axis_rstn(rf_adc_axis_rstn),
    .clk_200m_locked(clk_200m_locked),
    .rf_dac_axis_rstn(rf_dac_axis_rstn),
    .m00_axis_tdata(rf_m00_axis_tdata),
    .m00_axis_tvalid(rf_m00_axis_tvalid),
    .m00_axis_tready(rf_m00_axis_tready),
    .m01_axis_tdata(rf_m01_axis_tdata),
    .m01_axis_tvalid(rf_m01_axis_tvalid),
    .m01_axis_tready(rf_m01_axis_tready),
    .s00_axis_tdata(rf_s00_axis_tdata),
    .s00_axis_tvalid(rf_s00_axis_tvalid),
    .s00_axis_tready(rf_s00_axis_tready),
    .fifo_overflow(first_path_fifo_overflow),
    .fifo_underflow(first_path_fifo_underflow)
);

wire second_path_overflow, second_path_underflow;
ad_data_cdc ad_data_cdc_inst1 (
    .clk_adc(clk_adc0), .clk_dac(clk_dac0),
    .arst_n(pl_rstn && rf_adc_axis_rstn && rf_dac_axis_rstn),
    .m0_axis_tdata(rf_m02_axis_tdata), .m0_axis_tvalid(rf_m02_axis_tvalid),
    .m0_axis_tready(rf_m02_axis_tready),
    .m1_axis_tdata(rf_m03_axis_tdata), .m1_axis_tvalid(rf_m03_axis_tvalid),
    .m1_axis_tready(rf_m03_axis_tready),
    .s_axis_tdata(rf_s02_axis_tdata), .s_axis_tvalid(rf_s02_axis_tvalid),
    .s_axis_tready(rf_s02_axis_tready),
    .overflow(second_path_overflow), .underflow(second_path_underflow)
);

design_1_wrapper design_1_wrapper_inst
(
    .clk_adc0               (clk_adc0),
    .clk_dac0               (clk_dac0),
    .clk_10M                (clk_10M),
    .clk_100M               (clk_100M),
    .clk_200M               (clk_200M),
    .clk_200m_locked        (clk_200m_locked),

    .emio_gpio_i            (emio_gpio_i),
    .emio_gpio_o            (emio_gpio_o),
    .emio_gpio_t            (emio_gpio_t),

    .rf_adc0_clk_n          (rf_adc0_clk_n),
    .rf_adc0_clk_p          (rf_adc0_clk_p),
    .rf_dac0_clk_n          (rf_dac0_clk_n),
    .rf_dac0_clk_p          (rf_dac0_clk_p),

    // .rf_clk_adc0            (rf_clk_adc0),
    // .rf_clk_dac2            (rf_clk_dac2),
    .rf_adc_axis_rstn       (rf_adc_axis_rstn),
    .rf_dac_axis_rstn       (rf_dac_axis_rstn),
    .rf_m00_axis_tdata      (rf_m00_axis_tdata),
    .rf_m00_axis_tready     (rf_m00_axis_tready),
    .rf_m00_axis_tvalid     (rf_m00_axis_tvalid),
    .rf_m01_axis_tdata      (rf_m01_axis_tdata),
    .rf_m01_axis_tready     (rf_m01_axis_tready),
    .rf_m01_axis_tvalid     (rf_m01_axis_tvalid),
    .rf_m02_axis_tdata      (rf_m02_axis_tdata),
    .rf_m02_axis_tready     (rf_m02_axis_tready),
    .rf_m02_axis_tvalid     (rf_m02_axis_tvalid),
    .rf_m03_axis_tdata      (rf_m03_axis_tdata),
    .rf_m03_axis_tready     (rf_m03_axis_tready),
    .rf_m03_axis_tvalid     (rf_m03_axis_tvalid),
    .rf_s00_axis_tdata      (rf_s00_axis_tdata),
    .rf_s00_axis_tready     (rf_s00_axis_tready),
    .rf_s00_axis_tvalid     (rf_s00_axis_tvalid),
    .rf_s02_axis_tdata      (rf_s02_axis_tdata),
    .rf_s02_axis_tready     (rf_s02_axis_tready),
    .rf_s02_axis_tvalid     (rf_s02_axis_tvalid),
    .rf_sysref_in_diff_n    (rf_sysref_in_diff_n),
    .rf_sysref_in_diff_p    (rf_sysref_in_diff_p),
//    .rf_user_sysref_adc     (rf_user_sysref_adc),
//    .rf_user_sysref_dac     (rf_user_sysref_dac),
    .rf_vin0_01_v_n         (rf_vin0_01_v_n),
    .rf_vin0_01_v_p         (rf_vin0_01_v_p),
    .rf_vin0_23_v_n         (rf_vin0_23_v_n),
    .rf_vin0_23_v_p         (rf_vin0_23_v_p),
    .rf_vout00_v_n          (rf_vout00_v_n),
    .rf_vout00_v_p          (rf_vout00_v_p),
    .rf_vout02_v_n          (rf_vout02_v_n),
    .rf_vout02_v_p          (rf_vout02_v_p),

    .param_m_axi_araddr     (param_m_axi_araddr),
    .param_m_axi_arprot     (param_m_axi_arprot),
    .param_m_axi_arready    (param_m_axi_arready),
    .param_m_axi_arvalid    (param_m_axi_arvalid),
    .param_m_axi_awaddr     (param_m_axi_awaddr),
    .param_m_axi_awprot     (param_m_axi_awprot),
    .param_m_axi_awready    (param_m_axi_awready),
    .param_m_axi_awvalid    (param_m_axi_awvalid),
    .param_m_axi_bready     (param_m_axi_bready),
    .param_m_axi_bresp      (param_m_axi_bresp),
    .param_m_axi_bvalid     (param_m_axi_bvalid),
    .param_m_axi_rdata      (param_m_axi_rdata),
    .param_m_axi_rready     (param_m_axi_rready),
    .param_m_axi_rresp      (param_m_axi_rresp),
    .param_m_axi_rvalid     (param_m_axi_rvalid),
    .param_m_axi_wdata      (param_m_axi_wdata),
    .param_m_axi_wready     (param_m_axi_wready),
    .param_m_axi_wstrb      (param_m_axi_wstrb),
    .param_m_axi_wvalid     (param_m_axi_wvalid),

    .pl_rstn                (pl_rstn),

    .spi_clk                (spi_clk),
    .spi_csn                (spi_csn),
    .spi_miso               (spi_miso),
    .spi_mosi               (spi_mosi),

    .sys_clk_n              (sys_clk_n),
    .sys_clk_p              (sys_clk_p),
    .sys_rstn               (sys_rstn)
);


endmodule
