# create_clock -period 10.000 -name clk_pl_0 [get_pins {PS8_i/PLCLK[0]}]
create_clock -period 5.000 [get_ports ddr4_sys_clk_p]
create_clock -period 5.000 [get_ports sys_clk_p]

create_clock -period 3.333 -name single_bit_adc_refclk_p [get_ports single_bit_adc_refclk_p]
create_clock -period 100.000 -name hmc7044_sclk [get_ports hmc7044_sclk]

set_property -dict {PACKAGE_PIN E11 IOSTANDARD DIFF_HSTL_I_18} [get_ports sys_clk_p]
set_property -dict {PACKAGE_PIN E10 IOSTANDARD DIFF_HSTL_I_18} [get_ports pl_sysref_p]


set_property -dict {PACKAGE_PIN J12 IOSTANDARD LVCMOS33} [get_ports hmc7044_rst]
set_property -dict {PACKAGE_PIN H9 IOSTANDARD LVCMOS33} [get_ports hmc7044_sclk]
set_property -dict {PACKAGE_PIN H10 IOSTANDARD LVCMOS33} [get_ports hmc7044_csn]
set_property -dict {PACKAGE_PIN K11 IOSTANDARD LVCMOS33} [get_ports hmc7044_sdio]


#set_property -dict {PACKAGE_PIN F6 IOSTANDARD LVCMOS33} [get_ports {test_io_pl[0]}]
#set_property -dict {PACKAGE_PIN E6 IOSTANDARD LVCMOS33} [get_ports {test_io_pl[1]}]
#set_property -dict {PACKAGE_PIN E9 IOSTANDARD LVCMOS33} [get_ports {test_io_pl[2]}]
#set_property -dict {PACKAGE_PIN E8 IOSTANDARD LVCMOS33} [get_ports {test_io_pl[3]}]
#test_io5~8
#set_property -dict {PACKAGE_PIN C5 IOSTANDARD LVCMOS33} [get_ports {test_io_ps[0]}]
#set_property -dict {PACKAGE_PIN B5 IOSTANDARD LVCMOS33} [get_ports {test_io_ps[1]}]
#set_property -dict {PACKAGE_PIN A5 IOSTANDARD LVCMOS33} [get_ports {test_io_ps[2]}]
#set_property -dict {PACKAGE_PIN A7 IOSTANDARD LVCMOS33} [get_ports {test_io_ps[3]}]


set_property IOSTANDARD DIFF_SSTL12_DCI [get_ports ddr4_sys_clk_n]
set_property -dict {PACKAGE_PIN AL9 IOSTANDARD DIFF_SSTL12_DCI} [get_ports ddr4_sys_clk_p]

# A11	PL_DDR4_ALERT_B
# H8	PL_DDR4_PARITY

set_property -dict {PACKAGE_PIN AL11 IOSTANDARD SSTL12_DCI} [get_ports ddr4_act_n]
set_property -dict {PACKAGE_PIN AD17 IOSTANDARD LVCMOS12} [get_ports ddr4_reset_n]

set_property -dict {PACKAGE_PIN AJ9 IOSTANDARD SSTL12_DCI} [get_ports {ddr4_bg[0]}]
set_property -dict {PACKAGE_PIN AL12 IOSTANDARD SSTL12_DCI} [get_ports {ddr4_odt[0]}]
set_property -dict {PACKAGE_PIN AE11 IOSTANDARD SSTL12_DCI} [get_ports {ddr4_cs_n[0]}]
set_property -dict {PACKAGE_PIN AN9 IOSTANDARD SSTL12_DCI} [get_ports {ddr4_cke[0]}]

set_property -dict {PACKAGE_PIN AP7 IOSTANDARD SSTL12_DCI} [get_ports {ddr4_ba[0]}]
set_property -dict {PACKAGE_PIN AK13 IOSTANDARD SSTL12_DCI} [get_ports {ddr4_ba[1]}]

set_property -dict {PACKAGE_PIN AM11 IOSTANDARD DIFF_SSTL12_DCI} [get_ports {ddr4_ck_c[0]}]
#AM11
set_property -dict {PACKAGE_PIN AM12 IOSTANDARD DIFF_SSTL12_DCI} [get_ports {ddr4_ck_t[0]}]
#AM12

set_property -dict {PACKAGE_PIN AM14 IOSTANDARD POD12_DCI} [get_ports {ddr4_dm_n[0]}]
set_property -dict {PACKAGE_PIN AH13 IOSTANDARD POD12_DCI} [get_ports {ddr4_dm_n[1]}]
set_property -dict {PACKAGE_PIN AG15 IOSTANDARD POD12_DCI} [get_ports {ddr4_dm_n[2]}]
set_property -dict {PACKAGE_PIN AC13 IOSTANDARD POD12_DCI} [get_ports {ddr4_dm_n[3]}]
#set_property -dict {PACKAGE_PIN AP8 IOSTANDARD POD12_DCI} [get_ports {ddr4_dm_n[4]}]
#set_property -dict {PACKAGE_PIN AP13 IOSTANDARD POD12_DCI} [get_ports {ddr4_dm_n[5]}]

