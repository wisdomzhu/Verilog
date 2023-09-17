`timescale 1ns / 1ps
module uart_order_5(
  input clk_i,  
  input [7:0]rx_data_i,//-------连接uart_rx_data_o
  input rx_done,//-----------连接uart_rx_done
  output ver_done,//--------校验完毕，可以发送
  output [7:0]true_data_o 
);
//reg [2:0]flag_cnt=0;
reg [31:0] rx_data_r0=32'hAAAA_AAAA;
//reg [31:0] rx_data_r1=32'hAAAA_AAAA;
reg [7:0] true_data_r=8'hCC;
reg ver_done_r=0;
reg flag=0;

always @(posedge clk_i) begin
  if(rx_done) begin
    //flag_cnt<=flag_cnt+1;
    rx_data_r0<={rx_data_r0[23:0],rx_data_i};
    flag<=1;
  end
  /*if(flag_cnt>4) begin
    flag_cnt<=0;   
  end
*/
  else begin
    rx_data_r0<=rx_data_r0;
    flag<=flag;
end
end

/*
always @(posedge clk_i) begin
    if(flag_cnt==4)begin
      rx_data_r1<=rx_data_r0;
      ver_done_r<=1;
      if((rx_data_r1>=32'hFF00_0001)&&(rx_data_r1<=32'hFF00_0007))begin
         true_data_r<=8'hAA;
      end
      else begin
        true_data_r<=8'hCC;
      end
    end 
   else begin
       rx_data_r1<=rx_data_r1;
       ver_done_r<=0;
   end
end
*/

always @(posedge clk_i) begin
  if(flag)begin  
    if((rx_data_r0>=32'hFF00_0001)&&(rx_data_r0<=32'hFF00_0007))begin
      true_data_r<=8'hAA;
      ver_done_r<=1;
    end
    else begin
      true_data_r<=8'hCC;
      ver_done_r<=0;
  end
end
end
assign ver_done=ver_done_r;
assign true_data_o=true_data_r;
endmodule