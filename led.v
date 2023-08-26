`timescale 1ns / 1ns
/*1.共有4个LED灯，共阴极
  2.自定LED灯发光频率为50Hz
*/

module water_led(
    sys_clk,
    sys_rst_n,
    LED 
    );
    input sys_clk;
    input sys_rst_n;
    output reg[3:0] LED; 
    reg[31:0] count;
    parameter LT=25000000;//LED_Time,分频计数。
  

    //数码管闪烁计数器，一个灯管占1000000个时钟周期
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (~sys_rst_n) 
           count<=0;
           else if(count==LT-1)//同步清零，LT进制计数器，则在第LT个计数状态取清零信号（0是第一个状态）
           count<=0;
           else
           count<=count+1;
    end   
    /*
    //plan1:计数器计满，流水灯左移
    always @(posedge sys_clk or negedge sys_rst_n) begin
         if(~sys_rst_n)
           LED<=4'b0001;//假定流水灯共阴极，初始状态最右边的先亮
           else begin 
           if(count==LT-1)
           LED<={LED[2:0],LED[3]};//位拼接运算符，实现左移流水灯
              else
              LED<=LED;
           end   
    end    */ 
    //plan2:流水灯循环移动
    reg flag ;//flag:1,流水灯左移；0，流水灯右移
    /*
    reg[31:0] count_1;//flag翻转计数，切记不要忘掉计数器赋初值及累加！！！！
    parameter fT=100000000;//flag翻转计数，4个数码管，每个数码管1000000个时钟周期
       //左移/右移模式切换计数器
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if(~sys_rst_n)
           count_1<=0;
           else begin
              if(count_1 == fT-1)
                 count_1 <= 0;
                 else
                 count_1<=count_1+1;
           end
    end
    */
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if(~sys_rst_n)
          flag<=1;
          else begin
            if(LED == 4'b0001 )//同步计数
              flag=1;
              else if(LED == 4'b1000)
              flag=0;
                   else
                   flag=flag; 
          end     
    end

    always @(posedge sys_clk or negedge sys_rst_n) begin//posedge、negedge一定写正确
        if(~sys_rst_n)
          LED<=4'b0001;//流水灯共阴极，初始状态最右边的先亮
        else begin
        if(flag)begin
            if (count==LT-1)
               LED<={LED[2:0],LED[3]};//位拼接运算符，实现左移流水灯 
            else
               LED<=LED;
        end
        else begin
           if (count==LT-1) 
               LED<={LED[0],LED[3:1]} ;
           else
               LED<=LED;
        end   
    end
    end
    //ILA IP核例化为子模块
      ila_0 ila_0 (
	.clk(sys_clk), // input wire clk


	.probe0(LED), // input wire [3:0]  probe0  
	.probe1(sys_rst_n) // input wire [0:0]  probe1
);      
endmodule
