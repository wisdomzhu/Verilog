`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
/*
Company : Liyang Milian Electronic Technology Co., Ltd.
Brand: 米联客(msxbo)
Technical forum：uisrc.com
taobao: osrc.taobao.com
Create Date: 2019/02/27 22:09:55
Module Name: uart_top
Description: Serial port transmission and reception test, the data received by RX 
is sent through TX, and can be sent and received by the PC through the serial port 
debugging assistant.
Copyright: Copyright (c) msxbo
Revision: 1.0
Signal description：
1) _i input
2) _o output
3) _n activ low
4) _dg debug signal 
5) _r delay or register
6) _s state mechine
*/
////////////////////////////////////////////////////////////////////////////////


module uart_top(
	input clk_i,
	input uart_rx_i,
	output uart_tx_o
    );

wire [7:0] uart_rx_data_o;
wire uart_rx_done;
wire [7:0] true_data_o;
wire ver_done;

uart_rx_5 uart_rx_5_u (
    .clk_i(clk_i), 
    .uart_rx_i(uart_rx_i), 
    .uart_rx_data_o(uart_rx_data_o), 
    .uart_rx_done(uart_rx_done)
    );
    
uart_tx_5 uart_tx_5_u (
    .clk_i(clk_i), 
    .uart_tx_data_i(true_data_o), 
    .uart_tx_en_i(ver_done), 
    .uart_tx_o(uart_tx_o)
    );

uart_order_5 uart_order_5_u(
    .clk_i(clk_i),
    .rx_done(uart_rx_done),
    .rx_data_i(uart_rx_data_o),
    .ver_done(ver_done),
    .true_data_o(true_data_o)
);   
endmodule