set_property -dict {PACKAGE_PIN AG11 IOSTANDARD SSTL12_DCI} [get_ports {ddr4_adr[0]}]
set_property -dict {PACKAGE_PIN AH12 IOSTANDARD SSTL12_DCI} [get_ports {ddr4_adr[1]}]
set_property -dict {PACKAGE_PIN AH9 IOSTANDARD SSTL12_DCI} [get_ports {ddr4_adr[2]}]
set_property -dict {PACKAGE_PIN AG12 IOSTANDARD SSTL12_DCI} [get_ports {ddr4_adr[3]}]
set_property -dict {PACKAGE_PIN AK11 IOSTANDARD SSTL12_DCI} [get_ports {ddr4_adr[4]}]
set_property -dict {PACKAGE_PIN AJ12 IOSTANDARD SSTL12_DCI} [get_ports {ddr4_adr[5]}]
set_property -dict {PACKAGE_PIN AJ10 IOSTANDARD SSTL12_DCI} [get_ports {ddr4_adr[6]}]
set_property -dict {PACKAGE_PIN AF10 IOSTANDARD SSTL12_DCI} [get_ports {ddr4_adr[7]}]
set_property -dict {PACKAGE_PIN AG10 IOSTANDARD SSTL12_DCI} [get_ports {ddr4_adr[8]}]
set_property -dict {PACKAGE_PIN AF11 IOSTANDARD SSTL12_DCI} [get_ports {ddr4_adr[9]}]

set_property -dict {PACKAGE_PIN AK10 IOSTANDARD SSTL12_DCI} [get_ports {ddr4_adr[10]}]
set_property -dict {PACKAGE_PIN AG9 IOSTANDARD SSTL12_DCI} [get_ports {ddr4_adr[11]}]
set_property -dict {PACKAGE_PIN AF12 IOSTANDARD SSTL12_DCI} [get_ports {ddr4_adr[12]}]
set_property -dict {PACKAGE_PIN AJ11 IOSTANDARD SSTL12_DCI} [get_ports {ddr4_adr[13]}]
set_property -dict {PACKAGE_PIN AK9 IOSTANDARD SSTL12_DCI} [get_ports {ddr4_adr[14]}]
set_property -dict {PACKAGE_PIN AL13 IOSTANDARD SSTL12_DCI} [get_ports {ddr4_adr[15]}]
set_property -dict {PACKAGE_PIN AP12 IOSTANDARD SSTL12_DCI} [get_ports {ddr4_adr[16]}]

set_property -dict {PACKAGE_PIN AP16 IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[0]}]
set_property -dict {PACKAGE_PIN AN18 IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[1]}]
set_property -dict {PACKAGE_PIN AP15 IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[2]}]
set_property -dict {PACKAGE_PIN AP17 IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[3]}]
set_property -dict {PACKAGE_PIN AN15 IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[4]}]
set_property -dict {PACKAGE_PIN AM17 IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[5]}]
set_property -dict {PACKAGE_PIN AM15 IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[6]}]
set_property -dict {PACKAGE_PIN AN17 IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[7]}]
set_property -dict {PACKAGE_PIN AK15 IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[8]}]
set_property -dict {PACKAGE_PIN AK18 IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[9]}]

set_property -dict {PACKAGE_PIN AK14 IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[10]}]
set_property -dict {PACKAGE_PIN AK16 IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[11]}]
set_property -dict {PACKAGE_PIN AJ16 IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[12]}]
set_property -dict {PACKAGE_PIN AL18 IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[13]}]
set_property -dict {PACKAGE_PIN AJ15 IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[14]}]
set_property -dict {PACKAGE_PIN AJ17 IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[15]}]
set_property -dict {PACKAGE_PIN AF13 IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[16]}]
set_property -dict {PACKAGE_PIN AF17 IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[17]}]
set_property -dict {PACKAGE_PIN AF14 IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[18]}]
set_property -dict {PACKAGE_PIN AG17 IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[19]}]

set_property -dict {PACKAGE_PIN AE16 IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[20]}]
set_property -dict {PACKAGE_PIN AF18 IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[21]}]
set_property -dict {PACKAGE_PIN AF16 IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[22]}]
set_property -dict {PACKAGE_PIN AH17 IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[23]}]
set_property -dict {PACKAGE_PIN AE15 IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[24]}]
set_property -dict {PACKAGE_PIN AC17 IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[25]}]
set_property -dict {PACKAGE_PIN AE14 IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[26]}]
set_property -dict {PACKAGE_PIN AD16 IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[27]}]
set_property -dict {PACKAGE_PIN AD15 IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[28]}]
set_property -dict {PACKAGE_PIN AE18 IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[29]}]

