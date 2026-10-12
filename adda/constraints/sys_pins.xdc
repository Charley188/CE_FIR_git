# Active sys_top board pins. RFDC package/clock constraints are supplied by its IP.
# Stale DDR, external-ADC and RF-switch constraints have been removed.
create_clock -period 5.000 [get_ports sys_clk_p]
create_clock -period 100.000 -name hmc7044_sclk [get_ports hmc7044_sclk]
set_property -dict {PACKAGE_PIN E11 IOSTANDARD DIFF_HSTL_I_18} [get_ports sys_clk_p]
set_property -dict {PACKAGE_PIN E10 IOSTANDARD DIFF_HSTL_I_18} [get_ports pl_sysref_p]
set_property -dict {PACKAGE_PIN J12 IOSTANDARD LVCMOS33} [get_ports hmc7044_rst]
set_property -dict {PACKAGE_PIN H9 IOSTANDARD LVCMOS33} [get_ports hmc7044_sclk]
set_property -dict {PACKAGE_PIN H10 IOSTANDARD LVCMOS33} [get_ports hmc7044_csn]
set_property -dict {PACKAGE_PIN K11 IOSTANDARD LVCMOS33} [get_ports hmc7044_sdio]

# Use the always-running 100 MHz control clock for the debug hub.
connect_debug_port dbg_hub/clk [get_nets clk_100M]

# The AXI SPI input register is behind the internal three-wire adapter, not an IOB.
set_property IOB FALSE [get_cells {design_1_wrapper_inst/design_1_i/axi_quad_spi_0/U0/NO_DUAL_QUAD_MODE.QSPI_NORMAL/IO0_I_REG}]
