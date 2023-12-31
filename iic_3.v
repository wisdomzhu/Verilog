`timescale 1ns / 1ps
module iic_master(
  input clk_i,
  input rst_i,

  input [6:0] Slv_Addr_i,
  input [7:0] Reg_Addr_i,
  input [7:0] Data_i,

  input wr_i,
  input send_i,

  output scl,
  output sda,
  output [7:0]IIC_Read_Data

);

parameter DIV=4;//每DIV个clk_i的上升沿，翻转一次
parameter T1=DIV/4;
parameter T2=DIV*3/4;

reg [11:0] cnt_clk;						//clk计数器
reg [3:0] cnt_scl;						//scl计数器，表示传送数据的位数
reg sda_tri;							//三态控制信号,0:输出；1：输入
reg sda_o;								//sda总线输出数据的寄存器
//wire sda_i;                             //sda总线输入数据   
reg scl_o;								//scl时钟总线
reg [3:0] current_state;				//当前状态
reg [3:0] next_state;					//下个状态
reg [7:0]IIC_Read_Data_o;

assign sda = sda_tri ? 1'bz : sda_o;
//assign sda_i=sda;
assign scl = scl_o;
assign IIC_Read_Data=IIC_Read_Data_o;

//states
localparam IDLE=4'd0;
localparam W_START=4'd1;
localparam W_SLV_ADDR=4'd2;
localparam W_WR=4'd3;
localparam W_ACK1=4'd4;
localparam W_REG_ADDR=4'd5;
localparam W_ACK2=4'd6;
localparam W_DATA=4'd7;
localparam W_ACK3=4'd8;
localparam STOP=4'd9;
localparam R_START2=4'd10;
localparam R_SLV_ADDR2=4'd11;
localparam R_RD=4'd12;
localparam R_ACK3=4'd13;
localparam R_DATA=4'd14;
localparam R_ACK4=4'd15;

//状态机第一段
always@(posedge clk_i)
begin 
	if(~rst_i)
		current_state <= IDLE;
	else
		current_state <= next_state;
end

//状态机第二段
always@(*)
begin
	case(current_state)
		IDLE:
			begin
				if(send_i)
                    next_state <= W_START;
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
				if((cnt_clk == 12'b0)&&(wr_i==0))
					next_state <= W_DATA;
				else if ((cnt_clk == 12'b0)&&(wr_i==1))
				    next_state <= R_START2;
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
					next_state <= STOP;
				else
					next_state <= current_state;
			end 
		STOP:
			begin
				if(cnt_clk == 12'b0)
					next_state <= IDLE;
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
					next_state <= R_RD;
				else
					next_state <= current_state;
			end    
		R_RD:
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
					next_state <= STOP;
				else
					next_state <= current_state;
			end    
		default: next_state <= IDLE;                                                                  
    endcase
end

//状态机第三段
always@(posedge clk_i)
begin
	if(~rst_i)
		begin
			sda_tri 	<= 1'b0;
			scl_o 		<= 1'b1;
			sda_o 		<= 1'b1;
			cnt_clk 	<= 12'b0;
			cnt_scl 	<= 4'b0;
            IIC_Read_Data_o <= 8'b0;
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
						cnt_scl 	<= 4'b0;
                        IIC_Read_Data_o <= 8'b0;                        
					end   
				W_START:
					begin
						sda_tri 	<= 1'b0;
						scl_o 		<= (cnt_clk<T2) ? 1'b1 : 1'b0; 
						sda_o 		<= (cnt_clk<T1) ? 1'b1 : 1'b0; 
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1;
						cnt_scl 	<= 4'b0;
					end 
				W_SLV_ADDR:
					begin
						sda_tri 	<= 1'b0;
						scl_o 		<= (cnt_clk<T1) ? 1'b0 : (cnt_clk<T2 ? 1'b1 : 1'b0); 
						sda_o 		<= Slv_Addr_i[6-cnt_scl]; 
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1; 
						cnt_scl 	<= (cnt_clk>=DIV-1) ? cnt_scl+ 1 : cnt_scl;
					end   
				W_WR:
					begin
						sda_tri 	<= 1'b0;
						scl_o 		<= (cnt_clk<T1) ? 1'b0 : (cnt_clk<T2 ? 1'b1 : 1'b0); 
						sda_o 		<= 1'b0;//发送写标志，低电平
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1;
						cnt_scl 	<= 4'b0;
					end 
				W_ACK1:
					begin
						sda_tri 	<= 1'b1;
						scl_o 		<= (cnt_clk<T1) ? 1'b0 : (cnt_clk<T2 ? 1'b1 : 1'b0); 
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1;
						cnt_scl 	<= 4'b0;
					end      
				W_REG_ADDR:
					begin
						sda_tri 	<= 1'b0;
						scl_o 		<= (cnt_clk<T1) ? 1'b0 : (cnt_clk<T2 ? 1'b1 : 1'b0); 
						sda_o 		<= Reg_Addr_i[7- cnt_scl];
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1;
						cnt_scl 	<= (cnt_clk>=DIV-1) ? cnt_scl+ 1 : cnt_scl;
					end    
				W_ACK2:
					begin
						sda_tri 	<= 1'b1;
						scl_o 		<= (cnt_clk<T1) ? 1'b0 : (cnt_clk<T2 ? 1'b1 : 1'b0); 
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1;
						cnt_scl 	<= 4'b0;
					end   
				W_DATA:
					begin
						sda_tri 	<= 1'b0;
						scl_o 		<= (cnt_clk<T1) ? 1'b0 : (cnt_clk<T2 ? 1'b1 : 1'b0); 
						sda_o 		<= Data_i[7- cnt_scl];
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1;
						cnt_scl 	<= (cnt_clk>=DIV-1) ? cnt_scl+ 1 : cnt_scl;
					end     
				W_ACK3:
					begin
						sda_tri 	<= 1'b1;
						scl_o 		<= (cnt_clk<T1) ? 1'b0 : (cnt_clk<T2 ? 1'b1 : 1'b0);  
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1;
						cnt_scl 	<= 4'b0;
					end       
				STOP:
					begin
						sda_tri 	<= 1'b0;
						scl_o 		<= (cnt_clk<T1) ? 1'b0 : 1'b1; 
						sda_o 		<= (cnt_clk<T2) ? 1'b0 : 1'b1; 
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1;
						cnt_scl 	<= 4'b0;
					end 
				R_START2:
					begin
						sda_tri 	<= 1'b0;
						scl_o 		<= (cnt_clk<T2) ? 1'b1 : 1'b0; 
						sda_o 		<= (cnt_clk<T1) ? 1'b1 : 1'b0; 
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1;
						cnt_scl 	<= 4'b0;
					end   
				R_SLV_ADDR2:
					begin
						sda_tri 	<= 1'b0;
						scl_o 		<= (cnt_clk<T1) ? 1'b0 : (cnt_clk<T2 ? 1'b1 : 1'b0); 
						sda_o 		<= Slv_Addr_i[6-cnt_scl]; 
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1; 
						cnt_scl 	<= (cnt_clk>=DIV-1) ? cnt_scl+ 1 : cnt_scl;
					end 
				R_RD:
					begin
						sda_tri 	<= 1'b0;
						scl_o 		<= (cnt_clk<T1) ? 1'b0 : (cnt_clk<T2 ? 1'b1 : 1'b0); 
						sda_o 		<= 1'b1;//发送读标志
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1;
						cnt_scl 	<= 4'b0;
					end     
				R_ACK3:
					begin
						sda_tri 	<= 1'b1;
						scl_o 		<= (cnt_clk<T1) ? 1'b0 : (cnt_clk<T2 ? 1'b1 : 1'b0); 
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1;
						cnt_scl 	<= 4'b0;
					end 
				R_DATA:
					begin
						sda_tri 	<= 1'b1;
						scl_o 		<= (cnt_clk<T1) ? 1'b0 : (cnt_clk<T2 ? 1'b1 : 1'b0); 
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
                        endcase
                    end   
				R_ACK4://只有这个是主机发送应答
					begin
						sda_tri 	<= 1'b0;
						scl_o 		<= (cnt_clk<T1) ? 1'b0 : (cnt_clk<T2 ? 1'b1 : 1'b0); 
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1;
						cnt_scl 	<= 4'b0;
                        sda_o<=1;//主机发送高电平无效应答
					end                    
            endcase
end
end
endmodule