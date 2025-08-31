`timescale 1ns / 1ps

module tb_Rs232_Controller;

parameter N = 8;
parameter n = 8;

reg clk, reset;
reg [(N * n) - 1: 0] data_in;
wire start_flag;
wire done_flag;
wire [(N * n) - 1: 0] data_out;


Rs232_Controller uut (
  .clk(clk),
  .reset(reset),
  .start_flag(start_flag),
  .data_in(data_in),
  .done_flag(done_flag),
  .data_out(data_out)
);

initial 
begin

#10 clk = 1'b0; reset = 1'b0;

data_in = 64'b000010101010101000001010101010100000101010101010;

#50 reset = 1'b1;

end
always #0.005 clk = ~clk;
endmodule
