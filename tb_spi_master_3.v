`timescale 1ns/1ps
module tb_spi_master;

//inputs
  reg sys_clk;
  reg sys_rst_n;

  reg busy;
  reg [3:0] addr;
  reg [15:0]data_in;

  reg spi_miso;
  reg spi_send;

//outputs
  wire spi_cs;
  wire spi_sck;
  wire spi_mosi;
  wire [23:0] data_out;
  wire send_done;

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

//miso激励
initial spi_miso=0;

//busy激励
initial busy=0;//让数据只传输一次,传完数据send_done=1

//输入数据
initial begin
    addr = 4'b0100;
    data_in = 16'b1110_0110_1011_0110;
end

//spi_send激励
initial begin
    spi_send = 0;
    #40;
    spi_send = 1;
end


//例化
spi_master uut(
    .sys_clk(sys_clk),
    .sys_rst_n(sys_rst_n),
    
    .busy(busy),
    .addr(addr),
    .data_in(data_in),

    .spi_miso(spi_miso),
    .spi_send(spi_send),


    .spi_cs(spi_cs),
    .spi_sck(spi_sck),
    .spi_mosi(spi_mosi),
    .data_out(data_out),
    .send_done(send_done)

);

endmodule