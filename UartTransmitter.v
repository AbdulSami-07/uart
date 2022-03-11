
module UartTransmitter 
#(parameter CLOCK_PER_BIT = 868)
(Tx, data, tx_init, clk, rst);
input clk, tx_init, rst;
input [7:0] data;
output Tx;
reg Tx;

/*
1. xc7a100t-1csg324 has clock frequency of 100MHz
2. This uart_rx works at the baud rate of 115200.
3. Clock per bit = clock frequency / baud rate = 100MHz /115200 = 868
3. sm -> state machine
4. tx_init -> if it is high transmission of data start
5. Tx -> byte to be transferred is load on it bit by bit.
*/

//parameter CLOCK_PER_BIT = 868;

/*
1. There 5 states in the uart.
2. the state machine is called 
3. Idle = 0, rx_start_bit = 1, rx_data_bits = 2, rx_stop_bit = 3, rx_reset = 4;
*/

parameter IDLE = 3'd0;
parameter TX_START_BIT = 3'd1;
parameter TX_DATA_BITS = 3'd2;
parameter TX_STOP_BIT = 3'd3;
parameter TX_RESET = 3'd4;

reg [9:0] clock_count = 9'd0; // clock per bit = 868 use [9:0]
reg [2:0] tx_temp_index = 3'd0;
reg [2:0] TX_SM_STATE = 3'd0; // TX_SM_STATE = IDLE
reg [7:0] tx_temp = 8'd0;

always @(negedge clk or posedge rst)
begin
	if (rst == 1'b1)
		TX_SM_STATE <= TX_RESET;
	else
	begin
		case (TX_SM_STATE)
			IDLE:
/*
1. initialize clock_count = 0, tx_temp_index = 0,  = 0, tx_done = 0
2. if tx_init is high then sm go to start bit state.
*/
			begin
				tx_temp <= data;
				clock_count <= 10'd0;
				tx_temp_index <= 3'd0;
				if (tx_init) 
				begin
					TX_SM_STATE <= TX_START_BIT;
				end
				else
					TX_SM_STATE <= IDLE;
			end
		
			TX_START_BIT:
/*
1. first Tx is set to 0, then clock_count is incremented upto (CLOCK_PER_BIT-1)
2. after that  sm goes to start data bits state.
*/
			begin
				Tx <= 1'b0; 
				if ( clock_count < (CLOCK_PER_BIT-1) )
				begin
					clock_count <= clock_count + 1;
					TX_SM_STATE <= TX_START_BIT;
				end
				else
				begin
					clock_count <= 10'd0;
					TX_SM_STATE <= TX_DATA_BITS;
				end
			end
			
			TX_DATA_BITS:
/*
1. serial data is set is LSB of tx_temp, then clock_count is incremented upto (CLOCK_PER_BIT-1)
2. tx_temp_index is incremented,s serial data is set for next higher bit of tx_temp.
3. after Tx is given MSB of tx_temp & clock_count is incremented upto 
	(CLOCK_PER_BIT-1),then clock_count = 0, tx_temp_index = 0 ,sm goes to stop bit state.
*/
			begin
				Tx <= tx_temp[tx_temp_index];
				if ( clock_count < (CLOCK_PER_BIT-1)) 
				begin
					clock_count <= clock_count + 1;
					TX_SM_STATE <= TX_DATA_BITS;
				end
				else
				begin
					clock_count <= 10'd0;
					tx_temp_index <= tx_temp_index + 1; 
					if (tx_temp_index > 7)
					begin
						TX_SM_STATE <= TX_STOP_BIT;
					end
					else
						TX_SM_STATE <= TX_DATA_BITS;
				end
			end
			
			TX_STOP_BIT:
/*
1. Tx is pulled high and clock_count is incremented upto (CLOCK_PER_BIT - 1)
2. after that clock_count = 0 and sm is moved to reset state.
*/
			begin
				Tx <= 1'b1;
				if (clock_count < (CLOCK_PER_BIT-1))
				begin
					clock_count <= clock_count + 1;
					TX_SM_STATE <= TX_STOP_BIT;
				end
				else
				begin
					clock_count <= 10'd0;
					TX_SM_STATE <= TX_RESET;
				end
			end
			
			TX_RESET:
/*
1.  clock_count = 0, tx_temp = 0, tx_temp_index = 0, and sm moves to idle state.
*/
			begin
				clock_count <= 10'd0;
				tx_temp <= 8'd0;
				tx_temp_index <= 3'd0;
				TX_SM_STATE <= IDLE;
			end
		
			default:
				TX_SM_STATE <= IDLE;
		endcase
	end
end
endmodule
