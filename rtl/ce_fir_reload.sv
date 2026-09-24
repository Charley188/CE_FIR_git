`timescale 1ns/1ps
// Natural-order staging; generated FIR reload order is tap 299 down to 0.
module ce_fir_reload(
 input wire clk,arst_n,update_hold,coeff_we,
 input wire [10:0] coeff_addr,
 input wire [17:0] coeff_re,coeff_im,
 output wire coeff_match,load_quiet,
 output reg running,ip_rst_n,
 output wire [3:0] reload_valid,config_valid,
 input wire [3:0] reload_ready,config_ready,
 output wire reload_last,
 output wire [23:0] reload_re,reload_im,
 input wire [3:0] reload_missing,reload_unexpected,
 output reg fault
);
 wire rst_n;
 reset_sync_n sync_reset(.clk(clk),.arst_n(arst_n),.srst_n(rst_n));
 reg [17:0] re_mem[0:299],im_mem[0:299];
 reg [8:0] index;
 reg [3:0] accepted;
 reg [2:0] state;
 reg [5:0] settle;
 reg [23:0] watchdog;
 localparam HOLD=0,RESET_WAIT=1,RELOAD=2,CONFIG=3,RUN=4,FAILED=5;
 wire [8:0] tap=9'd299-index;
 assign reload_re={6'b0,re_mem[tap]};
 assign reload_im={6'b0,im_mem[tap]};
 assign reload_valid=(state==RELOAD) ? ~accepted : 4'b0;
 assign config_valid=(state==CONFIG) ? ~accepted : 4'b0;
 assign reload_last=(index==299);
 assign coeff_match=(coeff_addr<300) && re_mem[coeff_addr]==coeff_re && im_mem[coeff_addr]==coeff_im;
 assign load_quiet=rst_n && update_hold && state==HOLD && !ip_rst_n;
 always @(posedge clk) begin
  if(coeff_we && load_quiet && coeff_addr<300) begin
   re_mem[coeff_addr]<=coeff_re;im_mem[coeff_addr]<=coeff_im;
  end
  if(!rst_n || update_hold) begin
   state<=HOLD;running<=0;ip_rst_n<=0;fault<=0;index<=0;accepted<=0;settle<=0;watchdog<=0;
  end else begin
   if(state!=RUN && state!=FAILED) watchdog<=watchdog+1'b1;
   if((|reload_missing) || (|reload_unexpected) || (&watchdog)) begin
    fault<=1;running<=0;state<=FAILED;
   end else case(state)
    HOLD:begin ip_rst_n<=1;state<=RESET_WAIT;end
    RESET_WAIT:if(settle==31) state<=RELOAD;else settle<=settle+1'b1;
    RELOAD:begin
     accepted<=accepted | reload_ready;
     if(&(accepted | reload_ready)) begin
      accepted<=0;
      if(index==299) state<=CONFIG;else index<=index+1'b1;
     end
    end
    CONFIG:begin
     accepted<=accepted | config_ready;
     if(&(accepted | config_ready)) begin accepted<=0;state<=RUN;running<=1;watchdog<=0;end
    end
    RUN:begin end
    default:begin running<=0;fault<=1;end
   endcase
  end
 end
endmodule
