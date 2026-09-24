`timescale 1ns/1ps
// Single-bank loader. One acknowledged command in flight; AXI itself never
// waits for the 200 MHz domain. Busy/full writes return SLVERR immediately.
module ce_fir_coeff_control #(
 parameter integer WAIT_CYCLES=3000000
)(
 input wire axi_clk,alg_clk,arst_n,
 input wire [39:0] s_awaddr,input wire s_awvalid,output wire s_awready,
 input wire [31:0] s_wdata,input wire [3:0] s_wstrb,input wire s_wvalid,output wire s_wready,
 output reg [1:0] s_bresp,output reg s_bvalid,input wire s_bready,
 input wire [39:0] s_araddr,input wire s_arvalid,output wire s_arready,
 output reg [31:0] s_rdata,output reg [1:0] s_rresp,output reg s_rvalid,input wire s_rready,
 output reg update_hold,output reg coeff_we,output reg coeff_channel,
 output reg [10:0] coeff_addr,output reg [17:0] coeff_re,coeff_im,
 input wire [1:0] coeff_match,load_quiet,path_running,path_fault
);
 wire axi_rst_n,alg_rst_n;
 ce_reset_sync ra(.clk(axi_clk),.arst_n(arst_n),.rst_n(axi_rst_n));
 ce_reset_sync rp(.clk(alg_clk),.arst_n(arst_n),.rst_n(alg_rst_n));
 localparam BOOT=0,QUIET=1,LOAD=2,SEALED=3,STARTING=4,RUN=5,ERROR=6;
 localparam IDLE=0,WAIT_QUIET=1,VERIFY=2,CRC=3,WAIT_RUN=4,REPLY=5;
 localparam E_STATE=1,E_INDEX=2,E_READBACK=3,E_COUNT=4,E_CRC=5,E_QUIET_TIMEOUT=6,E_START_TIMEOUT=7,E_FAULT=8,E_ABORT=9;
 wire cmd_full,cmd_empty,cwb,crb,rsp_full,rsp_empty,rwb,rrb;
 reg cmd_we; reg [127:0] cmd_din;
 wire [127:0] cmd_dout,rsp_dout;
 wire cmd_re; wire rsp_re=!rsp_empty && !rrb && axi_rst_n;
 wire rsp_we;
 wire [127:0] rsp_din;
 xpm_fifo_async #(.FIFO_MEMORY_TYPE("distributed"),.FIFO_WRITE_DEPTH(16),
   .WRITE_DATA_WIDTH(128),.READ_DATA_WIDTH(128),.READ_MODE("fwft"),.FIFO_READ_LATENCY(0),
   .WR_DATA_COUNT_WIDTH(5),.RD_DATA_COUNT_WIDTH(5),.USE_ADV_FEATURES("0000"),
   .CDC_SYNC_STAGES(3),.SIM_ASSERT_CHK(1),.PROG_FULL_THRESH(10),.PROG_EMPTY_THRESH(5)) commands(
   .rst(!axi_rst_n),.wr_clk(axi_clk),.rd_clk(alg_clk),.din(cmd_din),.wr_en(cmd_we && axi_rst_n && !cwb),
   .dout(cmd_dout),.rd_en(cmd_re),.full(cmd_full),.empty(cmd_empty),.wr_rst_busy(cwb),.rd_rst_busy(crb),
   .sleep(1'b0),.injectsbiterr(1'b0),.injectdbiterr(1'b0));
 xpm_fifo_async #(.FIFO_MEMORY_TYPE("distributed"),.FIFO_WRITE_DEPTH(16),
   .WRITE_DATA_WIDTH(128),.READ_DATA_WIDTH(128),.READ_MODE("fwft"),.FIFO_READ_LATENCY(0),
   .WR_DATA_COUNT_WIDTH(5),.RD_DATA_COUNT_WIDTH(5),.USE_ADV_FEATURES("0000"),
   .CDC_SYNC_STAGES(3),.SIM_ASSERT_CHK(1),.PROG_FULL_THRESH(10),.PROG_EMPTY_THRESH(5)) replies(
   .rst(!alg_rst_n),.wr_clk(alg_clk),.rd_clk(axi_clk),.din(rsp_din),.wr_en(rsp_we),
   .dout(rsp_dout),.rd_en(rsp_re),.full(rsp_full),.empty(rsp_empty),.wr_rst_busy(rwb),.rd_rst_busy(rrb),
   .sleep(1'b0),.injectsbiterr(1'b0),.injectdbiterr(1'b0));
 wire live_axi;
 xpm_cdc_single #(.DEST_SYNC_FF(3),.SRC_INPUT_REG(1),.SIM_ASSERT_CHK(1)) live_cdc(
   .src_clk(alg_clk),.src_in((&path_running) && !update_hold),.dest_clk(axi_clk),.dest_out(live_axi));
 reg busy,axi_error,aw_saved,w_saved;
 reg [15:0] awaddr;reg [31:0] wdata;reg [3:0] wstrb;
 reg [31:0] channel,index_reg,re_reg,im_reg,expected0,expected1;
 reg re_fresh,im_fresh;
 reg [127:0] snapshot;
 wire [7:0] snap_phase=snapshot[119:112];
 wire [31:0] status={16'b0,snap_phase,axi_error,snapshot[111],
   (snapshot[127:120]!=0 || axi_error),snapshot[110],live_axi,
   (snap_phase==SEALED),(snap_phase==LOAD),busy};
 assign s_awready=axi_rst_n && !aw_saved && !s_bvalid;
 assign s_wready=axi_rst_n && !w_saved && !s_bvalid;
 assign s_arready=axi_rst_n && !s_rvalid;
 wire write_fire=aw_saved && w_saved && !s_bvalid;
 wire submit=write_fire && (awaddr==16'h0004 || awaddr==16'h0020);
 wire push=awaddr==16'h0020;
 wire command_valid=push ? (wdata==1 && channel<1 && index_reg<300 && re_fresh && im_fresh) :
   (wdata==1 || wdata==3 || wdata==4 || wdata==5 || wdata==6);
 always @(posedge axi_clk) begin
   if(!axi_rst_n) begin
     busy<=0;axi_error<=0;aw_saved<=0;w_saved<=0;s_bvalid<=0;s_bresp<=0;s_rvalid<=0;s_rresp<=0;s_rdata<=0;
     cmd_we<=0;cmd_din<=0;channel<=0;index_reg<=0;re_reg<=0;im_reg<=0;expected0<=0;expected1<=0;
     re_fresh<=0;im_fresh<=0;snapshot<=(128'b1<<110);awaddr<=0;wdata<=0;wstrb<=0;
   end else begin
     cmd_we<=0;
     if(s_bvalid && s_bready) s_bvalid<=0;
     if(s_rvalid && s_rready) s_rvalid<=0;
     if(s_awvalid && s_awready) begin awaddr<=s_awaddr[15:0];aw_saved<=1;end
     if(s_wvalid && s_wready) begin wdata<=s_wdata;wstrb<=s_wstrb;w_saved<=1;end
     if(rsp_re) begin snapshot<=rsp_dout;busy<=0;end
     if(write_fire) begin
       aw_saved<=0;w_saved<=0;s_bvalid<=1;s_bresp<=0;
       if(wstrb!=4'hf || awaddr[1:0]!=0) begin s_bresp<=2;axi_error<=1;end
       else if(submit) begin
         if(busy || cmd_full || cwb || !command_valid) begin s_bresp<=2;axi_error<=1;end
         else begin
           cmd_din<={push ? 8'd2 : wdata[7:0],channel[0],index_reg[10:0],re_reg[17:0],im_reg[17:0],8'b0,expected0,expected1};
           cmd_we<=1;busy<=1;
           if(push) begin index_reg<=index_reg+1;re_fresh<=0;im_fresh<=0;end
           if(!push && wdata==1) begin axi_error<=0;channel<=0;index_reg<=0;re_fresh<=0;im_fresh<=0;end
         end
       end else if(busy) begin s_bresp<=2;axi_error<=1;end
       else case(awaddr)
         16'h0010: if(wdata<1) begin channel<=wdata;re_fresh<=0;im_fresh<=0;end else begin s_bresp<=2;axi_error<=1;end
         16'h0014: if(wdata<300) begin index_reg<=wdata;re_fresh<=0;im_fresh<=0;end else begin s_bresp<=2;axi_error<=1;end
         16'h0018: if(wdata[31:18]==0) begin re_reg<=wdata;re_fresh<=1;end else begin s_bresp<=2;axi_error<=1;end
         16'h001c: if(wdata[31:18]==0) begin im_reg<=wdata;im_fresh<=1;end else begin s_bresp<=2;axi_error<=1;end
         16'h0034: expected0<=wdata;
         16'h0038: expected1<=wdata;
         default: begin s_bresp<=2;axi_error<=1;end
       endcase
     end
     if(s_arvalid && s_arready) begin
       s_rvalid<=1;s_rresp<=0;s_rdata<=0;
       case(s_araddr[15:0])
         16'h0000:s_rdata<=32'h43465231; // CFR1
         16'h0008:s_rdata<=status;
         16'h000c:s_rdata<={23'b0,axi_error,snapshot[127:120]};
         16'h0010:s_rdata<=channel;
         16'h0014:s_rdata<=index_reg;
         16'h0024:s_rdata<={20'b0,snapshot[107:96]};
         16'h0028:s_rdata<={20'b0,snapshot[91:80]};
         16'h002c:s_rdata<=snapshot[63:32];
         16'h0030:s_rdata<=snapshot[31:0];
         16'h0034:s_rdata<=expected0;
         16'h0038:s_rdata<=expected1;
         default:s_rresp<=2;
       endcase
     end
   end
 end
 reg [2:0] state;reg [7:0] phase,error_code;
 reg valid_image,aborting;reg [31:0] timer;
 reg [11:0] count0,count1;reg [31:0] crc0,crc1,crc_work;
 reg [63:0] crc_bytes;reg [3:0] byte_index;
 wire [7:0] op=cmd_dout[127:120];wire ch=cmd_dout[119];wire [10:0] idx=cmd_dout[118:108];
 wire [17:0] re_value=cmd_dout[107:90],im_value=cmd_dout[89:72];
 assign cmd_re=(state==IDLE) && !cmd_empty && !crb && alg_rst_n;
 assign rsp_we=(state==REPLY) && !rsp_full && !rwb && alg_rst_n;
 assign rsp_din={error_code,phase,valid_image,update_hold,2'b0,count0,4'b0,count1,16'b0,~crc0,~crc1};
 function automatic [31:0] crc_byte(input [31:0] c,input [7:0] b);
   reg [31:0] t;begin t=c ^ b;for(integer n=0;n<8;n=n+1)t=t[0] ? (t>>1)^32'hedb88320 : t>>1;crc_byte=t;end
 endfunction
 wire [31:0] crc_next=crc_byte(crc_work,crc_bytes[7:0]);
 always @(posedge alg_clk) begin
   if(!alg_rst_n) begin
     state<=IDLE;phase<=BOOT;error_code<=0;update_hold<=1;valid_image<=0;aborting<=0;timer<=0;
     coeff_we<=0;coeff_channel<=0;coeff_addr<=0;coeff_re<=0;coeff_im<=0;
     count0<=0;count1<=0;crc0<=32'hffffffff;crc1<=32'hffffffff;crc_work<=0;crc_bytes<=0;byte_index<=0;
   end else begin
     coeff_we<=0;
     case(state)
       IDLE: if(cmd_re) begin
         state<=REPLY;
         case(op)
           1,5:begin
             update_hold<=1;valid_image<=0;count0<=0;count1<=0;crc0<=32'hffffffff;crc1<=32'hffffffff;
             error_code<=0;phase<=QUIET;timer<=0;aborting<=op==5;state<=WAIT_QUIET;
           end
           2:if(phase!=LOAD || !(&load_quiet)) begin error_code<=E_STATE;end
             else if((ch ? count1 : count0)!=idx || (ch ? count1 : count0)>=300) begin error_code<=E_INDEX;phase<=ERROR;end
             else begin
               coeff_channel<=ch;coeff_addr<=idx;coeff_re<=re_value;coeff_im<=im_value;coeff_we<=1;
               crc_work<=ch ? crc1 : crc0;crc_bytes<={14'b0,im_value,14'b0,re_value};byte_index<=0;timer<=0;state<=VERIFY;
             end
           3:if(phase!=LOAD) error_code<=E_STATE;
             else if(count0!=300) begin error_code<=E_COUNT;phase<=ERROR;end
             else if(cmd_dout[63:32]!=~crc0) begin error_code<=E_CRC;phase<=ERROR;end
             else begin phase<=SEALED;valid_image<=1;error_code<=0;end
           4:if(phase!=SEALED || !valid_image || error_code!=0) error_code<=E_STATE;
             else begin update_hold<=0;phase<=STARTING;timer<=0;state<=WAIT_RUN;end
           6:begin end // snapshot only
           default:error_code<=E_STATE;
         endcase
       end
       WAIT_QUIET:begin
         timer<=timer+1;
         if((&load_quiet) && timer>=32) begin phase<=aborting ? ERROR : LOAD;error_code<=aborting ? E_ABORT : 0;state<=REPLY;end
         else if(timer>=WAIT_CYCLES-1) begin phase<=ERROR;error_code<=E_QUIET_TIMEOUT;state<=REPLY;end
       end
       VERIFY:begin
         timer<=timer+1;
         if(timer==3) begin
           if(!(&load_quiet) || !coeff_match[coeff_channel]) begin error_code<=E_READBACK;phase<=ERROR;state<=REPLY;end
           else state<=CRC;
         end
       end
       CRC:begin
         crc_work<=crc_next;crc_bytes<=crc_bytes>>8;byte_index<=byte_index+1;
         if(byte_index==7) begin
           if(coeff_channel) begin count1<=count1+1;crc1<=crc_next;end
           else begin count0<=count0+1;crc0<=crc_next;end
           state<=REPLY;
         end
       end
       WAIT_RUN:begin
         timer<=timer+1;
         if(timer>=32 && |path_fault) begin update_hold<=1;error_code<=E_FAULT;phase<=ERROR;valid_image<=0;state<=REPLY;end
         else if(&path_running) begin phase<=RUN;state<=REPLY;end
         else if(timer>=WAIT_CYCLES-1) begin update_hold<=1;error_code<=E_START_TIMEOUT;phase<=ERROR;valid_image<=0;state<=REPLY;end
       end
       REPLY:if(rsp_we) state<=IDLE;
       default:begin update_hold<=1;phase<=ERROR;state<=IDLE;end
     endcase
   end
 end
endmodule

module ce_reset_sync(input wire clk,arst_n,output wire rst_n);
 (* ASYNC_REG="TRUE" *) reg [3:0] ff;
 always @(posedge clk or negedge arst_n)
   if(!arst_n) ff<=0; else ff<={ff[2:0],1'b1};
 assign rst_n=ff[3];
endmodule