set_property -dict {PACKAGE_PIN AE13 IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[30]}]
set_property -dict {PACKAGE_PIN AD18 IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[31]}]
#set_property -dict {PACKAGE_PIN AP2 IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[32]}]
#set_property -dict {PACKAGE_PIN AM5 IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[33]}]
#set_property -dict {PACKAGE_PIN AP3 IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[34]}]
#set_property -dict {PACKAGE_PIN AP5 IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[35]}]
#set_property -dict {PACKAGE_PIN AN1 IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[36]}]
#set_property -dict {PACKAGE_PIN AM6 IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[37]}]
#set_property -dict {PACKAGE_PIN AN2 IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[38]}]
#set_property -dict {PACKAGE_PIN AP6 IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[39]}]

#set_property -dict {PACKAGE_PIN AM10 IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[40]}]
#set_property -dict {PACKAGE_PIN AP10 IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[41]}]
#set_property -dict {PACKAGE_PIN AN8 IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[42]}]
#set_property -dict {PACKAGE_PIN AP11 IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[43]}]
#set_property -dict {PACKAGE_PIN AN7 IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[44]}]
#set_property -dict {PACKAGE_PIN AN13 IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[45]}]
#set_property -dict {PACKAGE_PIN AN10 IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[46]}]
#set_property -dict {PACKAGE_PIN AN12 IOSTANDARD POD12_DCI} [get_ports {ddr4_dq[47]}]

#dqs_n
set_property -dict {PACKAGE_PIN AM16 IOSTANDARD DIFF_POD12_DCI} [get_ports {ddr4_dqs_c[0]}]
set_property -dict {PACKAGE_PIN AJ18 IOSTANDARD DIFF_POD12_DCI} [get_ports {ddr4_dqs_c[1]}]
set_property -dict {PACKAGE_PIN AH14 IOSTANDARD DIFF_POD12_DCI} [get_ports {ddr4_dqs_c[2]}]
set_property -dict {PACKAGE_PIN AC15 IOSTANDARD DIFF_POD12_DCI} [get_ports {ddr4_dqs_c[3]}]
#set_property -dict {PACKAGE_PIN AN4 IOSTANDARD DIFF_POD12_DCI} [get_ports {ddr4_dqs_c[4]}]
#set_property -dict {PACKAGE_PIN AM7 IOSTANDARD DIFF_POD12_DCI} [get_ports {ddr4_dqs_c[5]}]

#dqs_p
set_property -dict {PACKAGE_PIN AL17 IOSTANDARD DIFF_POD12_DCI} [get_ports {ddr4_dqs_t[0]}]
set_property -dict {PACKAGE_PIN AH18 IOSTANDARD DIFF_POD12_DCI} [get_ports {ddr4_dqs_t[1]}]
set_property -dict {PACKAGE_PIN AG14 IOSTANDARD DIFF_POD12_DCI} [get_ports {ddr4_dqs_t[2]}]
set_property -dict {PACKAGE_PIN AC16 IOSTANDARD DIFF_POD12_DCI} [get_ports {ddr4_dqs_t[3]}]
#set_property -dict {PACKAGE_PIN AN5 IOSTANDARD DIFF_POD12_DCI} [get_ports {ddr4_dqs_t[4]}]
#set_property -dict {PACKAGE_PIN AM8 IOSTANDARD DIFF_POD12_DCI} [get_ports {ddr4_dqs_t[5]}]

set_property -dict {PACKAGE_PIN C11 IOSTANDARD LVCMOS33} [get_ports single_bit_adc_rst]
set_property -dict {PACKAGE_PIN B10 IOSTANDARD LVCMOS33} [get_ports single_bit_adc_sclk]
set_property -dict {PACKAGE_PIN B11 IOSTANDARD LVCMOS33} [get_ports single_bit_adc_csn]
set_property -dict {PACKAGE_PIN C10 IOSTANDARD LVCMOS33} [get_ports single_bit_adc_miso]
set_property -dict {PACKAGE_PIN A10 IOSTANDARD LVCMOS33} [get_ports single_bit_adc_mosi]

set_property -dict {PACKAGE_PIN F12 IOSTANDARD LVCMOS33} [get_ports single_bit_adc_sync]

