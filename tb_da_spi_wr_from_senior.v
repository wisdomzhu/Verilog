`timescale 1ns / 1ps
module tb_da_spi_wr;
//inputs
reg clk_i;
reg reset_i;

reg [15:0]voltage_data_i;

//outputs
wire sclk_o;
wire sdi_o;
wire cs_o;
wire voltage_data_start; 
wire ldac_o;

//时钟激励
initial clk_i=0;
always #10 clk_i=~clk_i;
 
//复位激励
initial begin
   reset_i=0;
   #20;
   reset_i=1;
   #20;
   reset_i=0;

end

//输入数据
initial begin
    voltage_data_i=16'b1000_0101_0110_1011;
end

da_spi_wr uut(
    .clk_i(clk_i),
    .reset_i(reset_i),
    .voltage_data_i(voltage_data_i),

    .sclk_o(sclk_o),
    .sdi_o(sdi_o),
    .cs_o(cs_o),
    .voltage_data_start(voltage_data_start),
    .ldac_o(ldac_o)

);
endmodule