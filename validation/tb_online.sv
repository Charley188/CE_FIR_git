`timescale 1ns/1ps
module tb_online;
 reg clk=0,axi_clk=0,rst=0;
 always #2.5 clk=~clk;
 always #5 axi_clk=~axi_clk;
 reg [39:0] awaddr=0,araddr=0;
 reg awvalid=0,wvalid=0,bready=1,arvalid=0,rready=1;
 reg [31:0] wdata=0;
 wire awready,wready,bvalid,arready,rvalid;
 wire [1:0] bresp,rresp;wire [31:0] rdata;
 wire hold,we,ch,match,quiet,running,ip_rst,fault;
 wire [10:0] addr;wire [17:0] cr,ci;
 wire [3:0] rv,rr,cv,cc,missing,unexpected;
 wire last;wire [23:0] re_data,im_data;
 reg in_valid=0;reg [31:0] in_data=0;
 wire in_ready,out_valid;wire [31:0] out_data;
 ce_fir_coeff_control ctrl(.axi_clk(axi_clk),.alg_clk(clk),.arst_n(rst),
 .s_awaddr(awaddr),.s_awvalid(awvalid),.s_awready(awready),
 .s_wdata(wdata),.s_wstrb(4'hf),.s_wvalid(wvalid),.s_wready(wready),
 .s_bresp(bresp),.s_bvalid(bvalid),.s_bready(bready),
 .s_araddr(araddr),.s_arvalid(arvalid),.s_arready(arready),
 .s_rdata(rdata),.s_rresp(rresp),.s_rvalid(rvalid),.s_rready(rready),
 .update_hold(hold),.coeff_we(we),.coeff_channel(ch),.coeff_addr(addr),.coeff_re(cr),.coeff_im(ci),
 .coeff_match({1'b0,match}),.load_quiet({2{quiet}}),.path_running({2{running}}),.path_fault({1'b0,fault}));
 ce_fir_reload loader(.clk(clk),.arst_n(rst),.update_hold(hold),.coeff_we(we),.coeff_addr(addr),.coeff_re(cr),.coeff_im(ci),
 .coeff_match(match),.load_quiet(quiet),.running(running),.ip_rst_n(ip_rst),.fault(fault),
 .reload_valid(rv),.reload_ready(rr),.config_valid(cv),.config_ready(cc),.reload_last(last),
 .reload_re(re_data),.reload_im(im_data),.reload_missing(missing),.reload_unexpected(unexpected));
 complex_fir_calibration dut(.clk(clk),.rst_n(running && !hold),.ip_rst_n(ip_rst),
 .reload_valid(rv),.reload_ready(rr),.config_valid(cv),.config_ready(cc),.reload_last(last),
 .reload_re(re_data),.reload_im(im_data),.reload_missing(missing),.reload_unexpected(unexpected),
 .in_valid(in_valid),.in_ready(in_ready),.in_data(in_data),.out_valid(out_valid),.out_data(out_data));
 task automatic wr(input integer a,input reg [31:0] d);
 begin
  @(negedge axi_clk);awaddr=a;awvalid=1;
  @(posedge axi_clk);while(!awready) @(posedge axi_clk);
  @(negedge axi_clk);awvalid=0;wdata=d;wvalid=1;
  @(posedge axi_clk);while(!wready) @(posedge axi_clk);
  @(negedge axi_clk);wvalid=0;
  @(posedge axi_clk);while(!bvalid) @(posedge axi_clk);
  if(bresp!=0) $fatal(1,"AXI write failed %h",a);
 end endtask
 task automatic rd(input integer a,output reg [31:0] d);
 begin
  @(negedge axi_clk);araddr=a;arvalid=1;
  @(posedge axi_clk);while(!arready) @(posedge axi_clk);
  @(negedge axi_clk);arvalid=0;
  @(posedge axi_clk);while(!rvalid) @(posedge axi_clk);
  if(rresp!=0) $fatal(1,"AXI read failed");d=rdata;
 end endtask
 task automatic idle(input bit expect_error);
 reg [31:0] st;integer n;
 begin
  st=1;n=0;
  while(st[0]) begin rd(8,st);n=n+1;if(n>100000) $fatal(1,"BUSY timeout");end
  if(st[5]!==expect_error) $fatal(1,"Unexpected status %h",st);
 end endtask
 function automatic [31:0] crc_word(input [31:0] c,input [31:0] d);
 reg [31:0] t;integer b,k;
 begin t=c;for(b=0;b<4;b=b+1) begin t=t ^ ((d>>(b*8)) & 255);for(k=0;k<8;k=k+1)t=t[0] ? (t>>1)^32'hedb88320 : t>>1;end crc_word=t;end endfunction
 integer hr[0:299],hi[0:299],xi[0:699],xq[0:699];
 reg [31:0] expected[0:699];integer received=0;
 function automatic [15:0] sat(input longint signed a);
 longint signed t;
 begin t=a>>>16;sat=t>32767 ? 16'h7fff : t< -32768 ? 16'h8000 : t[15:0];end endfunction
 task automatic load_image(input bit bad_crc);
 reg [31:0] crc,st;integer k;
 begin
  wr(4,1);idle(0);crc=32'hffffffff;
  for(k=0;k<300;k=k+1) begin
   wr('h18,hr[k]&'h3ffff);wr('h1c,hi[k]&'h3ffff);wr('h20,1);idle(0);
   crc=crc_word(crc_word(crc,hr[k]&'h3ffff),hi[k]&'h3ffff);
  end
  rd('h24,st);if(st!=300) $fatal(1,"Count mismatch");
  rd('h2c,st);if(st!=~crc) $fatal(1,"CRC readback mismatch");
  wr('h34,(~crc) ^ bad_crc);wr(4,3);idle(bad_crc);
  if(!bad_crc) begin wr(4,4);idle(0);rd(8,st);if(!st[3]) $fatal(1,"Not running");end
 end endtask
 task automatic samples;
 integer k,j;longint signed a,b;
 begin
  received=0;
  for(k=0;k<700;k=k+1) begin
   xi[k]=(k<400) ? ((k*137)%30001)-15000 : 0;
   xq[k]=(k<400) ? ((k*331)%28001)-14000 : 0;
   a=0;b=0;
   for(j=0;j<300;j=j+1) if(k>=j) begin
    a=a+longint'(xi[k-j])*hr[j]-longint'(xq[k-j])*hi[j];
    b=b+longint'(xi[k-j])*hi[j]+longint'(xq[k-j])*hr[j];
   end
   expected[k]={sat(b),sat(a)};
  end
  for(k=0;k<700;k=k+1) begin
   @(negedge clk);in_valid=1;in_data={16'(xq[k]),16'(xi[k])};
   @(posedge clk);while(!in_ready) @(posedge clk);
  end
  @(negedge clk);in_valid=0;
  wait(received==700);repeat(10) @(negedge clk);
 end endtask
 always @(posedge clk) if(out_valid) begin
  if(received>=700 || out_data!==expected[received]) $fatal(1,"Mismatch sample %0d got %h expected %h",received,out_data,expected[received]);
  received=received+1;
 end
 integer k;reg [31:0] v;
 initial begin
  repeat(30) @(negedge clk);rst=1;repeat(30) @(negedge axi_clk);
  rd(0,v);if(v!=32'h43465231) $fatal(1,"Wrong ID");
  wr(4,4);idle(1); // cannot start before a complete image
  wr(4,1);idle(0);wr(4,3);idle(1); // incomplete image
  for(k=0;k<300;k=k+1) begin hr[k]=0;hi[k]=0;end
  hr[0]=49152;hr[1]=8192;hr[2]=-4096;hi[0]=8192;hi[1]=-2048;hi[2]=1024;
  load_image(1);if(running) $fatal(1,"CRC failure enabled path");
  load_image(0);samples();$display("PASS complex three tap");
  for(k=0;k<300;k=k+1) begin hr[k]=(k%2) ? -500 : 600;hi[k]=(k%3) ? 700 : -800;end
  hr[299]=131071;hi[299]=-131072;
  load_image(0);samples();$display("PASS all 300 taps, signed extremes, online reload");
  wr(4,5);idle(1);if(running) $fatal(1,"Abort did not mute");
  $display("PASS ONLINE: AXI count/CRC/error/abort and real FIR numerical comparison");$finish;
 end
 initial begin #20000000;$fatal(1,"Test timeout");end
endmodule