set_property -dict {PACKAGE_PIN C13 IOSTANDARD LVCMOS33} [get_ports rf_mw_sync]
set_property -dict {PACKAGE_PIN D12 IOSTANDARD LVCMOS33} [get_ports rf_mw_rx_det]
set_property -dict {PACKAGE_PIN E12 IOSTANDARD LVCMOS33} [get_ports rf_mw_r0_t0_sw]
set_property -dict {PACKAGE_PIN G11 IOSTANDARD LVCMOS33} [get_ports rf_mw_t1_sw]

set_property -dict {PACKAGE_PIN D13 IOSTANDARD LVCMOS33} [get_ports {rf_mw_freq_code[0]}]
set_property -dict {PACKAGE_PIN D14 IOSTANDARD LVCMOS33} [get_ports {rf_mw_freq_code[1]}]
set_property -dict {PACKAGE_PIN E14 IOSTANDARD LVCMOS33} [get_ports {rf_mw_freq_code[2]}]
set_property -dict {PACKAGE_PIN D9 IOSTANDARD LVCMOS33} [get_ports {rf_mw_freq_code[3]}]
set_property -dict {PACKAGE_PIN A9 IOSTANDARD LVCMOS33} [get_ports {rf_mw_freq_code[4]}]
set_property -dict {PACKAGE_PIN G10 IOSTANDARD LVCMOS33} [get_ports {rf_mw_freq_code[5]}]
set_property -dict {PACKAGE_PIN H13 IOSTANDARD LVCMOS33} [get_ports {rf_mw_freq_code[6]}]
set_property -dict {PACKAGE_PIN G12 IOSTANDARD LVCMOS33} [get_ports {rf_mw_freq_code[7]}]
set_property -dict {PACKAGE_PIN G13 IOSTANDARD LVCMOS33} [get_ports {rf_mw_freq_code[8]}]
set_property -dict {PACKAGE_PIN F13 IOSTANDARD LVCMOS33} [get_ports {rf_mw_freq_code[9]}]
set_property -dict {PACKAGE_PIN F14 IOSTANDARD LVCMOS33} [get_ports {rf_mw_freq_code[10]}]
set_property -dict {PACKAGE_PIN B12 IOSTANDARD LVCMOS33} [get_ports {rf_mw_freq_code[11]}]
set_property -dict {PACKAGE_PIN B13 IOSTANDARD LVCMOS33} [get_ports {rf_mw_freq_code[12]}]
set_property -dict {PACKAGE_PIN A13 IOSTANDARD LVCMOS33} [get_ports {rf_mw_freq_code[13]}]
set_property -dict {PACKAGE_PIN C14 IOSTANDARD LVCMOS33} [get_ports {rf_mw_freq_code[14]}]
set_property -dict {PACKAGE_PIN A14 IOSTANDARD LVCMOS33} [get_ports {rf_mw_freq_code[15]}]

set_property -dict {PACKAGE_PIN H28} [get_ports single_bit_adc_refclk_p]
set_property LOC GTYE4_CHANNEL_X0Y8 [get_cells {aad01s040g_module_inst/AAD01S040G_driver_inst/gty_inst/gtwizard_1_AAD01S040G_inst/inst/gen_gtwizard_gtye4_top.gtwizard_1_AAD01S040G_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[2].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST}]
set_property -dict {PACKAGE_PIN F33} [get_ports {single_bit_adc_rx_p[0]}]
set_property LOC GTYE4_CHANNEL_X0Y9 [get_cells {aad01s040g_module_inst/AAD01S040G_driver_inst/gty_inst/gtwizard_1_AAD01S040G_inst/inst/gen_gtwizard_gtye4_top.gtwizard_1_AAD01S040G_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[2].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[1].GTYE4_CHANNEL_PRIM_INST}]
set_property -dict {PACKAGE_PIN D33} [get_ports {single_bit_adc_rx_p[1]}]
set_property LOC GTYE4_CHANNEL_X0Y10 [get_cells {aad01s040g_module_inst/AAD01S040G_driver_inst/gty_inst/gtwizard_1_AAD01S040G_inst/inst/gen_gtwizard_gtye4_top.gtwizard_1_AAD01S040G_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[2].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[2].GTYE4_CHANNEL_PRIM_INST}]
set_property -dict {PACKAGE_PIN B33} [get_ports {single_bit_adc_rx_p[2]}]
set_property LOC GTYE4_CHANNEL_X0Y11 [get_cells {aad01s040g_module_inst/AAD01S040G_driver_inst/gty_inst/gtwizard_1_AAD01S040G_inst/inst/gen_gtwizard_gtye4_top.gtwizard_1_AAD01S040G_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[2].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[3].GTYE4_CHANNEL_PRIM_INST}]
set_property -dict {PACKAGE_PIN A31} [get_ports {single_bit_adc_rx_p[3]}]



connect_debug_port dbg_hub/clk [get_nets clk_out2_100M]
