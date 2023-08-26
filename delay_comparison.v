`timescale 1ns/1ps
module delay_comparison (
input sys_clk,
input sys_rst_n,


input data_i,

//Synchronous
output data_nonblocking,
output data_blocking,

//Asynchronous
output data_combinatory
);

reg data_1;
reg data_1_r;
reg data_2;
reg data_2_r;
reg data_3;

always@(posedge sys_clk or negedge sys_rst_n) begin//不加begin end  只会执行always块的第一句
  if(~sys_rst_n)begin
  data_1<=0;
  data_1_r<=0;
  end
  else begin
  data_1<=data_i;
  data_1_r<=data_1;
  end
end
assign data_nonblocking=data_1_r;

always@(posedge sys_clk or negedge sys_rst_n) begin
  if(~sys_rst_n) begin
  data_2=0;
  data_2_r=data_2;
  end
  else begin
  data_2=data_i;
  data_2_r=data_2;
  end
end
assign data_blocking=data_2_r;

//只有在复位信号拉低时，输出为0，其他时候，和输入同步
always@(*)begin
  if(~sys_rst_n)
  data_3=0;
  else
  data_3=data_i;
end
assign data_combinatory=data_3;

//主要比较同步时序和异步时序
/*同步时序逻辑下
  非阻塞赋值：每赋值一次，延一拍
  阻塞赋值：赋值一次，延一拍；在同一条件下的行为语句，是同步的
  组合逻辑正对
*/
endmodule