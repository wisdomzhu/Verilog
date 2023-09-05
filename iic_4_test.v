`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/05 17:22:11
// Design Name: 
// Module Name: model
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: flag_i拉高一次，iic运行一次，运行结束输出高电平
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module iic_master(
  input clk_i,//150MHz
  input reset_i,//高电平同步复位  
  input flag_i,//拉高一次，实现一次IIC

  input [6:0] Slv_Addr_i,
  input [7:0] Reg_Addr_i,
  input [7:0] Data_i,

  output scl,//30KHz
  /*inout*/output sda,
  output ready_o
  //output oled_rst_o
);

//parameter DELAY=10;//1500000;
parameter DIV=4;//2500;//每DIV个clk_i的上升沿，翻转一次
parameter T1=DIV/4;
parameter T2=DIV*3/4;

reg [11:0] cnt_clk;						//clk计数器
reg [3:0] cnt_scl;						//scl计数器，表示传送数据的位数
reg sda_tri;							//三态控制信号,0:输出；1：输入
reg sda_o;								//sda总线输出数据的寄存器
//wire sda_i;                           //sda总线输入数据   
reg scl_o;								//scl时钟总线
reg [4:0] current_state;				//当前状态
reg [4:0] next_state;					//下个状态
//reg [7:0]IIC_Read_Data_o;

//reg [4:0] current_state_1;
//reg [4:0] next_state_1;
//reg iic_send;
//reg rst_o;
//reg [23:0]cnt_delay;
reg busy=0;
reg wr_i=0;
reg ready_r;
assign ready_o=ready_r;


/*
//内嵌系统复位
wire rst_n;
reg [7:0]cnt_rst=8'd0;
always @(posedge clk_i) begin
	if(cnt_rst==8'd150)
	  cnt_rst<=cnt_rst;
	else
	  cnt_rst<=cnt_rst+1;  
end
assign rst_n=(cnt_rst==150)?1:0;
*/

assign sda = sda_tri ? 1'bz : sda_o;
//assign sda_i=sda;
assign scl = scl_o;
//assign IIC_Read_Data=IIC_Read_Data_o;
//assign oled_rst_o=rst_o;

//states
/*
//states_1
localparam PULL_UP=5'd16;
localparam RST_L=5'd17;
localparam RST_H=5'd18;
localparam OVER=5'd19;
*/
//states_2
localparam IDLE=5'd0;
localparam W_START=5'd1;
localparam W_SLV_ADDR=5'd2;
localparam W_WR=5'd3;
localparam W_ACK1=5'd4;
localparam W_REG_ADDR=5'd5;
localparam W_ACK2=5'd6;
localparam W_DATA=5'd7;
localparam W_ACK3=5'd8;
localparam STOP=5'd9;
localparam FINISH=5'd20;
localparam R_START2=5'd10;
localparam R_SLV_ADDR2=5'd11;
localparam R_RD=5'd12;
localparam R_ACK3=5'd13;
localparam R_DATA=5'd14;
localparam R_ACK4=5'd15;

/*
//状态机1第一段
always @(posedge clk_i) begin
	if(~reset_i)
		current_state_1<=PULL_UP;
    else
	    current_state_1<=next_state_1;
end
//状态机1第二段
always @(*)
begin
  case(current_state_1) 
	  PULL_UP:
	         begin
			   if(cnt_delay==0)
			   next_state_1<=RST_L;
			   else
			   next_state_1<=current_state_1;
			 end
	  RST_L:
	        begin
			  if(cnt_delay==0)
			  next_state_1<=RST_H;
			  else
			  next_state_1<=current_state_1;
			end	
	  RST_H:
	        begin
			  if(cnt_delay==0)
			  next_state_1<=OVER;
			  else
              next_state_1<=current_state_1;
			end
	  OVER:
	       begin
			 next_state_1<=current_state_1;
		   end		
	  default:next_state_1<=PULL_UP;//当current_state_1(这是case的判断条件)不等于以上值，则下一状态为PULL_UP	   			 
  endcase
end
//状态机1第三段
always@(posedge clk_i)
begin
	if(~reset_i)begin
	   rst_o<=1;
	   iic_send<=0;
	   cnt_delay<=0; 
	end
    else begin
  case(next_state_1) 
	  PULL_UP:
	         begin
			  rst_o<=1;
			  iic_send<=0;
			  cnt_delay<=(cnt_delay>=DELAY-1)?0:cnt_delay+1; 
			 end
	  RST_L:
	        begin
			  rst_o<=0;
			  iic_send<=0;
			  cnt_delay<=(cnt_delay>=DELAY-1)?0:cnt_delay+1; 
			end		
	  RST_H:
	        begin
			  rst_o<=1;
			  iic_send<=0;
			  cnt_delay<=(cnt_delay>=DELAY-1)?0:cnt_delay+1; 
			end	
	  OVER:
	       begin
			  rst_o<=1;
			  iic_send<=1;
			  cnt_delay<=0;
		   end			 
  endcase
	end
end
*/

//状态机2第一段
always@(posedge clk_i)
begin 
	if(reset_i)
		current_state <= IDLE;
	else
		current_state <= next_state;
end

//状态机2第二段
always@(*)
begin
	case(current_state)
		IDLE:
			begin
				if(flag_i)
                    next_state = W_START;
				else
					next_state = current_state;
			end
		W_START:
			begin
				if(cnt_clk == 12'b0)
					next_state = W_SLV_ADDR;
				else
					next_state = current_state;
			end
		W_SLV_ADDR:
			begin
				if((cnt_clk == 12'b0) && (cnt_scl == 4'b0111))
					next_state = W_WR;
				else
					next_state = current_state;
			end   
		W_WR:
			begin
				if(cnt_clk == 12'b0)
					next_state = W_ACK1;
				else
					next_state = current_state;
			end                     
		W_ACK1:
			begin
				if(cnt_clk == 12'b0)
					next_state = W_REG_ADDR;
				else
					next_state = current_state;
			end 
		W_REG_ADDR:
			begin
				if((cnt_clk == 12'b0) && (cnt_scl == 4'b1000))
					next_state = W_ACK2;
				else
					next_state = current_state;
			end
		W_ACK2:
			begin
				if((cnt_clk == 12'b0)&&(wr_i==0))
					next_state = W_DATA;
				else if ((cnt_clk == 12'b0)&&(wr_i==1))
				    next_state = R_START2;
                     else
                	next_state = current_state;
			end   
		W_DATA:
			begin
				if((cnt_clk == 12'b0) && (cnt_scl == 4'b1000))
					next_state = W_ACK3;
				else
					next_state = current_state;
			end
		W_ACK3:
			begin
				if(cnt_clk == 12'b0)
					next_state = STOP;
				else
					next_state = current_state;
			end 
		STOP:
			begin
				if((cnt_clk == 12'b0)&&(busy==1'b1))
					next_state = IDLE;
				else begin
				  if((cnt_clk == 12'b0)&&(busy==1'b0))
					next_state = FINISH;
					else
					next_state = current_state;
				end
			end
		FINISH:
		    begin
				next_state = current_state;
			end	
    /*        
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
     */         
		default: next_state <= IDLE;                                                                  
    endcase
end

//状态机2第三段
always@(posedge clk_i)
begin
	if(reset_i)
		begin
			sda_tri 	<= 1'b0;
			scl_o 		<= 1'b1;
			sda_o 		<= 1'b1;
			cnt_clk 	<= 12'b0;
			cnt_scl 	<= 4'b0;
            ready_r     <= 1'b0;
            //IIC_Read_Data_o <= 8'b0;
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
                        ready_r     <= 1'b0;
                        //IIC_Read_Data_o <= 8'b0;                        
					end   
				W_START:
					begin
						sda_tri 	<= 1'b0;
						scl_o 		<= (cnt_clk<T2) ? 1'b1 : 1'b0; 
						sda_o 		<= (cnt_clk<T1) ? 1'b1 : 1'b0; 
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1;
						cnt_scl 	<= 4'b0;
                        ready_r     <= 0;
					end 
				W_SLV_ADDR:
					begin
						sda_tri 	<= 1'b0;
						scl_o 		<= (cnt_clk<T1) ? 1'b0 : (cnt_clk<T2 ? 1'b1 : 1'b0); 
						sda_o 		<= Slv_Addr_i[6-cnt_scl]; 
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1; 
						cnt_scl 	<= (cnt_clk>=DIV-1) ? cnt_scl+ 1 : cnt_scl;
                        ready_r     <= 0;
					end   
				W_WR:
					begin
						sda_tri 	<= 1'b0;
						scl_o 		<= (cnt_clk<T1) ? 1'b0 : (cnt_clk<T2 ? 1'b1 : 1'b0); 
						sda_o 		<= 1'b0;//发送写标志，低电平
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1;
						cnt_scl 	<= 4'b0;
                        ready_r     <= 0;
					end 
				W_ACK1:
					begin
						sda_tri 	<= 1'b1;
						scl_o 		<= (cnt_clk<T1) ? 1'b0 : (cnt_clk<T2 ? 1'b1 : 1'b0); 
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1;
						cnt_scl 	<= 4'b0;
                        ready_r     <= 0;
					end      
				W_REG_ADDR:
					begin
						sda_tri 	<= 1'b0;
						scl_o 		<= (cnt_clk<T1) ? 1'b0 : (cnt_clk<T2 ? 1'b1 : 1'b0); 
						sda_o 		<= Reg_Addr_i[7- cnt_scl];
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1;
						cnt_scl 	<= (cnt_clk>=DIV-1) ? cnt_scl+ 1 : cnt_scl;
                        ready_r     <= 0;
					end    
				W_ACK2:
					begin
						sda_tri 	<= 1'b1;
						scl_o 		<= (cnt_clk<T1) ? 1'b0 : (cnt_clk<T2 ? 1'b1 : 1'b0); 
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1;
						cnt_scl 	<= 4'b0;
                        ready_r     <= 0;
					end   
				W_DATA:
					begin
						sda_tri 	<= 1'b0;
						scl_o 		<= (cnt_clk<T1) ? 1'b0 : (cnt_clk<T2 ? 1'b1 : 1'b0); 
						sda_o 		<= Data_i[7- cnt_scl];
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1;
						cnt_scl 	<= (cnt_clk>=DIV-1) ? cnt_scl+ 1 : cnt_scl;
                        ready_r     <= 0;
					end     
				W_ACK3:
					begin
						sda_tri 	<= 1'b1;
						scl_o 		<= (cnt_clk<T1) ? 1'b0 : (cnt_clk<T2 ? 1'b1 : 1'b0);  
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1;
						cnt_scl 	<= 4'b0;
                        ready_r     <= 0;
					end       
				STOP:
					begin
						sda_tri 	<= 1'b0;
						scl_o 		<= (cnt_clk<T1) ? 1'b0 : 1'b1; 
						sda_o 		<= (cnt_clk<T2) ? 1'b0 : 1'b1; 
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1;
						cnt_scl 	<= 4'b0;
                        ready_r     <= 0;
					end 
				FINISH:
				    begin
						sda_tri 	<= 1'b0;
						scl_o 		<= 1'b1;
						sda_o 		<= 1'b1;
						cnt_clk 	<= 0;
						cnt_scl 	<= 0;
                        ready_r     <= 1;
					end	
            /*        
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
        */                            
            endcase
end
end


endmodule