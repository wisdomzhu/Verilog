`timescale 1ns / 1ps
//
// Company: 
// Engineer: 
// 
// Create Date: 2021/09/14 19:45:40
// Design Name: 
// Module Name: IIC_CODE
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
//


module IIC_Code(

	input wire clk_i,
	input wire rst_i,
	input wire send_i,					//IIC开始信号
	input wire wr_i,					//读写控制信号，1为写，0为读
	input wire [6:0] Slv_Addr_i,			//从机的地址数据
	input wire [7:0] Reg_Addr_i,			//寄存器的地址数据
	input wire [7:0] Data_i,				//将要写入的数据
	output reg IIC_Busy_o,				//IIC工作标志信号
	output reg [7:0] IIC_Read_Data_o,		//IIC读出来的数据
	inout wire sda,
	inout wire scl
    );

parameter DIV = 2500;					//分频计数器的分频系数
parameter T1 = DIV / 4;					//第一个标志位
parameter T2 = DIV *3/4;				//第二个标志位

reg [11:0] cnt_clk;						//clk计数器
reg [3:0] cnt_scl;						//scl计数器，表示传送数据的位数
reg sda_tri;							//三态控制信号
reg sda_o;								//sda总线传输数据的寄存器
reg scl_o;								//scl时钟总线
reg [4:0] current_state;				//当前状态
reg [4:0] next_state;					//下个状态

assign sda = sda_tri ? 1'bz : sda_o;
assign scl = scl_o;

parameter IDLE 			= 5'd0;
parameter W_START 		= 5'd1;
parameter W_SLV_ADDR 	= 5'd2;
parameter W_WR 			= 5'd3;
parameter W_ACK1 		= 5'd4;
parameter W_REG_ADDR 	= 5'd5;
parameter W_ACK2 		= 5'd6;
parameter W_DATA 		= 5'd7;
parameter W_ACK3 		= 5'd8;
parameter W_STOP 		= 5'd9;
parameter R_START1 		= 5'd10;
parameter R_SLV_ADDR1	= 5'd11;
parameter R_WR1			= 5'd12;
parameter R_ACK1		= 5'd13;
parameter R_REG_ADDR	= 5'd14;
parameter R_ACK2		= 5'd15;
parameter R_STOP1		= 5'd16;
parameter R_START2		= 5'd17;
parameter R_SLV_ADDR2	= 5'd18;
parameter R_WR2			= 5'd19;
parameter R_ACK3		= 5'd20;
parameter R_DATA 		= 5'd21;
parameter R_ACK4		= 5'd22;
parameter R_STOP2		= 5'd23;

always@(posedge clk_i)
begin 
	if(rst_i == 1'b1)
		current_state <= IDLE;
	else
		current_state <= next_state;
end

always@(*)
begin
	case(current_state)
		IDLE:
			begin
				if((send_i == 1'b1) && (wr_i == 1'b1))
					next_state <= W_START;
				else if((send_i == 1'b1) && (wr_i == 1'b0))
					next_state <= R_START1;
				else
					next_state <= current_state;
			end
		W_START:
			begin
				if(cnt_clk == 12'b0)
					next_state <= W_SLV_ADDR;
				else
					next_state <= current_state;
			end
		W_SLV_ADDR:
			begin
				if((cnt_clk == 12'b0) && (cnt_scl == 4'b0111))
					next_state <= W_WR;
				else
					next_state <= current_state;
			end
		W_WR:
			begin
				if(cnt_clk == 12'b0)
					next_state <= W_ACK1;
				else
					next_state <= current_state;
			end
		W_ACK1:
			begin
				if(cnt_clk == 12'b0)
					next_state <= W_REG_ADDR;
				else
					next_state <= current_state;
			end
		W_REG_ADDR:
			begin
				if((cnt_clk == 12'b0) && (cnt_scl == 4'b1000))
					next_state <= W_ACK2;
				else
					next_state <= current_state;
			end
		W_ACK2:
			begin
				if(cnt_clk == 12'b0)
					next_state <= W_DATA;
				else
					next_state <= current_state;
			end
		W_DATA:
			begin
				if((cnt_clk == 12'b0) && (cnt_scl == 4'b1000))
					next_state <= W_ACK3;
				else
					next_state <= current_state;
			end
		W_ACK3:
			begin
				if(cnt_clk == 12'b0)
					next_state <= W_STOP;
				else
					next_state <= current_state;
			end
		W_STOP:
			begin
				if(cnt_clk == 12'b0)
					next_state <= IDLE;
				else
					next_state <= current_state;
			end
		R_START1:
			begin
				if(cnt_clk == 12'b0)
					next_state <= R_SLV_ADDR1;
				else
					next_state <= current_state;
			end
		R_SLV_ADDR1:
			begin
				if((cnt_clk == 12'b0) && (cnt_scl == 4'b0111))
					next_state <= R_WR1;
				else
					next_state <= current_state;
			end
		R_WR1:
			begin
				if(cnt_clk == 12'b0)
					next_state <= R_ACK1;
				else
					next_state <= current_state;
			end
		R_ACK1:
			begin
				if(cnt_clk == 12'b0)
					next_state <= R_REG_ADDR;
				else
					next_state <= current_state;
			end
		R_REG_ADDR:
			begin
				if((cnt_clk == 12'b0) && (cnt_scl == 4'b1000))
					next_state <= R_ACK2;
				else
					next_state <= current_state;
			end
		R_ACK2:
			begin
				if(cnt_clk == 12'b0)
					next_state <= R_STOP1;
				else
					next_state <= current_state;
			end
		R_STOP1:
			begin
				if(cnt_clk == 12'b0)
					next_state <= R_START2;
				else
					next_state <= current_state;
			end
		R_START2:
			begin
				if(cnt_clk == 12'b0)
					next_state <= R_SLV_ADDR2;
				else
					next_state <= current_state;
			end
		R_SLV_ADDR2:
			begin
				if((cnt_clk == 12'b0) && (cnt_scl == 4'b0111))
					next_state <= R_WR2;
				else
					next_state <= current_state;
			end
		R_WR2:
			begin
				if(cnt_clk == 12'b0)
					next_state <= R_ACK3;
				else
					next_state <= current_state;
			end
		R_ACK3:
			begin
				if(cnt_clk == 12'b0)
					next_state <= R_DATA;
				else
					next_state <=current_state;
			end
		R_DATA:
			begin
				if((cnt_clk == 12'b0) && (cnt_scl == 4'b1000))
					next_state <= R_ACK4;
				else
					next_state <= current_state;
			end
		R_ACK4:
			begin
				if(cnt_clk == 12'b0)
					next_state <= R_STOP2;
				else
					next_state <= current_state;
			end
		R_STOP2:
			begin
				if(cnt_clk == 12'b0)
					next_state <= IDLE;
				else
					next_state <= current_state;
			end
		default: next_state <= IDLE;
	endcase 
end

always@(posedge clk_i)
begin
	if(rst_i == 1'b1)
		begin
			sda_tri 	<= 1'b0;
			scl_o 		<= 1'b1;
			sda_o 		<= 1'b1;
			cnt_clk 	<= 12'b0;
			IIC_Busy_o 	<= 1'b0;
			cnt_scl 	<= 4'b0;
		end
	else 
		begin
			case (next_state)
				IDLE:
					begin
						sda_tri 	<= 1'b0;
						scl_o 		<= 1'b1;
						sda_o 		<= 1'b1;
						cnt_clk 	<= 12'b0;
						IIC_Busy_o 	<= 1'b0;
						cnt_scl 	<= 4'b0;
					end
				W_START:
					begin
						sda_tri 	<= 1'b0;
						scl_o 		<= (cnt_clk<T2) ? 1'b1 : 1'b0; 
						sda_o 		<= (cnt_clk<T1) ? 1'b1 : 1'b0; 
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1;
						IIC_Busy_o 	<= 1'b1;
						cnt_scl 	<= 4'b0;
					end
				W_SLV_ADDR:
					begin
						sda_tri 	<= 1'b0;
						scl_o 		<= (cnt_clk<T1) ? 1'b0 : (cnt_clk<T2 ? 1'b1 : 1'b0); 
						sda_o 		<= Slv_Addr_i[6-cnt_scl]; 
						IIC_Busy_o 	<= 1'b1; 
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1; 
						cnt_scl 	<= (cnt_clk>=DIV-1) ? cnt_scl+ 1 : cnt_scl;
					end
				W_WR:
					begin
						sda_tri 	<= 1'b0;
						scl_o 		<= (cnt_clk<T1) ? 1'b0 : (cnt_clk<T2 ? 1'b1 : 1'b0); 
						sda_o 		<= 1'b0;
						IIC_Busy_o 	<= 1'b1;
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1;
						cnt_scl 	<= 4'b0;
					end
				W_ACK1:
					begin
						sda_tri 	<= 1'b1;
						scl_o 		<= (cnt_clk<T1) ? 1'b0 : (cnt_clk<T2 ? 1'b1 : 1'b0); 
						IIC_Busy_o 	<= 1'b1;
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1;
						cnt_scl 	<= 4'b0;
					end
				W_REG_ADDR:
					begin
						sda_tri 	<= 1'b0;
						scl_o 		<= (cnt_clk<T1) ? 1'b0 : (cnt_clk<T2 ? 1'b1 : 1'b0); 
						sda_o 		<= Reg_Addr_i[7- cnt_scl];
						IIC_Busy_o 	<= 1'b1;
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1;
						cnt_scl 	<= (cnt_clk>=DIV-1) ? cnt_scl+ 1 : cnt_scl;
					end
				W_ACK2:
					begin
						sda_tri 	<= 1'b1;
						scl_o 		<= (cnt_clk<T1) ? 1'b0 : (cnt_clk<T2 ? 1'b1 : 1'b0); 
						IIC_Busy_o 	<= 1'b1;
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1;
						cnt_scl 	<= 4'b0;
					end
				W_DATA:
					begin
						sda_tri 	<= 1'b0;
						scl_o 		<= (cnt_clk<T1) ? 1'b0 : (cnt_clk<T2 ? 1'b1 : 1'b0); 
						sda_o 		<= Data_i[7- cnt_scl];
						IIC_Busy_o 	<= 1'b1;
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1;
						cnt_scl 	<= (cnt_clk>=DIV-1) ? cnt_scl+ 1 : cnt_scl;
					end
				W_ACK3:
					begin
						sda_tri 	<= 1'b1;
						scl_o 		<= (cnt_clk<T1) ? 1'b0 : (cnt_clk<T2 ? 1'b1 : 1'b0);  
						IIC_Busy_o 	<= 1'b1;
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1;
						cnt_scl 	<= 4'b0;
					end
				W_STOP:
					begin
						sda_tri 	<= 1'b0;
						scl_o 		<= (cnt_clk<T1) ? 1'b0 : 1'b1; 
						sda_o 		<= (cnt_clk<T2) ? 1'b0 : 1'b1; 
						IIC_Busy_o 	<= 1'b1;
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1;
						cnt_scl 	<= 4'b0;
					end
				R_START1:
					begin
						sda_tri 	<= 1'b0;
						scl_o 		<= (cnt_clk<T2) ? 1'b1 : 1'b0; 
						sda_o 		<= (cnt_clk<T1) ? 1'b1 : 1'b0; 
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1;
						IIC_Busy_o 	<= 1'b1;
						cnt_scl 	<= 4'b0;
					end
				R_SLV_ADDR1:
					begin
						sda_tri 	<= 1'b0;
						scl_o 		<= (cnt_clk<T1) ? 1'b0 : (cnt_clk<T2 ? 1'b1 : 1'b0); 
						sda_o 		<= Slv_Addr_i[6-cnt_scl]; 
						IIC_Busy_o 	<= 1'b1; 
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1; 
						cnt_scl 	<= (cnt_clk>=DIV-1) ? cnt_scl+ 1 : cnt_scl;
					end
				R_WR1:
					begin
						sda_tri 	<= 1'b0;
						scl_o 		<= (cnt_clk<T1) ? 1'b0 : (cnt_clk<T2 ? 1'b1 : 1'b0); 
						sda_o 		<= 1'b0;
						IIC_Busy_o 	<= 1'b1;
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1;
						cnt_scl 	<= 4'b0;
					end
				R_ACK1:
					begin
						sda_tri 	<= 1'b1;
						scl_o 		<= (cnt_clk<T1) ? 1'b0 : (cnt_clk<T2 ? 1'b1 : 1'b0); 
						IIC_Busy_o 	<= 1'b1;
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1;
						cnt_scl 	<= 4'b0;
					end
				R_REG_ADDR:
					begin
						sda_tri 	<= 1'b0;
						scl_o 		<= (cnt_clk<T1) ? 1'b0 : (cnt_clk<T2 ? 1'b1 : 1'b0); 
						sda_o 		<= Reg_Addr_i[7- cnt_scl];
						IIC_Busy_o 	<= 1'b1;
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1;
						cnt_scl 	<= (cnt_clk>=DIV-1) ? cnt_scl+ 1 : cnt_scl;
					end
				R_ACK2:
					begin
						sda_tri 	<= 1'b1;
						scl_o 		<= (cnt_clk<T1) ? 1'b0 : (cnt_clk<T2 ? 1'b1 : 1'b0); 
						IIC_Busy_o 	<= 1'b1;
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1;
						cnt_scl 	<= 4'b0;
					end
				R_STOP1:
					begin
						sda_tri 	<= 1'b0;
						scl_o 		<= (cnt_clk<T1) ? 1'b0 : 1'b1; 
						sda_o 		<= (cnt_clk<T2) ? 1'b0 : 1'b1; 
						IIC_Busy_o 	<= 1'b1;
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1;
						cnt_scl 	<= 4'b0;
					end
				R_START2:
					begin
						sda_tri 	<= 1'b0;
						scl_o 		<= (cnt_clk<T2) ? 1'b1 : 1'b0; 
						sda_o 		<= (cnt_clk<T1) ? 1'b1 : 1'b0; 
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1;
						IIC_Busy_o 	<= 1'b1;
						cnt_scl 	<= 4'b0;
					end
				R_SLV_ADDR2:
					begin
						sda_tri 	<= 1'b0;
						scl_o 		<= (cnt_clk<T1) ? 1'b0 : (cnt_clk<T2 ? 1'b1 : 1'b0); 
						sda_o 		<= Slv_Addr_i[6-cnt_scl]; 
						IIC_Busy_o 	<= 1'b1; 
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1; 
						cnt_scl 	<= (cnt_clk>=DIV-1) ? cnt_scl+ 1 : cnt_scl;
					end
				R_WR2:
					begin
						sda_tri 	<= 1'b0;
						scl_o 		<= (cnt_clk<T1) ? 1'b0 : (cnt_clk<T2 ? 1'b1 : 1'b0); 
						sda_o 		<= 1'b1;
						IIC_Busy_o 	<= 1'b1;
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1;
						cnt_scl 	<= 4'b0;
					end
				R_ACK3:
					begin
						sda_tri 	<= 1'b1;
						scl_o 		<= (cnt_clk<T1) ? 1'b0 : (cnt_clk<T2 ? 1'b1 : 1'b0); 
						IIC_Busy_o 	<= 1'b1;
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1;
						cnt_scl 	<= 4'b0;
					end
				R_DATA:
					begin
						sda_tri 	<= 1'b1;
						scl_o 		<= (cnt_clk<T1) ? 1'b0 : (cnt_clk<T2 ? 1'b1 : 1'b0); 
						IIC_Busy_o 	<= 1'b1;
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1;
						cnt_scl 	<= (cnt_clk==DIV/2-1) ? cnt_scl+ 1 : cnt_scl;
						case(cnt_scl)
							4'b0000: IIC_Read_Data_o[7] <= sda;
							4'b0001: IIC_Read_Data_o[6] <= sda;
							4'b0010: IIC_Read_Data_o[5] <= sda;
							4'b0011: IIC_Read_Data_o[4] <= sda;
							4'b0100: IIC_Read_Data_o[3] <= sda;
							4'b0101: IIC_Read_Data_o[2] <= sda;
							4'b0110: IIC_Read_Data_o[1] <= sda;
							4'b0111: IIC_Read_Data_o[0] <= sda;
							default: ;
						endcase
					end
				R_ACK4:
					begin
						sda_tri 	<= 1'b1;
						scl_o 		<= (cnt_clk<T1) ? 1'b0 : (cnt_clk<T2 ? 1'b1 : 1'b0); 
						IIC_Busy_o 	<= 1'b1;
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1;
						cnt_scl 	<= 4'b0;
					end
				R_STOP2:
					begin
						sda_tri 	<= 1'b0;
						scl_o 		<= (cnt_clk<T1) ? 1'b0 : 1'b1; 
						sda_o 		<= (cnt_clk<T2) ? 1'b0 : 1'b1; 
						IIC_Busy_o 	<= 1'b1;
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1;
						cnt_scl 	<= 4'b0;
					end
				default : 
							begin
								sda_tri    <= 1'b0;
								scl_o      <= 1'b1;
								sda_o      <= 1'b1;
								cnt_clk    <= 12'b0;
								IIC_Busy_o <= 1'b0;
								cnt_scl    <= 4'b0;
							end
			endcase
		end
end


endmodule

