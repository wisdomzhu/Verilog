`timescale 1ns / 1ps
module tb_iic_master;
//inputs
reg clk_i;
reg reset_i;
reg flag_i;

reg [6:0]Slv_Addr_i;
reg [7:0]Reg_Addr_i;
reg [7:0]Data_i;

//outputs
wire scl;
wire sda;
wire ready_o;

//时钟激励50MHz
initial clk_i=0;
always #10 clk_i=~clk_i;

//输入地址和数据
initial begin
    Slv_Addr_i=7'b1001011;
    Reg_Addr_i=8'b00110110;
    Data_i=8'b11000010;
end

//reset_i
initial begin
    reset_i=0;
    #10;
    reset_i=1;
    #10;
    reset_i=0;
end

//flag_i
initial begin
    flag_i=0;
    #20;
    flag_i=1;
    #20;
    flag_i=0;
end
iic_master uut(
    .clk_i(clk_i),
    .flag_i(flag_i),
    .Slv_Addr_i(Slv_Addr_i),
    .Reg_Addr_i(Reg_Addr_i),
    .Data_i(Data_i),

    .scl(scl),
    .sda(sda),
    .ready_o(ready_o)
);
endmodule