
module UartReceiver
#(parameter CLOCK_PER_BIT = 868)
(data, done, clk, Rx, rst);
input clk, Rx, rst;
output [7:0] data;
output done;
reg [7:0] data;
reg done;


/*
1. xc7a100t-1csg324 has clock frequency of 100MHz.
2. This uart_rx works at the baud rate of 115200.
3. Clock per bit = clock frequency / baud rate = 100MHz /115200 = 868.
3. sm -> state machine.
4. rx_temp -> data from Rx is latched on this FF. 
5. Rx -> it brings 1 byte data bit by bit and each bit remains on this line
	for no. of clk = ClOCK_PER_BIT
6. data -> all bits of rx_temp are latched to it after a succesful transmission

*/
//parameter ClOCK_PER_BIT = 868;

/*
1. There 5 states in the uart.
2. the state machine is called 
3. Idle = 0, rx_start_bit = 1, rx_temp_bits = 2, rx_stop_bit = 3, rx_reset = 4;
*/
parameter IDLE = 3'd0;
parameter RX_START_BIT = 3'd1;
parameter RX_DATA_BITS = 3'd2;
parameter RX_STOP_BIT = 3'd3;
parameter RX_RESET = 3'd4;

reg [9:0] clock_count = 10'd0; // clock per bit = 868 use [9:0]
reg [7:0] rx_temp = 8'd0; 
reg [2:0] rx_temp_index = 3'd0;
reg [2:0] RX_SM_STATE = 3'd0; // RX_SM_STATE = IDLE

always @(negedge clk or posedge rst)
begin
/*
1. serial data is sampled at half of clock per bit
*/
	if ( rst == 1'b1)
		RX_SM_STATE <= RX_RESET;
	else
	begin
		case (RX_SM_STATE)
			IDLE:
/*
1. clock_count = 0, rx_temp_index = 0.
2. serial data received is 0, then sm goes to rx_start_bit state.
*/
			begin
				clock_count <= 10'd0;
				rx_temp_index <= 3'd0;
				done <= 1'b0;
				if (Rx == 1'b0)
					RX_SM_STATE <= RX_START_BIT;
				else
					RX_SM_STATE <= IDLE;
			end
			
			RX_START_BIT:
/*
1. clock_count keeps incremented till reaches half of CLOCK_PER_BIT, then serial data is sampled.
2. if serial data  remains 0 for half of clock per bit, then sm moves rx_temp_bits
	state.
*/
			begin
				if ( clock_count == (CLOCK_PER_BIT - 1)/2)
					begin
						if ( Rx == 1'b0)
							begin
								clock_count <= 10'd0; // resetting the clock_count
								RX_SM_STATE <= RX_DATA_BITS;
							end
						else
							begin
								clock_count <= 10'd0;
								RX_SM_STATE <= IDLE;
							end
					end
				else
					clock_count <= clock_count + 1;
			end
			
			RX_DATA_BITS:
	/*
1. since we sample start bit at half of CLOCK_PER_BIT, if we increment clock_count to
	(CLOCK_PER_BIT-1), then data bit will automatically be sampled at half of CLOCK_PER_BIT.
	Similiar for next bit, reset clock_count and increment it to (CLOCK_PER_BIT-1).
*/	
			begin
				if (clock_count < (CLOCK_PER_BIT - 1))
				begin
					clock_count <= clock_count + 1;
					RX_SM_STATE <= RX_DATA_BITS;
				end
				else
				begin
					clock_count <= 10'd0;
					rx_temp[rx_temp_index] <= Rx;
					if ( rx_temp_index < 7) 
					begin
						rx_temp_index <= rx_temp_index + 1;
						RX_SM_STATE <= RX_DATA_BITS;
					end
					else
					begin
						rx_temp_index <= 3'd0;
						RX_SM_STATE <= RX_STOP_BIT;
					end
				end
			end
					
			RX_STOP_BIT:
/*
1. stop bit = 1, then 1 byte data is received.
2. set data = rx_temp
*/
			begin
				if (clock_count < (CLOCK_PER_BIT - 1))
				begin
				clock_count <= clock_count + 1;
				RX_SM_STATE <= RX_STOP_BIT;
				end
				else 
				begin
					if (Rx)
					begin
						done <= 1'b1;
						data <= rx_temp;
						clock_count <= 10'd0;
						RX_SM_STATE <= RX_RESET;
					end
				end
			end
			
			RX_RESET:
/*
1. cleaning rx_temp register by setting to 8'd0;
2. moving to idle state.
*/
			begin
				rx_temp <= 8'd0;
				rx_temp_index <= 3'd0;
				clock_count <= 10'd0;
				RX_SM_STATE <= IDLE;
			end
			
			default:
				RX_SM_STATE <= IDLE;
		endcase
	end
end
endmodule
							
