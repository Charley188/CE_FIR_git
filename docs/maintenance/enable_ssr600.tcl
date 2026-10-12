# Vivado 2023.2: close the GUI projects before running this migration.
# Run from any directory: vivado -mode batch -source <this-file> [-tclargs FIR_ONLY]
set root [file normalize [file join [file dirname [info script]] ../..]]
set fir_only [expr {$argc>0 && [lindex $argv 0] eq "FIR_ONLY"}]
open_project $root/tb/ce_fir_tb.xpr
foreach name {fir_coef_re fir_coef_im} {
    set_property -dict [list CONFIG.Sample_Frequency 600 CONFIG.Clock_Frequency 300 \
        CONFIG.Number_Channels 1 CONFIG.Number_Paths 1 \
        CONFIG.RateSpecification Frequency_Specification \
        CONFIG.Coefficient_Reload true CONFIG.Coefficient_Structure Non_Symmetric \
        CONFIG.Optimization_Goal Speed \
        CONFIG.Multi_Column_Support Custom CONFIG.ColumnConfig {150,150}] [get_ips $name]
    generate_target all [get_ips $name]
    # This loader depends on the generated order and length; fail rather than silently misload.
    set order_file $root/ip/$name/generated/${name}_reload_order.txt
    if {![file exists $order_file]} {error "Missing generated reload order: $order_file"}
    set f [open $order_file r]; set lines [split [string trim [read $f]] \n]; close $f
    if {[llength $lines]!=300} {error "Unexpected reload length for $name"}
    for {set i 0} {$i<300} {incr i} {
        if {[string trim [lindex $lines $i]] ne "Reload index $i = Coefficient [expr {299-$i}]"} {
            error "Unexpected SSR reload order for $name at index $i"
        }
    }
}
set_property include_dirs [list $root/rtl $root/tb] [get_filesets sources_1]
set_property include_dirs [list $root/rtl $root/tb] [get_filesets sim_1]
update_compile_order -fileset sources_1
close_project
if {$fir_only} {puts SSR600_FIR_READY; exit}

open_project $root/adda/project/ce_fir_adda.xpr
open_bd_design $root/adda/bd/design_1/design_1.bd
set rf [get_bd_cells usp_rf_data_converter_0]
set rf_settings {}
foreach suffix {00 02} {
    lappend rf_settings CONFIG.ADC_Decimation_Mode$suffix 8 \
        CONFIG.DAC_Interpolation_Mode$suffix 8 \
        CONFIG.ADC_Data_Width$suffix 2 CONFIG.DAC_Data_Width$suffix 4
}
set_property -dict $rf_settings $rf
set_property -dict [list CONFIG.ADC0_Refclk_Freq 300.000 CONFIG.DAC0_Refclk_Freq 300.000 \
    CONFIG.ADC0_Outclk_Freq 300.000 CONFIG.DAC0_Outclk_Freq 300.000] $rf
foreach cell {clk_wiz_adc clk_wiz_dac} {
    set_property -dict [list CONFIG.PRIM_IN_FREQ 300.000 CONFIG.CLKOUT1_REQUESTED_OUT_FREQ 300.000] [get_bd_cells $cell]
}
# Preserve the existing clock source and its 100/10 MHz outputs; rename the algorithm clock.
set_property CONFIG.CLKOUT1_REQUESTED_OUT_FREQ 300.000 [get_bd_cells clk_wiz_1]
if {[llength [get_bd_ports -quiet clk_200M]]} {set_property name clk_300M [get_bd_ports clk_200M]}
if {[llength [get_bd_ports -quiet clk_200m_locked]]} {set_property name clk_300m_locked [get_bd_ports clk_200m_locked]}
foreach {port_name source_pin} {
    clk_300M clk_wiz_dac/clk_out1
    clk_300m_locked clk_wiz_dac/locked
} {
    set port [get_bd_ports $port_name]
    set pin [get_bd_pins $source_pin]
    set old_net [get_bd_nets -quiet -of_objects $port]
    set target_net [get_bd_nets -quiet -of_objects $pin]
    if {$old_net ne $target_net} {
        if {[llength $old_net]} {disconnect_bd_net $old_net $port}
        connect_bd_net -net $target_net $port $pin
    }
}
foreach port {rf_s00_axis rf_s02_axis} {set_property CONFIG.TDATA_NUM_BYTES 8 [get_bd_intf_ports $port]}
validate_bd_design
save_bd_design
generate_target all [get_files $root/adda/bd/design_1/design_1.bd]
set wrappers [make_wrapper -files [get_files $root/adda/bd/design_1/design_1.bd] -top]
file copy -force [lindex $wrappers 0] $root/adda/design_1_wrapper.v
set_property include_dirs [list $root/rtl $root/tb] [get_filesets sources_1]
update_compile_order -fileset sources_1
synth_design -rtl -name ssr600_rtl_check -top sys_top -part xczu47dr-ffve1156-2-i
close_design
close_project
puts SSR600_PROJECTS_READY
