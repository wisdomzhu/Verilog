`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
/*
Company : Liyang Milian Electronic Technology Co., Ltd.
Brand: 米联客(msxbo)
Technical forum：uisrc.com
taobao: osrc.taobao.com
Create Date: 2019/02/27 22:09:55
Module Name: uart_rx_path
Description: 
The serial port receiving module has a baud rate of 9600. It does 8 samplings in
each sampling cycle and has good anti-interference ability.
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


module uart_rx_5(
input clk_i,
input uart_rx_i,
output [7:0] uart_rx_data_o,
output uart_rx_done
 );
  
parameter [12:0] BAUD_DIV     = 13'd5207;//波特率时钟，9600bps，50Mhz/9600 - 1'b1=5207
parameter [12:0] BAUD_DIV_CAP = (BAUD_DIV/8 - 1'b1);//8次采样滤波去毛刺

reg [12:0] baud_div = 0;	//波特率设置计数器
reg bps_start_en = 0;		//波特率启动标志
//-----------数据传输时钟分频计数器
always@(posedge clk_i)begin
    if(bps_start_en && baud_div < BAUD_DIV)	
        baud_div <= baud_div + 1'b1;
    else 
        baud_div <= 13'd0;
end
//-----------每650个时钟计数一次
reg [12:0] samp_cnt = 0;
always@(posedge clk_i)begin
    if(bps_start_en && samp_cnt < BAUD_DIV_CAP)	
        samp_cnt <= samp_cnt + 1'b1;
    else 
        samp_cnt <= 13'd0;
end

//数据接收缓存器   
reg [4:0] uart_rx_i_r=5'b11111;			
always@(posedge clk_i)
	uart_rx_i_r<={uart_rx_i_r[3:0],uart_rx_i};
//数据接收缓存器，当连续接收到五个低电平时，即uart_rx_int=0时，作为接收到起始信号
wire uart_rx_int=uart_rx_i_r[4] | uart_rx_i_r[3] | uart_rx_i_r[2] | uart_rx_i_r[1] | uart_rx_i_r[0];
//states assign
parameter START = 4'd0;
parameter BIT0  = 4'd1;
parameter BIT1  = 4'd2;
parameter BIT2  = 4'd3;
parameter BIT3  = 4'd4;
parameter BIT4  = 4'd5;
parameter BIT5  = 4'd6;
parameter BIT6  = 4'd7;
parameter BIT7  = 4'd8;
parameter STOP  = 4'd9;

reg [3:0] RX_S = 4'd0;
wire bps_en = (baud_div == BAUD_DIV);
wire rx_start_fail;
always@(posedge clk_i)begin
    if(!uart_rx_int&&bps_start_en==1'b0) begin//开始传输
        bps_start_en <= 1'b1;
        RX_S <= START;
    end
    else if(rx_start_fail)begin
        bps_start_en <= 1'b0;
    end
    else if(bps_en)begin//每计满5028个时钟，切换状态
        case(RX_S)
            START:RX_S <= BIT0; //RX bit0
            BIT0: RX_S <= BIT1; //RX bit1
            BIT1: RX_S <= BIT2; //RX bit2
            BIT2: RX_S <= BIT3; //RX bit3
            BIT3: RX_S <= BIT4; //RX bit4
            BIT4: RX_S <= BIT5; //RX bit5
            BIT5: RX_S <= BIT6; //RX bit6
            BIT6: RX_S <= BIT7; //RX bit7
            BIT7: RX_S <= STOP; //RX STOP
            STOP: bps_start_en <= 1'b0;
            default: RX_S <= STOP;
        endcase  
    end
end    

//滤波采样,在每个波特率周期采样，samp_en一个周期内出现8次，rx_tmp初值，15为中间值，如果采样为1则增加，否则减少---------------也不一定是15，只要大于等于8即可
reg [4:0] rx_tmp = 5'd15;
reg [4:0] cap_cnt = 4'd0;//8次采样计数器
wire samp_en = (samp_cnt == BAUD_DIV_CAP);//采样使能---------每650个时钟采一次

always@(posedge clk_i)begin
    if(samp_en)begin
        cap_cnt <= cap_cnt + 1'b1;
        rx_tmp <= uart_rx_i_r[4] ? rx_tmp + 1'b1 :  rx_tmp - 1'b1;
    end
    else if(bps_en) begin //每次波特率时钟使能，重新设置rx_tmp初值为15
        rx_tmp <= 5'd15; 
        cap_cnt <= 4'd0;
    end
end
//当采样7次取值,大于16为采样1，小于16为采样0----------实现对该波特率周期所传输数据是0还是1的确定，可以消毛刺
reg cap_r = 1'b0;
wire cap_tmp = (cap_cnt == 3'd7); //采满8次，拉高cap_tmp
reg ap_tmp_r = 1'b0;
reg ap_tmp_r1 = 1'b0;
wire cap_en = (!ap_tmp_r1&&ap_tmp_r);//8次采样计数计满，采样使能有效
reg cap_en_r = 1'b0;
always@(posedge clk_i)begin//打两拍,cap_tmp信号跨时钟传输，慢到快
    ap_tmp_r  <= cap_tmp;
    ap_tmp_r1 <= ap_tmp_r;
    cap_en_r  <= cap_en;
end


always@(posedge clk_i)begin
    if(cap_en&&bps_start_en)begin
        cap_r <= (rx_tmp > 5'd15) ? 1 : 0;    
    end 
    else if(!bps_start_en)begin
        cap_r <= 1'b1;
    end
end

//以下状态机里面保存好数据
reg [7:0] rx = 8'd0;
reg start_bit = 1'b1;
always@(posedge clk_i)begin//每个状态要执行的任务
    if(cap_en_r)begin
        case(RX_S)
            BIT0: rx[0] <= cap_r;
            BIT1: rx[1] <= cap_r;
            BIT2: rx[2] <= cap_r;
            BIT3: rx[3] <= cap_r;
            BIT4: rx[4] <= cap_r;
            BIT5: rx[5] <= cap_r;
            BIT6: rx[6] <= cap_r;
            BIT7: rx[7] <= cap_r;
            default: rx <= rx; 
        endcase  
    end
end   

assign rx_start_fail = (RX_S == START)&&cap_en_r&&(cap_r == 1'b1);//--------已经开始传输数据了or bps_start_en使能无效
assign uart_rx_done = (RX_S == STOP)&& cap_en;//不是毛刺，是串转并结束的应答信号
assign uart_rx_data_o = rx;

endmodule

