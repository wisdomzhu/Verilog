`timescale 1ns/1ps
module tb_spi_master;

//inputs
  reg sys_clk_i;
  reg sys_rst_n;

//outputs
  wire cs_o;
  wire scl_o;
  wire mosi_o;
  wire ldac_o;

//时钟激励
initial sys_clk_i=0;
always #10 sys_clk_i=~sys_clk_i;

//复位激励
initial begin 
    sys_rst_n=1;
    #20;
    sys_rst_n=0;
    #20;
    sys_rst_n=1;
end

//例化
spi_master uut(
    .sys_clk_i(sys_clk_i),
    .sys_rst_n(sys_rst_n),

    .cs_o(cs_o),
    .scl_o(scl_o),
    .mosi_o(mosi_o),
    .ldac_o(ldac_o)
);

endmodule