`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/08/14 21:39:39
// Design Name: 
// Module Name: uart_tx
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module uart_tx_5(
	input 			clk_i,		
	input	[7:0] 	uart_tx_data_i,	//发送的8位数据
	input			uart_tx_en_i,	//发送使能信号
	output 			uart_tx_o	//串口发送数据线		

);

parameter 	SYS_CLK_FRE=50_000_000;    
parameter 	BPS=9_600;                 
localparam	BPS_CNT=SYS_CLK_FRE/BPS;   //传输一位数据所需要的时钟个数

reg uart_tx_r=1;
reg	uart_tx_en_d0=0;			//寄存1拍
reg uart_tx_en_d1=0;			//寄存2拍
reg tx_flag=0;				//发送标志位
reg [7:0]  uart_data_reg=8'd0;	//发送数据寄存器
reg [15:0] clk_cnt=16'd0;			//时钟计数器
reg [3:0]  tx_cnt=4'd0;			//发送个数计数器

wire pos_uart_en_txd;		//使能信号的上升沿

//捕捉使能端的上升沿信号，用来标志输出开始传输
assign pos_uart_en_txd= uart_tx_en_d0 && (~uart_tx_en_d1);

//使能信号打两拍
always @(posedge clk_i)begin
		uart_tx_en_d0<=uart_tx_en_i;
		uart_tx_en_d1<=uart_tx_en_d0;
end

//有使能信号上升沿就把数据给寄存器，发送信号置1
always @(posedge clk_i )begin
	 if(pos_uart_en_txd)begin
		uart_data_reg<=uart_tx_data_i;
		tx_flag<=1'b1;
	end
	else if((tx_cnt==4'd9) && (clk_cnt==BPS_CNT>>1))begin
		tx_flag<=1'b0;
		uart_data_reg<=8'd0;
	end
	else begin
		uart_data_reg<=uart_data_reg;
		tx_flag<=tx_flag;	
	end
end

//每一位的时钟计数以及发送了的位数的计数
always @(posedge clk_i )begin
      if(tx_flag) begin
		if(clk_cnt<BPS_CNT-1)begin
			clk_cnt<=clk_cnt+1'b1;
			tx_cnt <=tx_cnt;
		end
		else begin
			clk_cnt<=16'd0;
			tx_cnt <=tx_cnt+1'b1;
		end
	end
	else begin
		clk_cnt<=16'd0;
		tx_cnt<=4'd0;
	end
end

//在时钟计数为一半的时候一位位给出数据，并加上起始位和停止位
always @(posedge clk_i)begin
	 if(tx_flag)
		if(clk_cnt==BPS_CNT>>1) begin
		case(tx_cnt)
			4'd0:	uart_tx_r<=1'b0;//start
			4'd1:	uart_tx_r<=uart_data_reg[0];
			4'd2:	uart_tx_r<=uart_data_reg[1];
			4'd3:	uart_tx_r<=uart_data_reg[2];
			4'd4:	uart_tx_r<=uart_data_reg[3];
			4'd5:	uart_tx_r<=uart_data_reg[4];
			4'd6:	uart_tx_r<=uart_data_reg[5];
			4'd7:	uart_tx_r<=uart_data_reg[6];
			4'd8:	uart_tx_r<=uart_data_reg[7];
			4'd9:	uart_tx_r<=1'b1;//stop
			default:;
		endcase
		end
		else
			uart_tx_r<=uart_tx_r;
	else 	
		uart_tx_r<=1'b1;
end

assign 			uart_tx_o = uart_tx_r;

endmodule
