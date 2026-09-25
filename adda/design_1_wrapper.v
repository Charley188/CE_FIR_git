//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2023.2 (win64) Build 4029153 Fri Oct 13 20:14:34 MDT 2023
//Date        : Thu Sep 24 19:20:21 2026
//Host        : Charlieco running 64-bit major release  (build 9200)
//Command     : generate_target design_1_wrapper.bd
//Design      : design_1_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module design_1_wrapper
   (clk_100M,
    clk_10M,
    clk_200M,
    clk_200m_locked,
    clk_adc0,
    clk_dac0,
    emio_gpio_i,
    emio_gpio_o,
    emio_gpio_t,
    param_m_axi_araddr,
    param_m_axi_arprot,
    param_m_axi_arready,
    param_m_axi_arvalid,
    param_m_axi_awaddr,
    param_m_axi_awprot,
    param_m_axi_awready,
    param_m_axi_awvalid,
    param_m_axi_bready,
    param_m_axi_bresp,
    param_m_axi_bvalid,
    param_m_axi_rdata,
    param_m_axi_rready,
    param_m_axi_rresp,
    param_m_axi_rvalid,
    param_m_axi_wdata,
    param_m_axi_wready,
    param_m_axi_wstrb,
    param_m_axi_wvalid,
    pl_rstn,
    rf_adc0_clk_n,
    rf_adc0_clk_p,
    rf_adc_axis_rstn,
    rf_dac0_clk_n,
    rf_dac0_clk_p,
    rf_dac_axis_rstn,
    rf_m00_axis_tdata,
    rf_m00_axis_tready,
    rf_m00_axis_tvalid,
    rf_m01_axis_tdata,
    rf_m01_axis_tready,
    rf_m01_axis_tvalid,
    rf_m02_axis_tdata,
    rf_m02_axis_tready,
    rf_m02_axis_tvalid,
    rf_m03_axis_tdata,
    rf_m03_axis_tready,
    rf_m03_axis_tvalid,
    rf_s00_axis_tdata,
    rf_s00_axis_tready,
    rf_s00_axis_tvalid,
    rf_s02_axis_tdata,
    rf_s02_axis_tready,
    rf_s02_axis_tvalid,
    rf_sysref_in_diff_n,
    rf_sysref_in_diff_p,
    rf_vin0_01_v_n,
    rf_vin0_01_v_p,
    rf_vin0_23_v_n,
    rf_vin0_23_v_p,
    rf_vout00_v_n,
    rf_vout00_v_p,
    rf_vout02_v_n,
    rf_vout02_v_p,
    spi_clk,
    spi_csn,
    spi_miso,
    spi_mosi,
    sys_clk_n,
    sys_clk_p,
    sys_rstn);
  output clk_100M;
  output clk_10M;
  output clk_200M;
  output clk_200m_locked;
  output clk_adc0;
  output clk_dac0;
  input [3:0]emio_gpio_i;
  output [3:0]emio_gpio_o;
  output [3:0]emio_gpio_t;
  output [39:0]param_m_axi_araddr;
  output [2:0]param_m_axi_arprot;
  input [0:0]param_m_axi_arready;
  output [0:0]param_m_axi_arvalid;
  output [39:0]param_m_axi_awaddr;
  output [2:0]param_m_axi_awprot;
  input [0:0]param_m_axi_awready;
  output [0:0]param_m_axi_awvalid;
  output [0:0]param_m_axi_bready;
  input [1:0]param_m_axi_bresp;
  input [0:0]param_m_axi_bvalid;
  input [31:0]param_m_axi_rdata;
  output [0:0]param_m_axi_rready;
  input [1:0]param_m_axi_rresp;
  input [0:0]param_m_axi_rvalid;
  output [31:0]param_m_axi_wdata;
  input [0:0]param_m_axi_wready;
  output [3:0]param_m_axi_wstrb;
  output [0:0]param_m_axi_wvalid;
  output pl_rstn;
  input rf_adc0_clk_n;
  input rf_adc0_clk_p;
  output [0:0]rf_adc_axis_rstn;
  input rf_dac0_clk_n;
  input rf_dac0_clk_p;
  output [0:0]rf_dac_axis_rstn;
  output [15:0]rf_m00_axis_tdata;
  input rf_m00_axis_tready;
  output rf_m00_axis_tvalid;
  output [15:0]rf_m01_axis_tdata;
  input rf_m01_axis_tready;
  output rf_m01_axis_tvalid;
  output [15:0]rf_m02_axis_tdata;
  input rf_m02_axis_tready;
  output rf_m02_axis_tvalid;
  output [15:0]rf_m03_axis_tdata;
  input rf_m03_axis_tready;
  output rf_m03_axis_tvalid;
  input [31:0]rf_s00_axis_tdata;
  output rf_s00_axis_tready;
  input rf_s00_axis_tvalid;
  input [31:0]rf_s02_axis_tdata;
  output rf_s02_axis_tready;
  input rf_s02_axis_tvalid;
  input rf_sysref_in_diff_n;
  input rf_sysref_in_diff_p;
  input rf_vin0_01_v_n;
  input rf_vin0_01_v_p;
  input rf_vin0_23_v_n;
  input rf_vin0_23_v_p;
  output rf_vout00_v_n;
  output rf_vout00_v_p;
  output rf_vout02_v_n;
  output rf_vout02_v_p;
  output spi_clk;
  output [1:0]spi_csn;
  input spi_miso;
  output spi_mosi;
  input sys_clk_n;
  input sys_clk_p;
  input sys_rstn;

  wire clk_100M;
  wire clk_10M;
  wire clk_200M;
  wire clk_200m_locked;
  wire clk_adc0;
  wire clk_dac0;
  wire [3:0]emio_gpio_i;
  wire [3:0]emio_gpio_o;
  wire [3:0]emio_gpio_t;
  wire [39:0]param_m_axi_araddr;
  wire [2:0]param_m_axi_arprot;
  wire [0:0]param_m_axi_arready;
  wire [0:0]param_m_axi_arvalid;
  wire [39:0]param_m_axi_awaddr;
  wire [2:0]param_m_axi_awprot;
  wire [0:0]param_m_axi_awready;
  wire [0:0]param_m_axi_awvalid;
  wire [0:0]param_m_axi_bready;
  wire [1:0]param_m_axi_bresp;
  wire [0:0]param_m_axi_bvalid;
  wire [31:0]param_m_axi_rdata;
  wire [0:0]param_m_axi_rready;
  wire [1:0]param_m_axi_rresp;
  wire [0:0]param_m_axi_rvalid;
  wire [31:0]param_m_axi_wdata;
  wire [0:0]param_m_axi_wready;
  wire [3:0]param_m_axi_wstrb;
  wire [0:0]param_m_axi_wvalid;
  wire pl_rstn;
  wire rf_adc0_clk_n;
  wire rf_adc0_clk_p;
  wire [0:0]rf_adc_axis_rstn;
  wire rf_dac0_clk_n;
  wire rf_dac0_clk_p;
  wire [0:0]rf_dac_axis_rstn;
  wire [15:0]rf_m00_axis_tdata;
  wire rf_m00_axis_tready;
  wire rf_m00_axis_tvalid;
  wire [15:0]rf_m01_axis_tdata;
  wire rf_m01_axis_tready;
  wire rf_m01_axis_tvalid;
  wire [15:0]rf_m02_axis_tdata;
  wire rf_m02_axis_tready;
  wire rf_m02_axis_tvalid;
  wire [15:0]rf_m03_axis_tdata;
  wire rf_m03_axis_tready;
  wire rf_m03_axis_tvalid;
  wire [31:0]rf_s00_axis_tdata;
  wire rf_s00_axis_tready;
  wire rf_s00_axis_tvalid;
  wire [31:0]rf_s02_axis_tdata;
  wire rf_s02_axis_tready;
  wire rf_s02_axis_tvalid;
  wire rf_sysref_in_diff_n;
  wire rf_sysref_in_diff_p;
  wire rf_vin0_01_v_n;
  wire rf_vin0_01_v_p;
  wire rf_vin0_23_v_n;
  wire rf_vin0_23_v_p;
  wire rf_vout00_v_n;
  wire rf_vout00_v_p;
  wire rf_vout02_v_n;
  wire rf_vout02_v_p;
  wire spi_clk;
  wire [1:0]spi_csn;
  wire spi_miso;
  wire spi_mosi;
  wire sys_clk_n;
  wire sys_clk_p;
  wire sys_rstn;

  design_1 design_1_i
       (.clk_100M(clk_100M),
        .clk_10M(clk_10M),
        .clk_200M(clk_200M),
        .clk_200m_locked(clk_200m_locked),
        .clk_adc0(clk_adc0),
        .clk_dac0(clk_dac0),
        .emio_gpio_i(emio_gpio_i),
        .emio_gpio_o(emio_gpio_o),
        .emio_gpio_t(emio_gpio_t),
        .param_m_axi_araddr(param_m_axi_araddr),
        .param_m_axi_arprot(param_m_axi_arprot),
        .param_m_axi_arready(param_m_axi_arready),
        .param_m_axi_arvalid(param_m_axi_arvalid),
        .param_m_axi_awaddr(param_m_axi_awaddr),
        .param_m_axi_awprot(param_m_axi_awprot),
        .param_m_axi_awready(param_m_axi_awready),
        .param_m_axi_awvalid(param_m_axi_awvalid),
        .param_m_axi_bready(param_m_axi_bready),
        .param_m_axi_bresp(param_m_axi_bresp),
        .param_m_axi_bvalid(param_m_axi_bvalid),
        .param_m_axi_rdata(param_m_axi_rdata),
        .param_m_axi_rready(param_m_axi_rready),
        .param_m_axi_rresp(param_m_axi_rresp),
        .param_m_axi_rvalid(param_m_axi_rvalid),
        .param_m_axi_wdata(param_m_axi_wdata),
        .param_m_axi_wready(param_m_axi_wready),
        .param_m_axi_wstrb(param_m_axi_wstrb),
        .param_m_axi_wvalid(param_m_axi_wvalid),
        .pl_rstn(pl_rstn),
        .rf_adc0_clk_n(rf_adc0_clk_n),
        .rf_adc0_clk_p(rf_adc0_clk_p),
        .rf_adc_axis_rstn(rf_adc_axis_rstn),
        .rf_dac0_clk_n(rf_dac0_clk_n),
        .rf_dac0_clk_p(rf_dac0_clk_p),
        .rf_dac_axis_rstn(rf_dac_axis_rstn),
        .rf_m00_axis_tdata(rf_m00_axis_tdata),
        .rf_m00_axis_tready(rf_m00_axis_tready),
        .rf_m00_axis_tvalid(rf_m00_axis_tvalid),
        .rf_m01_axis_tdata(rf_m01_axis_tdata),
        .rf_m01_axis_tready(rf_m01_axis_tready),
        .rf_m01_axis_tvalid(rf_m01_axis_tvalid),
        .rf_m02_axis_tdata(rf_m02_axis_tdata),
        .rf_m02_axis_tready(rf_m02_axis_tready),
        .rf_m02_axis_tvalid(rf_m02_axis_tvalid),
        .rf_m03_axis_tdata(rf_m03_axis_tdata),
        .rf_m03_axis_tready(rf_m03_axis_tready),
        .rf_m03_axis_tvalid(rf_m03_axis_tvalid),
        .rf_s00_axis_tdata(rf_s00_axis_tdata),
        .rf_s00_axis_tready(rf_s00_axis_tready),
        .rf_s00_axis_tvalid(rf_s00_axis_tvalid),
        .rf_s02_axis_tdata(rf_s02_axis_tdata),
        .rf_s02_axis_tready(rf_s02_axis_tready),
        .rf_s02_axis_tvalid(rf_s02_axis_tvalid),
        .rf_sysref_in_diff_n(rf_sysref_in_diff_n),
        .rf_sysref_in_diff_p(rf_sysref_in_diff_p),
        .rf_vin0_01_v_n(rf_vin0_01_v_n),
        .rf_vin0_01_v_p(rf_vin0_01_v_p),
        .rf_vin0_23_v_n(rf_vin0_23_v_n),
        .rf_vin0_23_v_p(rf_vin0_23_v_p),
        .rf_vout00_v_n(rf_vout00_v_n),
        .rf_vout00_v_p(rf_vout00_v_p),
        .rf_vout02_v_n(rf_vout02_v_n),
        .rf_vout02_v_p(rf_vout02_v_p),
        .spi_clk(spi_clk),
        .spi_csn(spi_csn),
        .spi_miso(spi_miso),
        .spi_mosi(spi_mosi),
        .sys_clk_n(sys_clk_n),
        .sys_clk_p(sys_clk_p),
        .sys_rstn(sys_rstn));
endmodule
