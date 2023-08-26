`timescale 1ns / 1ps
module tb_iic_master;
//inputs
reg clk_i;


reg [6:0]Slv_Addr_i;
reg [7:0]Reg_Addr_i;
reg [7:0]Data_i;

reg wr_i;

//outputs
wire scl;
wire [7:0]IIC_Read_Data;
wire sda;
wire oled_pclk_o;
wire oled_rst_o;

//时钟激励
initial clk_i=0;
always #10 clk_i=~clk_i;

//输入地址和数据
initial begin
    Slv_Addr_i=7'b1001011;
    Reg_Addr_i=8'b00110110;
    Data_i=8'b11000010;
end

//IIC开始
initial begin
    #40;
    wr_i=0;
end

iic_master uut(
    .clk_i(clk_i),

    .Slv_Addr_i(Slv_Addr_i),
    .Reg_Addr_i(Reg_Addr_i),
    .Data_i(Data_i),

    .wr_i(wr_i),

    .scl(scl),
    .IIC_Read_Data(IIC_Read_Data),
    .sda(sda),
    .oled_pclk_o(oled_pclk_o),
    .oled_rst_o(oled_rst_o)
);
endmodule