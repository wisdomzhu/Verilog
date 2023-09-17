`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/09/09 17:26:32
// Design Name: 
// Module Name: da_spi_wr
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 通过FPGA控制AD5761输出指定电压
// 在AD5761运行中每配置一次控制寄存器都得先执行一个软件全更新命令
//软件全更新->写入控制寄存器（主要设置电压的范围）[写入该寄存器的数据内嵌在.v]->写入并且更新数模转换寄存器（写入该寄存器的数据根据换算公式，可得到具体的输出电压）
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module da_spi_wr(
	clk_i,								
	reset_i,
		
	voltage_data_i,		
	voltage_data_start,	

	sclk_o,
	sdi_o,								
	cs_o,								// 低电平数据有效
	ldac_o
);
//--------------------------------------Parameters
	// Reg_addr_cmd    DB19-DB16->REG ADDR-------------配置了三个寄存器
	localparam							CMD_SW_FULL_RESET       = 8'b0000_1111;//软件完全复位
	localparam							CMD_WR_CTRL_REG         = 8'b0000_0100;//写入控制寄存器
	localparam							CMD_WR_UPDATE_DAC_REG   = 8'b0000_0011;//写入和更新寄存器
							
	// Reg_data
	localparam							CTRL_DATA               = 16'b0000_0010_0110_1011;	//控制寄存器的运行模式 DB[15:11]=0000_0-------主要给出输入的数据对应十进制数是多少，且输出电压范围是多少
	//DB[10:9] CV:01->clear电压选择：中间电平
	//DB8      OVR:0->是否允许超出额定范围的5%:不允许
	//DB7      B2C:0->直接二进制编码;输入的编码是以什么形式对应相应的10进制	   换算成对应的十进制数即为D
	//DB6      ETS:1->模具温度高于150度内部数字电源是否断电:断电
	//DB5      IRO:1->内反射是否打开:打开--------------the internal reference is on by default 
	//DB[4:3]  PV:01->上电电压：中间电平;
	//DB[2:0]  RA:011->0~5v;输出电压范围	对应换算公式中的M=2，C=0 

	//换算公式中 N=16 （对AD5761）
			
	//localparam							VOLTAGE_DATA = 16'b1111_1111_1111_1111;
	
localparam                              S_IDLE				= 0;
localparam                              S_W_REG				= 1;
localparam                              S_STOP				= 2;
localparam                              S_UPDATA_DAC		= 3;
	
localparam                              NUM_STATE_W		= 3;
	
	reg 	[NUM_STATE_W-1:0]			state;	
//--------------------------------------Interface
    input								clk_i;
    input  						        reset_i;//高电平复位

  	input	[15:0]						voltage_data_i;//要输入的16位数据
	output 								voltage_data_start;//开始传输数据的标志
  	 	
    output								sdi_o;
    output								cs_o;       //低电平数据有效
    output								sclk_o;
	output                              ldac_o;
//--------------------------------------Implementation
    //----------------------------------输入数据变化时配置一次
	reg 	[15:0]						voltage_data_r=15'd0;
	reg 	[15:0]						voltage_data_rr=15'd0;
	reg									voltage_data_start = 0;
	always@(posedge clk_i)begin//等了一拍
		voltage_data_r                  <= voltage_data_i;
		voltage_data_rr                 <= voltage_data_r;
	end					
	always@(posedge clk_i)begin
		if (voltage_data_rr == voltage_data_r)
			voltage_data_start          <= 1'b0;
		else            
			voltage_data_start          <= 1'b1;//------第一个时钟上升沿来时，不能开始；第二个时钟上升沿来时，开始。voltage_data_start是脉宽为1个时钟周期的脉冲
	end		
	//----------------------------------状态输出
reg                    [   7:0]         addr_r = 0                 ;//寄存器地址
reg                    [  15:0]         data_r = 0                 ;//寄存器数据
reg                    [   2:0]         order_r = 0                ;//不同的指令配置不同的寄存器及输入数据
    //----------------------------------LDAC
reg                    ldac_r;	
	//----------------------------------关键
	always @(posedge clk_i) begin
		case(order_r)
			3'd0: begin//-----------Software full reset
				addr_r                  <= CMD_SW_FULL_RESET;
				data_r                  <= 16'd0;
			end
			3'd1: begin//-----------a software full reset command must be written to the device before write to control register
				addr_r                  <= CMD_WR_CTRL_REG;
				data_r                  <= CTRL_DATA;
			end
			3'd2: begin//----------Write and update DAC register,irrespective of the state of LDAC//-----用输入移位寄存器中的数据更新输入寄存器和数模转换寄存器
				addr_r                  <= CMD_WR_UPDATE_DAC_REG;
				data_r                  <= voltage_data_r;//寄存输入移位寄存器中的数据
			end
			3'd3: begin
				addr_r                  <= CMD_WR_UPDATE_DAC_REG;//Why?  在控制寄存器原来模式下，可保证依次输入数据去更新DAC，从而依次得到不同输出电压
				data_r                  <= voltage_data_r;
			end
			default: begin
				addr_r                  <= 0;
				data_r                  <= 0;
			end
		endcase
		
		if(reset_i)begin
			addr_r                      <= 0;
			data_r                      <= 0;
		end
	end
	//----------------------------------SDI State
reg                    [5:0]         	reg_cnt = 24               ;//传输24位数据计数器
reg                                     sdi_r                      ;//mosi寄存器
reg                                     cs_r                       ;
	always @(posedge clk_i) begin
		case(state)
			S_IDLE: begin
				if(order_r == 3) begin
					if(voltage_data_start == 1) begin
						state <= S_UPDATA_DAC;
					end
					else begin
						state <= S_IDLE;
					end
				end
				else begin
					state <= S_W_REG;
					ldac_r <=0;
				end
			end
			S_W_REG: begin//----------写寄存器地址、及传输数据
				cs_r <= 0;
				if(reg_cnt > 16) begin
					sdi_r <= addr_r[reg_cnt-17];//从addr[7]~addr[0]
					reg_cnt <= reg_cnt - 1;
				end
				else begin//寄存器地址传输结束后，传输16位数据，从data_r[15]~data_r[0]
					sdi_r <= data_r[reg_cnt-1];
					reg_cnt <= reg_cnt - 1;
					if(reg_cnt == 0) begin
						state <= S_STOP;//寄存器地址和数据传输结束后，切到停止状态
						//--------------
						reg_cnt <= 24;
						sdi_r <= 0;//数据传输进入空闲态
						cs_r <= 1;//片选拉高
						order_r <= order_r + 1;//切到配置下一个寄存器
						if(order_r == 3) begin
							order_r <= order_r;//所有指令只发一次
						end
					end
				end
			end
			S_UPDATA_DAC:begin//----------order_r==3且voltage_data_start == 1才会切到S_UPDATA_DAC
				cs_r <= 0;
				if(reg_cnt > 16) begin
					sdi_r <= addr_r[reg_cnt-17];
					reg_cnt <= reg_cnt - 1;
				end
				else begin
					sdi_r <= data_r[reg_cnt-1];
					reg_cnt <= reg_cnt - 1;
					if(reg_cnt == 0) begin
						state <= S_STOP;
						//--------------
						reg_cnt <= 24;
						sdi_r <= 0;
						cs_r <= 1;
					end
				end
			end
			
			S_STOP: begin//----------切到空闲态
			    ldac_r <= 1;
				state <= S_IDLE;
			end

			default: begin
				state <= S_IDLE;
			end
		endcase
		
		if(reset_i) begin
			state                       <= S_IDLE;
			order_r                     <= 0;
			sdi_r                       <= 0;
			reg_cnt                     <= 24;
			cs_r                        <= 1;
			ldac_r                      <= 1;
		end
	end
//--------------------------------------output
    assign                              sclk_o  = clk_i;
	assign	                            sdi_o   = sdi_r;
	assign	                            cs_o    = cs_r;	
	assign                              ldac_o  = ldac_r;
endmodule
