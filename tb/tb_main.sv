`timescale 1ns/1ps
`include "fir_ip_layout.vh"
// Main ADDA digital-chain test. Numerical comparison is performed in MATLAB mode 2.
module tb_main;
  localparam integer MAX_SAMPLES=1048576;
  reg adc_clk=0, alg_clk=0, dac_clk=0, rst_n=0;
  always #2.5 adc_clk=~adc_clk;
  always #2.5 alg_clk=~alg_clk;
  initial begin #0.73; forever #2.5 dac_clk=~dac_clk; end
  reg [15:0] adc_i=0,adc_q=0;
  reg adc_valid=0;
  wire i_ready,q_ready;
  wire [31:0] dac_data;
  wire dac_valid,overflow,underflow;
  reg dac_ready=0;
  `include "online_coeff_tb.vh"
  adda_first_path_chain dut (
    .update_hold(hold),.coeff_we(we),.coeff_addr(addr),.coeff_re(cr),.coeff_im(ci),
    .coeff_match(match),.load_quiet(quiet),.path_running(running),.reload_fault(fault),
    .clk_adc0(adc_clk),.clk_200m(alg_clk),.clk_dac0(dac_clk),
    .pl_rstn(rst_n),.rf_adc_axis_rstn(rst_n),.clk_200m_locked(rst_n),.rf_dac_axis_rstn(rst_n),
    .m00_axis_tdata(adc_i),.m00_axis_tvalid(adc_valid),.m00_axis_tready(i_ready),
    .m01_axis_tdata(adc_q),.m01_axis_tvalid(adc_valid),.m01_axis_tready(q_ready),
    .s00_axis_tdata(dac_data),.s00_axis_tvalid(dac_valid),.s00_axis_tready(dac_ready),
    .fifo_overflow(overflow),.fifo_underflow(underflow));
  // Exercise the second channel independently, including DAC backpressure.
  reg [15:0] bypass_i=0,bypass_q=0;
  reg bypass_valid=0;
  wire bypass_ir,bypass_qr,bypass_ov,bypass_uv,bypass_out_valid;
  wire [31:0] bypass_out;
  integer bypass_sent=0,bypass_received=0;
  reg bypass_done=0,bypass_prev_valid=0,bypass_prev_ready=0;
  reg [31:0] bypass_prev_data=0;
  ad_data_cdc bypass_dut (
    .clk_adc(adc_clk),.clk_dac(dac_clk),.arst_n(rst_n),
    .m0_axis_tdata(bypass_i),.m1_axis_tdata(bypass_q),
    .m0_axis_tvalid(bypass_valid),.m1_axis_tvalid(bypass_valid),
    .m0_axis_tready(bypass_ir),.m1_axis_tready(bypass_qr),
    .s_axis_tdata(bypass_out),.s_axis_tvalid(bypass_out_valid),
    .s_axis_tready(dac_ready),.overflow(bypass_ov),.underflow(bypass_uv));
  integer xi[0:MAX_SAMPLES-1],xq[0:MAX_SAMPLES-1];
  integer ns,fi,fq,fc,fd,ff,fo,fb,fs,rc,extra,j,b,l;
  integer sent=0,nd=0,nf=0,no=0,nb=0,cycles=0;
  integer ai,aq;
  integer max_join_count=0;
  reg loaded=0,input_done=0;
  reg prev_dac_valid=0,prev_dac_ready=0;
  reg [31:0] prev_dac_data=0;
  reg [31:0] rng=32'h12345678;
  string in_dir,out_dir;
  initial begin
    if (!$value$plusargs("INPUT_DIR=%s",in_dir)) $fatal(1,"Missing INPUT_DIR");
    if (!$value$plusargs("OUTPUT_DIR=%s",out_dir)) $fatal(1,"Missing OUTPUT_DIR");
    fs=$fopen({out_dir,"/tb_status.txt"},"w");
    if (!fs) $fatal(1,"Cannot open output directory");
    $fdisplay(fs,"RUNNING");$fclose(fs);
    fc=$fopen({in_dir,"/config.txt"},"r");
    if (!fc) $fatal(1,"Run MATLAB MAIN mode 1 first");
    rc=$fscanf(fc,"%d",ns);$fclose(fc);
    if (rc!=1 || ns<192 || ns>MAX_SAMPLES) $fatal(1,"Invalid sample count");
    fi=$fopen({in_dir,"/input_200_i.txt"},"r");
    fq=$fopen({in_dir,"/input_200_q.txt"},"r");
    if (!fi || !fq) $fatal(1,"Missing I/Q stimulus");
    for(j=0;j<ns;j=j+1) begin
      rc=$fscanf(fi,"%d",xi[j]);if(rc!=1) $fatal(1,"Invalid I row %0d",j);
      rc=$fscanf(fq,"%d",xq[j]);if(rc!=1) $fatal(1,"Invalid Q row %0d",j);
      if(xi[j]<-32768 || xi[j]>32767 || xq[j]<-32768 || xq[j]>32767) $fatal(1,"Input outside signed16");
    end
    if($fscanf(fi,"%d",extra)==1 || $fscanf(fq,"%d",extra)==1) $fatal(1,"Surplus input samples");
    $fclose(fi);$fclose(fq);
    fd=$fopen({out_dir,"/adc.txt"},"w");ff=$fopen({out_dir,"/fir.txt"},"w");
    fo=$fopen({out_dir,"/dac.txt"},"w");fb=$fopen({out_dir,"/dac_beats.txt"},"w");
    if(!fd || !ff || !fo || !fb) $fatal(1,"Cannot open result files");
    loaded=1;
  end
  initial begin
    wait(loaded);repeat(32) @(negedge adc_clk);rst_n=1;
    repeat(64) @(negedge adc_clk);
    repeat(64) @(negedge axi_clk); // XPM command/reply FIFO reset release
    load_coefficients();
    for(b=0;b<ns;b=b+1) begin
      adc_i=xi[b];adc_q=xq[b];
      adc_valid=1;
      @(posedge adc_clk);
      if ($test$plusargs("CONTINUOUS") && sent>32 && !(i_ready && q_ready)) $fatal(1,"Input throughput below one sample/cycle");
      while(!(i_ready && q_ready)) @(posedge adc_clk);
      sent=sent+1;
      @(negedge adc_clk);
    end
    adc_valid=0;input_done=1;
  end
  initial begin
    wait(loaded && rst_n);
    repeat(64) @(negedge adc_clk);
    for(integer k=0;k<ns;k=k+1) begin
      bypass_i=xi[k];bypass_q=xq[k];bypass_valid=1;
      @(posedge adc_clk);
      if ($test$plusargs("CONTINUOUS") && k>32 && !(bypass_ir && bypass_qr)) $fatal(1,"Bypass throughput below one sample/cycle");
      while(!(bypass_ir && bypass_qr)) @(posedge adc_clk);
      bypass_sent=bypass_sent+1;
      @(negedge adc_clk);
    end
    bypass_valid=0;bypass_done=1;
  end
  always @(posedge dac_clk) if(rst_n) begin
    if($test$plusargs("CONTINUOUS") && bypass_received>0 && bypass_received<ns && !bypass_out_valid) $fatal(1,"Bypass stream gap");
    if(bypass_ov || bypass_uv) $fatal(1,"Bypass FIFO fault");
    if(bypass_prev_valid && !bypass_prev_ready && (!bypass_out_valid || bypass_out!==bypass_prev_data)) $fatal(1,"Bypass changed under stall");
    if(bypass_out_valid && dac_ready) begin
      if(bypass_received>=ns) $fatal(1,"Extra bypass output");
      if($signed(bypass_out[15:0])!==xi[bypass_received] || $signed(bypass_out[31:16])!==xq[bypass_received]) $fatal(1,"Bypass sample/order mismatch %0d",bypass_received);
      bypass_received=bypass_received+1;
    end
    bypass_prev_valid<=bypass_out_valid;bypass_prev_ready<=dac_ready;bypass_prev_data<=bypass_out;
  end
  always @(negedge dac_clk) begin
    rng<={rng[30:0],rng[31]^rng[21]^rng[1]^rng[0]};
    dac_ready<=rst_n && ($test$plusargs("CONTINUOUS") || (rng[2:0]!=0));
  end
  always @(posedge adc_clk) if(rst_n) begin
    cycles=cycles+1;
    if(cycles>ns*100+100000) $fatal(1,"Timeout sent=%0d decim=%0d FIR=%0d DAC=%0d",sent,nd,nf,no);
    if($isunknown({i_ready,q_ready,overflow,underflow})) $fatal(1,"Unknown control");
    if(overflow || underflow) $fatal(1,"FIFO fault");
    if(adc_valid && (i_ready!==q_ready)) $fatal(1,"I/Q handshake split");
    if(dut.adc_pair_valid && dut.adc_fifo_ready) begin
      if($isunknown(dut.adc_pair_data) || nd>=ns) $fatal(1,"Invalid ADC output");
      $fdisplay(fd,"%0d %0d %0d",nd,$signed(dut.adc_pair_data[15:0]),$signed(dut.adc_pair_data[31:16]));nd=nd+1;
    end
  end
  always @(posedge alg_clk) if(rst_n) begin
    if(dut.fir_inst.core_inst.count_i_cr>max_join_count) max_join_count=dut.fir_inst.core_inst.count_i_cr;
    if(dut.fir_inst.core_inst.count_q_ci>max_join_count) max_join_count=dut.fir_inst.core_inst.count_q_ci;
    if(dut.fir_inst.core_inst.count_i_ci>max_join_count) max_join_count=dut.fir_inst.core_inst.count_i_ci;
    if(dut.fir_inst.core_inst.count_q_cr>max_join_count) max_join_count=dut.fir_inst.core_inst.count_q_cr;
    if(overflow || underflow) $fatal(1,"FIFO fault");
    if(dut.cal_valid && dut.cal_ready) begin
      if($isunknown(dut.cal_data) || nf>=ns) $fatal(1,"Invalid FIR output");
      $fdisplay(ff,"%0d %0d %0d",nf,$signed(dut.cal_data[15:0]),$signed(dut.cal_data[31:16]));nf=nf+1;
    end
  end
  always @(posedge dac_clk) if(rst_n) begin
    if($test$plusargs("CONTINUOUS") && no>0 && no<ns && !dac_valid) $fatal(1,"DAC stream gap");
    if($isunknown(dac_valid)) $fatal(1,"Unknown DAC valid");
    if(prev_dac_valid && !prev_dac_ready && (!dac_valid || dac_data!==prev_dac_data)) $fatal(1,"DAC changed under backpressure");
    if(dac_valid && dac_ready) begin
      if($isunknown(dac_data) || no>=ns) $fatal(1,"Invalid DAC output");
      $fwrite(fb,"%0d",nb);
      for(integer lane=0;lane<1;lane=lane+1) begin
        ai=$signed(dac_data[lane*32+:16]);aq=$signed(dac_data[lane*32+16+:16]);
        $fdisplay(fo,"%0d %0d %0d",no,ai,aq);$fwrite(fb," %0d %0d",ai,aq);no=no+1;
      end
      $fwrite(fb,"\n");nb=nb+1;
    end
    prev_dac_valid<=dac_valid;prev_dac_ready<=dac_ready;prev_dac_data<=dac_data;
  end
  initial begin
    wait(loaded);wait(no==ns && bypass_received==ns);
    repeat(64) @(negedge dac_clk);
    if(!bypass_done || bypass_sent!=ns || bypass_out_valid) $fatal(1,"Bypass drain mismatch");
    if(!input_done || sent!=ns || nd!=ns || nf!=ns || nb!=ns || dac_valid) $fatal(1,"Count/drain mismatch");
    $fclose(fd);$fclose(ff);$fclose(fo);$fclose(fb);
    fs=$fopen({out_dir,"/tb_status.txt"},"w");$fdisplay(fs,"PASS samples=%0d adc=%0d fir=%0d beats=%0d max_join=%0d",no,nd,nf,nb,max_join_count);$fclose(fs);
    $display("TB_MAIN_PASS samples=%0d; run MATLAB mode 2 for numerical comparison",no);$finish;
  end
endmodule
