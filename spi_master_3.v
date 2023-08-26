`timescale 1ns/1ps
module spi_master(
    input sys_clk,//50Mhz
    input sys_rst_n,

    input busy,
    input [3:0]addr,
    input [15:0]data_in,
    output [23:0]data_out,//从机发出、主机接收的数据

    //四线制spi
    input spi_miso,
    output spi_cs,
    output spi_sck,//5Mhz
    output spi_mosi,
    
    input spi_send,
    output send_done
);
    reg [7:0] count;//传输数据计数器
    
    //状态机四个状态：等待，拉低CS，发送数据，结束发送
    localparam IDLE=0,
    CS_L=1,
    DATA=2,
    FINISH=3;
    reg [3:0]cur_st,nxt_st;
    
    reg [23:0] data_latch;
    reg sck_reg ;
    reg spi_sck_m;
    reg cs_reg;
    reg send_done_reg;
    reg spi_mosi_reg;

    reg [3:0]div_cnt ;

    //时钟分频
    always@(posedge sys_clk or negedge sys_rst_n) begin
       if(~sys_rst_n)
       div_cnt <= 0;
       else begin
        if(div_cnt==4)
        div_cnt <= 0;
        else
        div_cnt <= div_cnt+1;
       end
    end
   
    //产生5MHz的时钟
    always@(posedge sys_clk or negedge sys_rst_n) begin
       if(~sys_rst_n)
       sck_reg <= 0;
       else begin
        if(div_cnt==4)
        sck_reg <= ~sck_reg;
        else
        sck_reg <= sck_reg;
       end
    end

    //sck只有在CS拉低时才变化，其他时都为低
    always@(*)
    if(spi_cs)
       spi_sck_m=0;
       else begin
        if(cur_st==FINISH)
          spi_sck_m=0;
          else if(~spi_cs)
          spi_sck_m=sck_reg;
                else
          spi_sck_m=0;      

       end 
    assign spi_sck = spi_sck_m;
    //主状态机   
    always@(posedge sck_reg or negedge sys_rst_n) begin
      if(~sys_rst_n)
        cur_st<=0;
        else
        cur_st<=nxt_st;
    end

    always@(*)
    begin
      nxt_st=cur_st;
      case (cur_st)
          IDLE:if(spi_send)
               nxt_st=CS_L;
          CS_L:nxt_st=DATA;
          DATA:if (count==24)//已改
                  nxt_st=FINISH;
          FINISH:if(busy)
                 nxt_st=IDLE;
        default:nxt_st=IDLE;        
        
      endcase
    end

    //产生发送结束标志
    always @(*) 
    if(~sys_rst_n)
      send_done_reg=0;
    else if(cur_st==FINISH)
      send_done_reg=1;
         else
      send_done_reg=0;

    assign send_done=send_done_reg;  

    //产生CS
    always@(*) 
      if(~sys_rst_n)
        cs_reg=1;
      else if(count>=1 && count<=24)
        cs_reg=0;
            else
        cs_reg=1;

    assign spi_cs=cs_reg;

    //发送数据计数
    always@(posedge sck_reg or negedge sys_rst_n) begin
        if(~sys_rst_n)
           count<=0;
        else if(cur_st==DATA)
           count<=count+1;
             else if(cur_st==IDLE|cur_st==FINISH)
            count<=0;
    end
    //MOSI数据
    always@(posedge sck_reg or negedge sys_rst_n) begin
       if(~sys_rst_n)
         spi_mosi_reg<=0;
         else if(cur_st==DATA)
         begin
            data_latch[23:1]<=data_latch[22:0];
            spi_mosi_reg<=data_latch[23];    
         end   
               else if(spi_send)
            data_latch <= {4'b1000,addr,data_in};     
    
    end   
    
    assign spi_mosi=spi_mosi_reg;
endmodule