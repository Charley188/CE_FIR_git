set root [file normalize [file join [file dirname [info script]] ../..]]
foreach name {adda/project/ce_fir_adda.xpr tb/ce_fir_tb.xpr} {
 open_project $root/$name
 foreach n {ce_fir_coeff_control.sv ce_fir_reload.sv} {add_files $root/rtl/$n}
 set_property XPM_LIBRARIES {XPM_CDC XPM_FIFO XPM_MEMORY} [current_project]
 set_property include_dirs [list $root/rtl $root/tb] [get_filesets sources_1]
 set_property include_dirs [list $root/rtl $root/tb] [get_filesets sim_1]
 if {[string match tb/* $name]} {add_files -fileset sim_1 $root/tb/online_coeff_tb.vh}
 update_compile_order -fileset sources_1
 update_compile_order -fileset sim_1
 if {[string match adda/* $name]} {
  synth_design -rtl -name rtl_check -top sys_top -part xczu47dr-ffve1156-2-i
  close_design
 }
 close_project
}
puts ONLINE_PROJECTS_READY
