`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
/*
Company : Liyang Milian Electronic Technology Co., Ltd.
Brand: 米联客(msxbo)
Technical forum：uisrc.com
taobao: osrc.taobao.com
Create Date: 2019/02/27 22:09:55
Module Name: uart_top_TB
Description: uart simulation test module
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


module uart_top_TB;

reg clk_i;
reg uart_rx_i;
wire uart_tx_o;

uart_top u_uart_top
(
.clk_i  (clk_i),
.uart_rx_i  (uart_rx_i),
.uart_tx_o  (uart_tx_o)
);
parameter CLK50M_BAUD_DIV  = 104166;
//parameter CLK100M_BAUD_DIV = 10416.6*10;
initial
begin
        clk_i = 0;
		uart_rx_i = 1'b1;

		// Wait 100 ns for global reset to finish
		#96
		#CLK50M_BAUD_DIV
		uart_rx_i = 1'b1;//IDLE
		#CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;//start
        //1111_1111
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b1;
         #CLK50M_BAUD_DIV
        uart_rx_i = 1'b1;
         #CLK50M_BAUD_DIV
        uart_rx_i = 1'b1;
         #CLK50M_BAUD_DIV
        uart_rx_i = 1'b1;
         #CLK50M_BAUD_DIV
        uart_rx_i = 1'b1;
         #CLK50M_BAUD_DIV
        uart_rx_i = 1'b1;
         #CLK50M_BAUD_DIV
        uart_rx_i = 1'b1;
         #CLK50M_BAUD_DIV
        uart_rx_i = 1'b1;        
         #CLK50M_BAUD_DIV
        uart_rx_i = 1'b1;//stop             
         //#808320
        //0000_0000
        #CLK50M_BAUD_DIV        
        uart_rx_i = 1'b0;//start
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
         #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
         #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
         #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
         #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
          #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
          #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
          #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;        
           #CLK50M_BAUD_DIV
        uart_rx_i = 1'b1;//stop   
        
        #CLK50M_BAUD_DIV
      //0000_0000
        uart_rx_i = 1'b0;//start
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;           
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b1;//stop            
    
      #CLK50M_BAUD_DIV
    //0000_0100  
        uart_rx_i = 1'b0;//start
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b1;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;           
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b1;//stop       
//发送FF00_0004结束
/*
    #CLK50M_BAUD_DIV
    //1111_1111  
        uart_rx_i = 1'b0;//start
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b1;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b1;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b1;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b1;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b1;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b1;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b1;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b1;           
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b1;//stop     

      #CLK50M_BAUD_DIV
    //0000_0000  
        uart_rx_i = 1'b0;//start
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;           
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b1;//stop     

      #CLK50M_BAUD_DIV
    //0000_0000 
        uart_rx_i = 1'b0;//start
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;           
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b1;//stop             

      #CLK50M_BAUD_DIV
    //0000_0000 
        uart_rx_i = 1'b0;//start
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;           
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b1;//stop             
//发送FF00_0000结束*/
    #CLK50M_BAUD_DIV
    //1111_1111  
        uart_rx_i = 1'b0;//start
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b1;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b1;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b1;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b1;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b1;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b1;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b1;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b1;           
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b1;//stop     

      #CLK50M_BAUD_DIV
    //0000_0000  
        uart_rx_i = 1'b0;//start
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;           
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b1;//stop     

      #CLK50M_BAUD_DIV
    //0000_0000 
        uart_rx_i = 1'b0;//start
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;           
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b1;//stop             

      #CLK50M_BAUD_DIV
    //0000_0010 
        uart_rx_i = 1'b0;//start
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b1;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b0;           
        #CLK50M_BAUD_DIV
        uart_rx_i = 1'b1;//stop             
//发送FF00_0002结束

end

always 
    begin
        #10 clk_i = ~clk_i;
    end
    
endmodule


