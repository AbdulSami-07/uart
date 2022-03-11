module Uart (data,Tx, Rx, clk, rst);
input clk, rst;
input Rx;
output Tx;
output [7:0] data;

wire [7:0] data_received;
wire tx_init;

UartReceiver #(868) ur0 (.data(data_received), .done(tx_init), .clk(clk), .Rx(Rx), .rst(rst));
UartTransmitter #(868) ut0 (.Tx(Tx), .data(data_received), .tx_init(tx_init), .clk(clk), .rst(rst));

assign data = data_received;

endmodule

