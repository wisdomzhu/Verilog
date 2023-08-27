`timescale 1ns / 1ps
module iic_master(
  input sys_clk_p_i,
  input sys_clk_n_i,

  output oled_scl_o,//30KHz
  inout oled_sda_io,
  output oled_pclk_o,
  output oled_rst_o
);

parameter DELAY=1500000;
parameter DIV=2500;//每DIV个clk_i的上升沿，翻转一次
parameter T1=DIV/4;
parameter T2=DIV*3/4;

reg [11:0] cnt_clk;						//clk计数器
reg [3:0] cnt_scl;						//scl计数器，表示传送数据的位数
reg sda_tri;							//三态控制信号,0:输出；1：输入
reg sda_out_r/* synthesis mark_debug=true */;								//sda总线输出数据的寄存器
wire sda_in_r/* synthesis mark_debug=true */;                             //sda总线输入数据   
reg scl_r/* synthesis mark_debug=true */;								//scl时钟总线
reg [4:0] current_state;				//当前状态
reg [4:0] next_state;					//下个状态
reg [7:0] IIC_Read_Data_r;//读出来的数据放在寄存器里检验是否正确

reg [4:0] current_state_1;
reg [4:0] next_state_1;
reg iic_send;
reg rst_r/* synthesis mark_debug=true */;//debug标记技巧
reg [23:0]cnt_delay;
reg wr_flag;//0:写；1：读

//要输入的数据放在寄存器
reg [6:0] Slv_Addr_i=7'b1010100;
reg [7:0] Reg_Addr_i=8'b00000001;
reg [7:0] Data_i=8'b00001011;

//输入的差分时钟转单端,cmos_data_clk_150m_o作为全局时钟
wire cmos_data_clk_150m;
wire cmos_data_clk_150m_o;
IBUFGDS
CLK_U(
	.I(sys_clk_p_i),
	.IB(sys_clk_n_i),
	.O(cmos_data_clk_150m)
);
BUFG
BUFG_CLKIN1(
    .I(cmos_data_clk_150m),
	.O(cmos_data_clk_150m_o)
);

//内嵌系统复位
wire rst_n;
reg [7:0]cnt_rst=8'd0;
always @(posedge cmos_data_clk_150m_o) begin
	if(cnt_rst==8'd150)
	  cnt_rst<=cnt_rst;
	else
	  cnt_rst<=cnt_rst+1;  
end
assign rst_n=(cnt_rst==150)?1:0;


assign oled_sda_io = sda_tri ? 1'bz : sda_out_r;
assign sda_in_r=oled_sda_io;
assign oled_scl_o = scl_r;
assign oled_rst_o=rst_r;

//states
//states_1
localparam PULL_UP=5'd16;
localparam RST_L=5'd17;
localparam RST_H=5'd18;
localparam OVER=5'd19;
//states_2
localparam IDLE=5'd0;
localparam W_START=5'd1;
localparam W_SLV_ADDR=5'd2;
localparam W_WR=5'd3;
localparam W_ACK1=5'd4;
localparam W_REG_ADDR=5'd5;
localparam W_ACK2=5'd6;
localparam W_DATA=5'd7;
localparam W_ACK3=4'd8;
localparam STOP=5'd9;
localparam FINISH=5'd20;
localparam R_START2=5'd10;
localparam R_SLV_ADDR2=5'd11;
localparam R_RD=5'd12;
localparam R_ACK3=5'd13;
localparam R_DATA=5'd14;
localparam R_ACK4=5'd15;



//状态机1第一段
always @(posedge cmos_data_clk_150m_o) begin
	if(~rst_n)
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
always@(posedge cmos_data_clk_150m_o)
begin
	if(~rst_n)begin
	   rst_r<=1;
	   iic_send<=0;
	   cnt_delay<=0; 
	   wr_flag=0;
	end
    else begin
  case(next_state_1) 
	  PULL_UP:
	         begin
			  rst_r<=1;
			  iic_send<=0;
			  cnt_delay<=(cnt_delay>=DELAY-1)?0:cnt_delay+1; 
			 end
	  RST_L:
	        begin
			  rst_r<=0;
			  iic_send<=0;
			  cnt_delay<=(cnt_delay>=DELAY-1)?0:cnt_delay+1; 
			end		
	  RST_H:
	        begin
			  rst_r<=1;
			  iic_send<=0;
			  cnt_delay<=(cnt_delay>=DELAY-1)?0:cnt_delay+1; 
			end	
	  OVER:
	       begin
			  rst_r<=1;
			  iic_send<=1;
			  cnt_delay<=0;
			  wr_flag<=0;//前三个状态都对wr_flag没操作，故在前三个状态，wr_flag保持初值
		   end	
	  default://以上状态都跳不进去，则默认为OVER
	  	   begin
			  rst_r<=1;
			  iic_send<=1;
			  cnt_delay<=0;
			  wr_flag<=0;
		   end		 
  endcase
	end
end

//状态机2第一段
always@(posedge cmos_data_clk_150m_o)
begin 
	if(~rst_r)
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
				if(iic_send)
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
				if((cnt_clk == 12'b0)&&(sda_in_r==0))
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
				if((cnt_clk == 12'b0)&&(wr_flag==0)&&(sda_in_r==0))
					next_state <= W_DATA;
				else if ((cnt_clk == 12'b0)&&(wr_flag==1)&&(sda_in_r==0))
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
				if((cnt_clk == 12'b0)&&(sda_in_r==0))
					next_state <= STOP;
				else
					next_state <= current_state;
			end 
		STOP:
			begin
				if(cnt_clk == 12'b0)
					next_state <= FINISH;
				else
					next_state <= current_state;
			end
		FINISH:
		    begin
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
				if((cnt_clk == 12'b0)&&(sda_in_r==0))
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

//状态机2第三段
always@(posedge cmos_data_clk_150m_o)
begin
	if(~rst_r)
		begin
			sda_tri 	<= 1'b0;
			scl_r 		<= 1'b1;
			sda_out_r 		<= 1'b1;
			cnt_clk 	<= 12'b0;
			cnt_scl 	<= 4'b0;
            IIC_Read_Data_r <= 8'b0;
		end
	else 
		begin
			case (next_state)
				IDLE:
					begin
						sda_tri 	<= 1'b0;
						scl_r 		<= 1'b1;
						sda_out_r 		<= 1'b1;
						cnt_clk 	<= 12'b0;
						cnt_scl 	<= 4'b0;
                        IIC_Read_Data_r <= 8'b0;                        
					end   
				W_START:
					begin
						sda_tri 	<= 1'b0;
						scl_r 		<= (cnt_clk<T2) ? 1'b1 : 1'b0; 
						sda_out_r 		<= (cnt_clk<T1) ? 1'b1 : 1'b0; 
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1;
						cnt_scl 	<= 4'b0;
					end 
				W_SLV_ADDR:
					begin
						sda_tri 	<= 1'b0;
						scl_r 		<= (cnt_clk<T1) ? 1'b0 : (cnt_clk<T2 ? 1'b1 : 1'b0); 
						sda_out_r 		<= Slv_Addr_i[6-cnt_scl]; 
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1; 
						cnt_scl 	<= (cnt_clk>=DIV-1) ? cnt_scl+ 1 : cnt_scl;
					end   
				W_WR:
					begin
						sda_tri 	<= 1'b0;
						scl_r 		<= (cnt_clk<T1) ? 1'b0 : (cnt_clk<T2 ? 1'b1 : 1'b0); 
						sda_out_r 		<= 1'b0;//发送写标志，低电平
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1;
						cnt_scl 	<= 4'b0;
					end 
				W_ACK1:
					begin
						sda_tri 	<= 1'b1;
						scl_r 		<= (cnt_clk<T1) ? 1'b0 : (cnt_clk<T2 ? 1'b1 : 1'b0); 
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1;
						cnt_scl 	<= 4'b0;
					end      
				W_REG_ADDR:
					begin
						sda_tri 	<= 1'b0;
						scl_r 		<= (cnt_clk<T1) ? 1'b0 : (cnt_clk<T2 ? 1'b1 : 1'b0); 
						sda_out_r 		<= Reg_Addr_i[7- cnt_scl];
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1;
						cnt_scl 	<= (cnt_clk>=DIV-1) ? cnt_scl+ 1 : cnt_scl;
					end    
				W_ACK2:
					begin
						sda_tri 	<= 1'b1;
						scl_r 		<= (cnt_clk<T1) ? 1'b0 : (cnt_clk<T2 ? 1'b1 : 1'b0); 
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1;
						cnt_scl 	<= 4'b0;
					end   
				W_DATA:
					begin
						sda_tri 	<= 1'b0;
						scl_r 		<= (cnt_clk<T1) ? 1'b0 : (cnt_clk<T2 ? 1'b1 : 1'b0); 
						sda_out_r 		<= Data_i[7- cnt_scl];
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1;
						cnt_scl 	<= (cnt_clk>=DIV-1) ? cnt_scl+ 1 : cnt_scl;
					end     
				W_ACK3:
					begin
						sda_tri 	<= 1'b1;
						scl_r 		<= (cnt_clk<T1) ? 1'b0 : (cnt_clk<T2 ? 1'b1 : 1'b0);  
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1;
						cnt_scl 	<= 4'b0;
					end       
				STOP:
					begin
						sda_tri 	<= 1'b0;
						scl_r 		<= (cnt_clk<T1) ? 1'b0 : 1'b1; 
						sda_out_r 	<= (cnt_clk<T2) ? 1'b0 : 1'b1; 
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1;
						cnt_scl 	<= 4'b0;
					end 
				FINISH:
				    begin
						sda_tri 	<= 1'b0;
						scl_r 		<= 1'b0;
						sda_out_r 	<= 1'b0;
						cnt_clk 	<= 0;
						cnt_scl 	<= 4'b0;
					end	
				R_START2:
					begin
						sda_tri 	<= 1'b0;
						scl_r 		<= (cnt_clk<T2) ? 1'b1 : 1'b0; 
						sda_out_r 		<= (cnt_clk<T1) ? 1'b1 : 1'b0; 
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1;
						cnt_scl 	<= 4'b0;
					end   
				R_SLV_ADDR2:
					begin
						sda_tri 	<= 1'b0;
						scl_r 		<= (cnt_clk<T1) ? 1'b0 : (cnt_clk<T2 ? 1'b1 : 1'b0); 
						sda_out_r 		<= Slv_Addr_i[6-cnt_scl]; 
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1; 
						cnt_scl 	<= (cnt_clk>=DIV-1) ? cnt_scl+ 1 : cnt_scl;
					end 
				R_RD:
					begin
						sda_tri 	<= 1'b0;
						scl_r 		<= (cnt_clk<T1) ? 1'b0 : (cnt_clk<T2 ? 1'b1 : 1'b0); 
						sda_out_r 		<= 1'b1;//发送读标志
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1;
						cnt_scl 	<= 4'b0;
					end     
				R_ACK3:
					begin
						sda_tri 	<= 1'b1;
						scl_r 		<= (cnt_clk<T1) ? 1'b0 : (cnt_clk<T2 ? 1'b1 : 1'b0); 
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1;
						cnt_scl 	<= 4'b0;
					end 
				R_DATA:
					begin
						sda_tri 	<= 1'b1;
						scl_r 		<= (cnt_clk<T1) ? 1'b0 : (cnt_clk<T2 ? 1'b1 : 1'b0); 
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1;
						cnt_scl 	<= (cnt_clk==DIV/2-1) ? cnt_scl+ 1 : cnt_scl;
						case(cnt_scl)
							4'b0000: IIC_Read_Data_r[7] <= oled_sda_io;
							4'b0001: IIC_Read_Data_r[6] <= oled_sda_io;
							4'b0010: IIC_Read_Data_r[5] <= oled_sda_io;
							4'b0011: IIC_Read_Data_r[4] <= oled_sda_io;
							4'b0100: IIC_Read_Data_r[3] <= oled_sda_io;
							4'b0101: IIC_Read_Data_r[2] <= oled_sda_io;
							4'b0110: IIC_Read_Data_r[1] <= oled_sda_io;
							4'b0111: IIC_Read_Data_r[0] <= oled_sda_io;                                                                                                                                                                                                                                                        
                        endcase
                    end   
				R_ACK4://只有这个是主机发送应答
					begin
						sda_tri 	<= 1'b0;
						scl_r 		<= (cnt_clk<T1) ? 1'b0 : (cnt_clk<T2 ? 1'b1 : 1'b0); 
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1;
						cnt_scl 	<= 4'b0;
                        sda_out_r<=1;//主机发送高电平无效应答
					end    
				default://若不跳入以上状态，则STOP
					begin
						sda_tri 	<= 1'b0;
						scl_r 		<= (cnt_clk<T1) ? 1'b0 : 1'b1; 
						sda_out_r 		<= (cnt_clk<T2) ? 1'b0 : 1'b1; 
						cnt_clk 	<= (cnt_clk>=DIV-1) ? 0 : cnt_clk+1;
						cnt_scl 	<= 4'b0;
					end                 
            endcase
end
end
    	
wire oled_pclk_r/* synthesis mark_debug=true */;
assign oled_pclk_o = oled_pclk_r;
wire locked;
//108MHz时钟
  clk_wiz_0 instance_name
   (
    // Clock out ports
    .clk_out1(oled_pclk_r),     // output clk_out1
    // Status and control signals
    .resetn(rst_n), // input resetn
    .locked(locked),       // output locked
   // Clock in ports
    .clk_in1(cmos_data_clk_150m_o));      // input clk_in1

endmodule