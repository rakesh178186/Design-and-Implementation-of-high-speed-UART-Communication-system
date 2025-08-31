`timescale 1ns / 1ps

module Rs232_Controller(clk,reset,data_in,start_flag,data_out,done_flag);

parameter N=8;
parameter n=8;

  input clk;  // Input clk 
  input reset;// Input reset
  input [(N*n)-1:0] data_in; // Input data_in
  output start_flag;
  output [(N*n)-1:0] data_out;//output data_out
  output done_flag;
  
  wire Rs232_Txd,Rs232_Rxd;
 
 assign Rs232_Rxd = Rs232_Txd;
  

 Rs232_Tx_nbytes tx(.clk(clk),
                    .reset(reset),
                    .tx_start_flag(start_flag),
                    .data_in(data_in),
                    .tx_done_flag(done_flag),
                    .Rs232_Txd(Rs232_Txd));

 Rs232_Rx_nbytes Rx(.clk(clk),
                    .reset(reset),
                    .Rs232_Rxd(Rs232_Rxd),
                    .data_out(data_out));
  

endmodule // END of Module
