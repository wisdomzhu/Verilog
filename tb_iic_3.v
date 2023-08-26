`timescale 1ns / 1ps
module tb_iic_master;
//inputs
reg clk_i;
reg rst_i;

reg [6:0]Slv_Addr_i;
reg [7:0]Reg_Addr_i;
reg [7:0]Data_i;

reg wr_i;
reg send_i;

//outputs
wire scl;
wire [7:0]IIC_Read_Data;
wire sda;

//时钟激励
initial clk_i=0;
always #10 clk_i=~clk_i;

//复位激励
initial begin
    rst_i=1;
    #20;
    rst_i=0;
    #20;
    rst_i=1;
end

//输入地址和数据
initial begin
    Slv_Addr_i=7'b1001011;
    Reg_Addr_i=8'b00110110;
    Data_i=8'b11000010;
end

//IIC开始
initial begin
    #40;
    send_i=1;//一开始就从
    wr_i=0;
end

iic_master uut(
    .clk_i(clk_i),
    .rst_i(rst_i),

    .Slv_Addr_i(Slv_Addr_i),
    .Reg_Addr_i(Reg_Addr_i),
    .Data_i(Data_i),

    .wr_i(wr_i),
    .send_i(send_i),

    .scl(scl),
    .IIC_Read_Data(IIC_Read_Data),
    .sda(sda)
);
endmodule