`timescale 1ns/1ps
module tb_delay_comparison;
//inputs
reg sys_clk;
reg sys_rst_n;

reg data_i;
//outputs
wire data_blocking;
wire data_nonblocking;
wire data_combinatory;

//时钟激励
initial sys_clk=0;
always #10 sys_clk=~sys_clk;

//复位激励
initial begin
    sys_rst_n=1;
    #20;
    sys_rst_n=0;
    #20;
    sys_rst_n=1;
end

//信号输入
initial begin
  data_i=0;
  #30
  data_i=1;
end
delay_comparison uut(
    .sys_clk(sys_clk),
    .sys_rst_n(sys_rst_n),
    .data_i(data_i),

    .data_blocking(data_blocking),
    .data_nonblocking(data_nonblocking),
    .data_combinatory(data_combinatory)
);
endmodule