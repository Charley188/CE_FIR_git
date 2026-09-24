set root [file normalize [file join [file dirname [info script]] ../..]]
open_project $root/adda/project/ce_fir_adda.xpr
add_files $root/rtl/ce_nco_vio_ctrl.v
open_bd_design $root/adda/bd/design_1/design_1.bd
set_property -dict [list CONFIG.ADC_Mixer_Type00 {2} CONFIG.ADC_Mixer_Type02 {2} CONFIG.ADC_NCO_Freq00 {1.2} CONFIG.ADC_NCO_Freq02 {1.2} CONFIG.ADC_NCO_RTS {true} CONFIG.DAC_Mixer_Type00 {2} CONFIG.DAC_Mixer_Type02 {2} CONFIG.DAC_NCO_Freq00 {-1.2} CONFIG.DAC_NCO_Freq02 {-1.2} CONFIG.DAC_NCO_RTS {true}] [get_bd_cells usp_rf_data_converter_0]
create_bd_cell -type module -reference ce_nco_vio_ctrl nco_adc_ctrl
set_property -dict [list CONFIG.BUSY_WIDTH {1}] [get_bd_cells nco_adc_ctrl]
create_bd_cell -type ip -vlnv xilinx.com:ip:vio:3.0 vio_adc_freq
set_property -dict [list CONFIG.C_NUM_PROBE_IN {4} CONFIG.C_NUM_PROBE_OUT {4} CONFIG.C_PROBE_OUT0_INIT_VAL {0x400000000000} CONFIG.C_PROBE_OUT0_WIDTH {48} CONFIG.C_PROBE_OUT1_INIT_VAL {0x400000000000} CONFIG.C_PROBE_OUT1_WIDTH {48} CONFIG.C_PROBE_OUT2_INIT_VAL {0x3} CONFIG.C_PROBE_OUT2_WIDTH {2} CONFIG.C_PROBE_OUT3_WIDTH {1}] [get_bd_cells vio_adc_freq]
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 adc0_01_phase_zero
set_property -dict [list CONFIG.CONST_VAL {0} CONFIG.CONST_WIDTH {18}] [get_bd_cells adc0_01_phase_zero]
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 adc0_01_phase_rst_zero
set_property -dict [list CONFIG.CONST_VAL {0} CONFIG.CONST_WIDTH {1}] [get_bd_cells adc0_01_phase_rst_zero]
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 adc0_23_phase_zero
set_property -dict [list CONFIG.CONST_VAL {0} CONFIG.CONST_WIDTH {18}] [get_bd_cells adc0_23_phase_zero]
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 adc0_23_phase_rst_zero
set_property -dict [list CONFIG.CONST_VAL {0} CONFIG.CONST_WIDTH {1}] [get_bd_cells adc0_23_phase_rst_zero]
create_bd_cell -type module -reference ce_nco_vio_ctrl nco_dac_ctrl
set_property -dict [list CONFIG.BUSY_WIDTH {2}] [get_bd_cells nco_dac_ctrl]
create_bd_cell -type ip -vlnv xilinx.com:ip:vio:3.0 vio_dac_freq
set_property -dict [list CONFIG.C_NUM_PROBE_IN {4} CONFIG.C_NUM_PROBE_OUT {4} CONFIG.C_PROBE_OUT0_INIT_VAL {0xc00000000000} CONFIG.C_PROBE_OUT0_WIDTH {48} CONFIG.C_PROBE_OUT1_INIT_VAL {0xc00000000000} CONFIG.C_PROBE_OUT1_WIDTH {48} CONFIG.C_PROBE_OUT2_INIT_VAL {0x3} CONFIG.C_PROBE_OUT2_WIDTH {2} CONFIG.C_PROBE_OUT3_WIDTH {1}] [get_bd_cells vio_dac_freq]
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 dac00_phase_zero
set_property -dict [list CONFIG.CONST_VAL {0} CONFIG.CONST_WIDTH {18}] [get_bd_cells dac00_phase_zero]
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 dac00_phase_rst_zero
set_property -dict [list CONFIG.CONST_VAL {0} CONFIG.CONST_WIDTH {1}] [get_bd_cells dac00_phase_rst_zero]
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 dac02_phase_zero
set_property -dict [list CONFIG.CONST_VAL {0} CONFIG.CONST_WIDTH {18}] [get_bd_cells dac02_phase_zero]
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 dac02_phase_rst_zero
set_property -dict [list CONFIG.CONST_VAL {0} CONFIG.CONST_WIDTH {1}] [get_bd_cells dac02_phase_rst_zero]
connect_bd_net [get_bd_pins adc0_01_phase_rst_zero/dout] [get_bd_pins usp_rf_data_converter_0/adc0_01_nco_phase_rst]
connect_bd_net [get_bd_pins adc0_01_phase_zero/dout] [get_bd_pins usp_rf_data_converter_0/adc0_01_nco_phase]
connect_bd_net [get_bd_pins adc0_23_phase_rst_zero/dout] [get_bd_pins usp_rf_data_converter_0/adc0_23_nco_phase_rst]
connect_bd_net [get_bd_pins adc0_23_phase_zero/dout] [get_bd_pins usp_rf_data_converter_0/adc0_23_nco_phase]
connect_bd_net [get_bd_pins clk_wiz_1/clk_out2_100M] [get_bd_ports clk_100M] [get_bd_pins axi_quad_spi_0/ext_spi_clk] [get_bd_pins axi_quad_spi_0/s_axi_aclk] [get_bd_pins rst_ps8_0_100M/slowest_sync_clk] [get_bd_pins usp_rf_data_converter_0/s_axi_aclk] [get_bd_pins zynq_ultra_ps_e_0/maxihpm0_lpd_aclk] [get_bd_pins system_ila_0/clk] [get_bd_pins axi_interconnect_0/ACLK] [get_bd_pins axi_interconnect_0/S00_ACLK] [get_bd_pins axi_interconnect_0/M00_ACLK] [get_bd_pins axi_interconnect_0/M01_ACLK] [get_bd_pins axi_interconnect_0/M02_ACLK] [get_bd_pins vio_adc_freq/clk] [get_bd_pins vio_dac_freq/clk] [get_bd_pins nco_adc_ctrl/clk] [get_bd_pins nco_dac_ctrl/clk]
connect_bd_net [get_bd_pins dac00_phase_rst_zero/dout] [get_bd_pins usp_rf_data_converter_0/dac00_nco_phase_rst]
connect_bd_net [get_bd_pins dac00_phase_zero/dout] [get_bd_pins usp_rf_data_converter_0/dac00_nco_phase]
connect_bd_net [get_bd_pins dac02_phase_rst_zero/dout] [get_bd_pins usp_rf_data_converter_0/dac02_nco_phase_rst]
connect_bd_net [get_bd_pins dac02_phase_zero/dout] [get_bd_pins usp_rf_data_converter_0/dac02_nco_phase]
connect_bd_net [get_bd_pins nco_adc_ctrl/completed_count] [get_bd_pins vio_adc_freq/probe_in1]
connect_bd_net [get_bd_pins nco_adc_ctrl/nco_en0] [get_bd_pins usp_rf_data_converter_0/adc0_01_nco_update_en]
connect_bd_net [get_bd_pins nco_adc_ctrl/nco_en1] [get_bd_pins usp_rf_data_converter_0/adc0_23_nco_update_en]
connect_bd_net [get_bd_pins nco_adc_ctrl/nco_freq0] [get_bd_pins vio_adc_freq/probe_in2] [get_bd_pins usp_rf_data_converter_0/adc0_01_nco_freq]
connect_bd_net [get_bd_pins nco_adc_ctrl/nco_freq1] [get_bd_pins vio_adc_freq/probe_in3] [get_bd_pins usp_rf_data_converter_0/adc0_23_nco_freq]
connect_bd_net [get_bd_pins nco_adc_ctrl/nco_req] [get_bd_pins usp_rf_data_converter_0/adc0_nco_update_req]
connect_bd_net [get_bd_pins nco_adc_ctrl/status] [get_bd_pins vio_adc_freq/probe_in0]
connect_bd_net [get_bd_pins nco_dac_ctrl/completed_count] [get_bd_pins vio_dac_freq/probe_in1]
connect_bd_net [get_bd_pins nco_dac_ctrl/nco_en0] [get_bd_pins usp_rf_data_converter_0/dac00_nco_update_en]
connect_bd_net [get_bd_pins nco_dac_ctrl/nco_en1] [get_bd_pins usp_rf_data_converter_0/dac02_nco_update_en]
connect_bd_net [get_bd_pins nco_dac_ctrl/nco_freq0] [get_bd_pins vio_dac_freq/probe_in2] [get_bd_pins usp_rf_data_converter_0/dac00_nco_freq]
connect_bd_net [get_bd_pins nco_dac_ctrl/nco_freq1] [get_bd_pins vio_dac_freq/probe_in3] [get_bd_pins usp_rf_data_converter_0/dac02_nco_freq]
connect_bd_net [get_bd_pins nco_dac_ctrl/nco_req] [get_bd_pins usp_rf_data_converter_0/dac0_nco_update_req]
connect_bd_net [get_bd_pins nco_dac_ctrl/status] [get_bd_pins vio_dac_freq/probe_in0]
connect_bd_net [get_bd_pins rst_ps8_0_100M/peripheral_aresetn] [get_bd_pins axi_quad_spi_0/s_axi_aresetn] [get_bd_pins clk_wiz_adc/resetn] [get_bd_pins clk_wiz_dac/resetn] [get_bd_pins usp_rf_data_converter_0/s_axi_aresetn] [get_bd_pins system_ila_0/resetn] [get_bd_pins axi_interconnect_0/ARESETN] [get_bd_pins axi_interconnect_0/S00_ARESETN] [get_bd_pins axi_interconnect_0/M00_ARESETN] [get_bd_pins axi_interconnect_0/M01_ARESETN] [get_bd_pins axi_interconnect_0/M02_ARESETN] [get_bd_pins nco_adc_ctrl/rst_n] [get_bd_pins nco_dac_ctrl/rst_n]
connect_bd_net [get_bd_pins usp_rf_data_converter_0/adc0_nco_update_busy] [get_bd_pins nco_adc_ctrl/nco_busy]
connect_bd_net [get_bd_pins usp_rf_data_converter_0/dac0_nco_update_busy] [get_bd_pins nco_dac_ctrl/nco_busy]
connect_bd_net [get_bd_pins vio_adc_freq/probe_out0] [get_bd_pins nco_adc_ctrl/freq0]
connect_bd_net [get_bd_pins vio_adc_freq/probe_out1] [get_bd_pins nco_adc_ctrl/freq1]
connect_bd_net [get_bd_pins vio_adc_freq/probe_out2] [get_bd_pins nco_adc_ctrl/channel_mask]
connect_bd_net [get_bd_pins vio_adc_freq/probe_out3] [get_bd_pins nco_adc_ctrl/apply_toggle]
connect_bd_net [get_bd_pins vio_dac_freq/probe_out0] [get_bd_pins nco_dac_ctrl/freq0]
connect_bd_net [get_bd_pins vio_dac_freq/probe_out1] [get_bd_pins nco_dac_ctrl/freq1]
connect_bd_net [get_bd_pins vio_dac_freq/probe_out2] [get_bd_pins nco_dac_ctrl/channel_mask]
connect_bd_net [get_bd_pins vio_dac_freq/probe_out3] [get_bd_pins nco_dac_ctrl/apply_toggle]
validate_bd_design
save_bd_design
generate_target all [get_files design_1.bd]
set wrappers [make_wrapper -files [get_files design_1.bd] -top]
file copy -force [lindex $wrappers 0] $root/adda/design_1_wrapper.v
close_project
