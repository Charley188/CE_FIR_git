set root [file normalize [file join [file dirname [info script]] ..]]
if {![info exists ::env(CE_TB_OPTIONS)]} {set ::env(CE_TB_OPTIONS) ""}
open_project $root/tb/ce_fir_tb.xpr
if {![llength [get_files -quiet */ad_data_cdc.v]]} {add_files $root/rtl/ad_data_cdc.v}
set_property -dict [list xsim.simulate.xsim.more_options "-testplusarg INPUT_DIR=$root/data/input -testplusarg OUTPUT_DIR=$root/data/output $::env(CE_TB_OPTIONS)"] [get_filesets sim_1]
set_property verilog_define CE_SIM_FAST_RESET [get_filesets sim_1]
set_property xsim.simulate.custom_tcl $root/validation/run_all.tcl [get_filesets sim_1]
launch_simulation
close_sim
close_project
