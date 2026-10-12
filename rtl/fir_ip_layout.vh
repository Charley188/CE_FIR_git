// SSR=2, reloadable Non_Symmetric 300 taps: 48-bit AXI padding PER SAMPLE.
// Each real FIR has a 32-bit input and a 96-bit output.
`ifndef FIR_IP_LAYOUT_VH
`define FIR_IP_LAYOUT_VH
`define FIR_RE_TDATA_WIDTH 48
`define FIR_IM_TDATA_WIDTH 48
`endif
