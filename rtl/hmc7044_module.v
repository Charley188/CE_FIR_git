// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2023.2 (win64) Build 4029153 Fri Oct 13 20:14:34 MDT 2023
// Date        : Thu Jul 10 15:20:49 2025
// Host        : DESKTOP-3EHQVOH running 64-bit major release  (build 9200)
// Command     : write_verilog -mode synth_stub d:/netlist/hmc7044_module.v
// Design      : hmc7044_module
// Purpose     : Stub declaration of top-level module interface
// Device      : xczu47dr-ffve1156-2-i
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module hmc7044_module(clk, rst_n, hmc7044_dev_rdy, hmc7044_cfg_done,
  spi_sclk, spi_csn, spi_mosi, spi_miso)
/* synthesis syn_black_box black_box_pad_pin="rst_n,hmc7044_dev_rdy,hmc7044_cfg_done,spi_sclk,spi_csn,spi_mosi,spi_miso" */
/* synthesis syn_force_seq_prim="clk" */;
  input clk /* synthesis syn_isclock = 1 */;
  input rst_n;
  input hmc7044_dev_rdy;
  output hmc7044_cfg_done;
  output spi_sclk;
  output spi_csn;
  output spi_mosi;
  input spi_miso;
endmodule
