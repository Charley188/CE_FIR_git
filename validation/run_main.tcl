set root [file normalize [file join [file dirname [info script]] ..]]
open_project $root/tb/ce_fir_tb.xpr
set_property verilog_define CE_SIM_FAST_RESET [get_filesets sim_1]
set_property xsim.simulate.custom_tcl $root/validation/run_all.tcl [get_filesets sim_1]
launch_simulation
close_sim
close_project
