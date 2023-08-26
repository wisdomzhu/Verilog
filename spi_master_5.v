`timescale 1ns/1ps
module spi_master(
    input sys_clk_i,//50Mhz
    input sys_rst_n,
    output mosi_o,
    output cs_o,
    output scl_o,//25MHz
    output ldac_o
);
reg cs_r;
reg scl_r;
reg [3:0]cnt_clk;
reg [7:0]cnt_scl;
reg mosi_r;
//reg [3:0]addr_order
//reg [3:0]addr=4'b0100;
//reg [15:0]data=16'b1110_0110_1011_0111;
reg [23:0]data_i=24'b0000_0100_1110_0110_1011_0111;
 assign cs_o=cs_r;
 assign scl_o=scl_r;
 assign mosi_o=mosi_r;

reg [1:0] current_state;
reg [1:0] next_state;

localparam IDLE=0;
localparam WR=1;
localparam FINISH=2;
localparam LDAC_UP=3;

reg busy=0;
reg [23:0] data_r=0;
reg [23:0] data_convert=0;
always@(posedge sys_clk_i)begin//延一拍
    data_r<=data_i;
    data_convert<=data_r;
end
/*
//control
always @(posedge sys_clk_i) begin
   case(addr_order)
   0:addr<=4'b0001;//write to input register(no update)
   1:addr<=4'b0010;//update DAC register from input register
   2:addr<=4'b0011;//write and update DAC register
   3:addr<=4'b0100;//write to control register  
   4:addr<=4'b0111; 
    
   endcase  
end
*/
reg ldac_up=0;
reg ldac_r=1;
always @(posedge sys_clk_i) begin
    if((data_convert==data_i) &&(ldac_up==0))begin
        ldac_r<=0;
    end
    else if(ldac_up)
     ldac_r<=1;
         else
     ldac_r<=ldac_r;       
end
assign ldac_o=ldac_r;

//状态机第一段
always @(posedge sys_clk_i ) begin
    if (~sys_rst_n) begin
       current_state<=IDLE;
    end
    else begin
       current_state<=next_state;
    end
end
//状态机第二段
always @(*) begin
    case(current_state)
     IDLE:
          begin
            if(ldac_r==0)
              next_state<=WR;
            else if(ldac_r)
              next_state<=current_state;//得想
          end
     WR:
        begin
            if(cnt_scl==24)
              next_state<=FINISH;
            else
              next_state<=current_state;
        end 
     FINISH:
        begin
            if(cnt_clk==0)
              next_state<=LDAC_UP;
            else
              next_state<=current_state;  
        end
     LDAC_UP:
        begin
            if(busy)
              next_state<=IDLE;
            else
              next_state<=current_state;  
        end        
     default:next_state<=current_state;                   
    endcase    
end
//状态机第三段
always @(posedge sys_clk_i) begin
    if(~sys_rst_n)begin
        cs_r<=1;
        cnt_clk<=0;
        cnt_scl<=0;
        scl_r<=0;
        mosi_r<=0;
    end 
    else begin   
    case(next_state)
        IDLE:
             begin
                cs_r<=1;
                //cnt_clk<=(cnt_clk<=3)?cnt_clk+1:0;
                cnt_scl<=0;
                scl_r<=0;
                mosi_r<=0;
             end
        WR:
            begin
                cs_r<=0;
                cnt_scl<=(cnt_scl<=23)?cnt_scl+1:0;
                //cnt_clk<=0;
                scl_r<=~scl_r;
                mosi_r<=data_convert[23-cnt_scl];
            end
        FINISH:
            begin
                cs_r<=1;
                cnt_scl<=0;
                cnt_clk<=(cnt_clk<=1)?cnt_clk+1:0;
                scl_r<=0;
                mosi_r<=0;
            end
        LDAC_UP:
            begin
                cnt_clk<=0;
                ldac_up<=1;
            end

        default:   
                begin
                cs_r<=1;
                cnt_scl<=0;
                //cnt_clk<=0;
                scl_r<=0;
                mosi_r<=1'bz;
            end         
    endcase
    end
end
endmodule