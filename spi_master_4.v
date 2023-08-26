`timescale 1ns/1ps
module spi_master(
    input sys_clk,//50Mhz
    input sys_rst_n,

    //四线制spi
    input spi_miso,
    output spi_cs,
    output spi_sck,//5Mhz
    output spi_mosi,
    
    input spi_send
);
    reg [7:0] count;//传输数据计数器
    
    //状态机四个状态：等待，拉低CS，发送数据，结束发送
    localparam IDLE=0,
    //CS_L=1,
    DATA=2,
    FINISH=3;
    reg [3:0]cur_st,nxt_st;

    //置入数据
    parameter  addr = 4'b0100;
    parameter data_in = 16'b1110_0110_1011_0111;
    
    parameter busy = 0;//由于从机对主机的反馈并无该端口，故置数。让数据只传输一次

    reg [23:0] data_latch;
    reg sck_reg ;
    reg spi_sck_m;
    reg cs_reg;
    reg send_done_reg;
    reg spi_mosi_reg;

    reg [3:0]div_cnt ;

    //clk_5MHz assignment
    always@(posedge sys_clk or negedge sys_rst_n) begin
       if(~sys_rst_n)begin
       div_cnt <= 0;
       sck_reg <= 0;
       end
       else begin
        if(div_cnt==4)begin
        div_cnt <= 0;
        sck_reg <= ~sck_reg;
        end
        else begin
        div_cnt <= div_cnt+1;
        sck_reg <= sck_reg;
       end
    end
    end
   
   //sck只有在CS拉低时才变化，其他时都为低
    always@(*)begin//要把always块中的语句括起来，否则只执行第一句
    if(spi_cs)
       spi_sck_m<=0;
       else 
       spi_sck_m<=sck_reg;     
    end

    //去毛刺
    reg spi_sck_en;
    reg [7:0] spi_sck_m_neg;
    always@(negedge spi_sck_m or sys_rst_n)begin
       if(~sys_rst_n)begin
       spi_sck_m_neg<=0;
       spi_sck_en<=1;
       end
       else if(spi_sck_m_neg<=23) begin
            spi_sck_m_neg<=spi_sck_m_neg+1;
            spi_sck_en<=spi_sck_en;
           end
           else begin
      spi_sck_m_neg<=0;
      spi_sck_en<=0;
       end
    end

assign spi_sck = spi_sck_m && spi_sck_en;
    //状态机第一段   
    always@(posedge sck_reg or negedge sys_rst_n) begin
      if(~sys_rst_n)
        cur_st<=0;
        else
        cur_st<=nxt_st;
    end
    //状态机第二段
    always@(*)
    begin
      case (cur_st)
          IDLE:if(spi_send)
               //nxt_st<=CS_L;
               nxt_st<=DATA;
          //CS_L:nxt_st<=DATA;
          DATA:if (count==23)//已改
                  nxt_st<=FINISH;
          FINISH:if(busy)
                 nxt_st<=IDLE;
        default:nxt_st<=IDLE;           
      endcase
    end
   /*//状态机第三段
   always @(posedge sck_reg or negedge sys_rst_n )
   if(~sys_rst_n)begin
     cs_reg<=1;
     //sck_reg_m<=0;
     count<=0;
     spi_mosi_reg<=0;
     data_latch <= {4'b1000,addr,data_in};
     send_done_reg<=0;
   end
   else
     case(cur_st)
     IDLE:begin
       cs_reg<=1;
       //sck_reg_m<=0;
       count<=0;
       spi_mosi_reg<=0;
       data_latch <= {4'b1000,addr,data_in};
       send_done_reg<=0;
     end 
     DATA:begin
       cs_reg<=0;
       //sck_reg_m<=sck_reg;
       count<=count+1;
       data_latch<={data_latch[22:0],1'b0};
       spi_mosi_reg<=data_latch[23];
       send_done_reg<=0;
     end
     FINISH:begin
       cs_reg<=1;
       //sck_reg_m<=0;
       count<=0;
       spi_mosi_reg<=0;
       send_done_reg<=1;

     end
     endcase
assign spi_sck = spi_sck_m;
assign spi_cs=cs_reg;
assign spi_mosi=spi_mosi_reg;
*/

 
    
    //产生发送结束标志
    always @(*) begin
    if(~sys_rst_n)
      send_done_reg<=0;
    else if(cur_st==FINISH)
      send_done_reg<=1;
         else
      send_done_reg<=0;
    end

    //assign send_done=send_done_reg;  

    //产生CS
    always@(*) begin
      if(~sys_rst_n)
        cs_reg<=1;
      else if(cur_st==DATA)
        cs_reg<=0;
            else
        cs_reg<=1;
    end
    
    assign spi_cs=cs_reg;

    //发送数据计数
    always@(posedge sck_reg or negedge sys_rst_n) begin
        if(~sys_rst_n)
           count<=0;
        //else if(cur_st==DATA)//比清零条件优先级高
           //count<=count+1;
             else if(count==23||cur_st==IDLE||cur_st==FINISH)
            count<=0;
            else
            count<=count+1;
    end
    //MOSI数据
    always@(posedge sck_reg or negedge sys_rst_n) begin
       if(~sys_rst_n)begin
         spi_mosi_reg<=0;
         data_latch <= {4'b1000,addr,data_in}; 
       end
         else if(spi_send)
         begin
            data_latch<={data_latch[22:0],1'b0};
            spi_mosi_reg<=data_latch[23];    
         end   
              else if(spi_send)
            data_latch <= {4'b1000,addr,data_in};     
        
    end   
    
    assign spi_mosi=spi_mosi_reg;
  
   
    
endmodule