 reg axi_clk=0;always #5 axi_clk=~axi_clk;
 reg [39:0] awaddr=0,araddr=0;
 reg awvalid=0,wvalid=0,bready=1,arvalid=0,rready=1;
 reg [31:0] wdata=0;
 wire awready,wready,bvalid,arready,rvalid;
 wire [1:0] bresp,rresp;wire [31:0] rdata;
 wire hold,we,ch,match,quiet,running,ip_rst,fault;
 wire [10:0] addr;wire [17:0] cr,ci;
 ce_fir_coeff_control ctrl(.axi_clk(axi_clk),.alg_clk(alg_clk),.arst_n(rst_n),
 .s_awaddr(awaddr),.s_awvalid(awvalid),.s_awready(awready),
 .s_wdata(wdata),.s_wstrb(4'hf),.s_wvalid(wvalid),.s_wready(wready),
 .s_bresp(bresp),.s_bvalid(bvalid),.s_bready(bready),
 .s_araddr(araddr),.s_arvalid(arvalid),.s_arready(arready),
 .s_rdata(rdata),.s_rresp(rresp),.s_rvalid(rvalid),.s_rready(rready),
 .update_hold(hold),.coeff_we(we),.coeff_channel(ch),.coeff_addr(addr),.coeff_re(cr),.coeff_im(ci),
 .coeff_match({1'b0,match}),.load_quiet({2{quiet}}),.path_running({2{running}}),.path_fault({1'b0,fault}));
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
 reg [17:0] image_re[0:299],image_im[0:299];
 task automatic load_coefficients;
 reg [31:0] crc,st;integer k;
 begin
  $readmemh({in_dir,"/h_re.mem"},image_re);$readmemh({in_dir,"/h_im.mem"},image_im);
  $display("Loading 300 complex FIR taps through AXI...");
  wr(4,1);idle(0);crc=32'hffffffff;
  for(k=0;k<300;k=k+1) begin
   if($isunknown({image_re[k],image_im[k]})) $fatal(1,"Missing/invalid FIR MEM row %0d",k);
   wr('h18,{14'b0,image_re[k]});wr('h1c,{14'b0,image_im[k]});wr('h20,1);idle(0);
   crc=crc_word(crc_word(crc,{14'b0,image_re[k]}),{14'b0,image_im[k]});
  end
  wr('h34,~crc);wr(4,3);idle(0);wr(4,4);idle(0);
  rd(8,st);if(!st[3]) $fatal(1,"FIR path did not start");
  $display("FIR coefficient load complete");
 end endtask
