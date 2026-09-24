set root [file normalize [file join [file dirname [info script]] ..]]
create_project online_check $root/validation/online_check -part xczu47dr-ffve1156-2-i -force
set_property XPM_LIBRARIES {XPM_CDC XPM_FIFO XPM_MEMORY} [current_project]
foreach n {ce_fir_coeff_control.sv ce_fir_reload.sv reset_sync_n.v complex_fir_calibration.v signed_saturate_16.v} {add_files $root/rtl/$n}
set_property include_dirs $root/rtl [get_filesets sources_1]
foreach n {fir_coef_re fir_coef_im} {add_files $root/ip/$n/$n.xci}
add_files -fileset sim_1 $root/validation/tb_online.sv
set_property top tb_online [get_filesets sim_1]
set_property xsim.simulate.runtime all [get_filesets sim_1]
set_property verilog_define CE_SIM_FAST_RESET [get_filesets sim_1]
set_property xsim.simulate.custom_tcl $root/validation/run_all.tcl [get_filesets sim_1]
launch_simulation
close_sim
close_project
