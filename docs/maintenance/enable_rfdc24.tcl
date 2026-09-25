# Run with Vivado 2023.2 after saving/closing the GUI project.
set root [file normalize [file join [file dirname [info script]] ../..]]
set obsolete {interp3_stage1.coe interp2_stage2_odd.coe interp2_stage3_odd.coe rfdc_8lane_decimator12.v complex_interp12_top.v interp3_ssr_wrapper.v halfband_interp2_ssr3_wrapper.v halfband_interp2_ssr6_wrapper.v gearbox_12to8.v complex_block_async_fifo.v da_data_cdc.v fifo_generator_0.xci interp12_ip_layout.vh interp3_stage1.xci interp2_stage2_odd.xci interp2_stage3_odd.xci}
foreach project {adda/project/ce_fir_adda.xpr tb/ce_fir_tb.xpr} {
    open_project $root/$project
    foreach name $obsolete {
        set files [get_files -quiet */$name]
        if {[llength $files]} {remove_files $files}
    }
    set_property include_dirs [list $root/rtl $root/tb] [get_filesets sources_1]
    set_property include_dirs [list $root/rtl $root/tb] [get_filesets sim_1]
    if {[string match adda/* $project]} {
        open_bd_design $root/adda/bd/design_1/design_1.bd
        set rf [get_bd_cells usp_rf_data_converter_0]
        foreach suffix {00 02} {
            set_property CONFIG.ADC_Decimation_Mode$suffix 24 $rf
            set_property CONFIG.DAC_Interpolation_Mode$suffix 24 $rf
            set_property CONFIG.ADC_Data_Width$suffix 1 $rf
            set_property CONFIG.DAC_Data_Width$suffix 2 $rf
        }
        set_property -dict [list CONFIG.ADC0_Refclk_Freq 300.000 CONFIG.DAC0_Refclk_Freq 300.000 CONFIG.ADC0_Outclk_Freq 300.000 CONFIG.DAC0_Outclk_Freq 300.000] $rf
        foreach cell {clk_wiz_adc clk_wiz_dac} {
            set_property -dict [list CONFIG.PRIM_IN_FREQ 300.000 CONFIG.CLKOUT1_REQUESTED_OUT_FREQ 200.000] [get_bd_cells $cell]
        }
        foreach port {rf_s00_axis rf_s02_axis} {set_property CONFIG.TDATA_NUM_BYTES 4 [get_bd_intf_ports $port]}
        # ADC master widths propagate from RFDC automatically.
        if {[llength [get_bd_ports -quiet clk_300M]]} {delete_bd_objs [get_bd_ports clk_300M]}
        validate_bd_design
        save_bd_design
        generate_target all [get_files $root/adda/bd/design_1/design_1.bd]
        set wrappers [make_wrapper -files [get_files $root/adda/bd/design_1/design_1.bd] -top]
        file copy -force [lindex $wrappers 0] $root/adda/design_1_wrapper.v
        generate_target all [get_ips {ila_adc fir_coef_re fir_coef_im}]
        update_compile_order -fileset sources_1
        synth_design -rtl -name rfdc24_rtl_check -top sys_top -part xczu47dr-ffve1156-2-i
        close_design
    } else {
        if {![llength [get_files -quiet */ad_data_cdc.v]]} {add_files $root/rtl/ad_data_cdc.v}
        set_property -dict [list xsim.simulate.xsim.more_options "-testplusarg INPUT_DIR=$root/data/input -testplusarg OUTPUT_DIR=$root/data/output"] [get_filesets sim_1]
    }
    close_project
}
puts RFDC24_PROJECTS_READY
