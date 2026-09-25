# Usage: vivado -mode batch -source validation/run_rfdc24.tcl -tclargs <scratch-dir> [CONTINUOUS]
set root [file normalize [file join [file dirname [info script]] ..]]
if {$argc < 1} {error "Specify a disposable simulation directory"}
set scratch [file normalize [lindex $argv 0]]
create_project rfdc24_check $scratch -part xczu47dr-ffve1156-2-i -force
set_property XPM_LIBRARIES {XPM_CDC XPM_FIFO XPM_MEMORY} [current_project]
foreach n {adda_first_path_chain.v ad_data_cdc.v reset_sync_n.v complex_sample_async_fifo.v complex_fir_stream_buffer.v complex_fir_calibration.v signed_saturate_16.v ce_fir_reload.sv ce_fir_coeff_control.sv} {add_files $root/rtl/$n}
foreach n {fir_coef_re fir_coef_im} {add_files $root/ip/$n/$n.xci}
set_property include_dirs [list $root/rtl $root/tb] [get_filesets sources_1]
add_files -fileset sim_1 $root/tb/tb_main.sv
set_property include_dirs [list $root/rtl $root/tb] [get_filesets sim_1]
set_property top tb_main [get_filesets sim_1]
set_property verilog_define CE_SIM_FAST_RESET [get_filesets sim_1]
set opts "-testplusarg INPUT_DIR=$root/data/input -testplusarg OUTPUT_DIR=$root/data/output"
if {$argc > 1 && [lindex $argv 1] eq "CONTINUOUS"} {append opts " -testplusarg CONTINUOUS"}
set_property -dict [list xsim.simulate.xsim.more_options $opts] [get_filesets sim_1]
set_property xsim.simulate.custom_tcl $root/validation/run_all.tcl [get_filesets sim_1]
launch_simulation
close_sim
close_project
