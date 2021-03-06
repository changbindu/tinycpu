/*
 * This is the L1 Data Cache for TinyCPU
 * Author : Yann Sionneau <yann.sionneau@gmail.com>
 */
module dcache( 
	input clk,
	input reset,

	input [15:0] addr, // 64 kB of total memory
	input en,
	input we,

	output [31:0] cache_do,
	output ack,

	output [15:0] main_memory_addr,
	output main_memory_en,
	output main_memory_we,
	output [31:0] main_memory_di,
	input main_memory_ack,
	input [31:0] main_memory_do
);

/*
* D-Cache size is 8 kB
* 1024 lines of 2 words ( 64 bits )
*/

parameter IDLE = 2'd0;
parameter CACHE_MISS = 2'd1;

reg [1:0] state;

reg [63:0] do;
reg [2:0] tag_do;
reg [63:0] icache[1023:0];
reg [2:0] tag[1023:0];

reg update_cache;
reg ack_reg;

reg main_memory_en_reg;
reg main_memory_we_reg;
reg main_memory_addr_reg;
reg cache_do_reg;

assign main_memory_en = main_memory_en_reg;
assign main_memory_we = main_memory_we_reg;
assign main_memory_addr = main_memory_addr_reg;
assign ack = ack_reg;
assign cache_do = cache_do_reg;

always @(posedge clk)
begin
	if ( ~reset )
	begin
		if (update_cache)
			icache[ addr[12:3] ] <= main_memory_do;

		do <= icache[ addr[12:3] ];
	end
end

always @(posedge clk)
begin
	if ( ~reset )
	begin
		if (update_cache)
			tag[ addr[12:3] ] <= addr[15:13];

		tag_do <= tag[ addr[12:3] ];
	end
end


always @(posedge clk)
begin

	if (reset)
	begin
		state <= IDLE;
		ack_reg <= 0;
		main_memory_en_reg <= 0;
		main_memory_we_reg <= 0;
	end
	else
	begin

		case ( state )
		IDLE:
		begin
			if (en)
			begin
				if (addr[15:13] == tag_do)
				begin
					state <= CACHE_MISS;
					main_memory_addr_reg <= addr;
					main_memory_en_reg <= 1;
					main_memory_we_reg <= 0;
					ack_reg <= 0;
				end
				else
				begin
					ack_reg <= 1;
					state <= IDLE;
					if (addr[1])
						cache_do_reg <= do[31:0];
					else
						cache_do_reg <= do[63:32];
				end
			end
			else
			begin
				ack_reg <= 0;
				state <= IDLE;
			end
		end

		CACHE_MISS:
		begin
			if (main_memory_ack)
			begin
				cache_do_reg <= main_memory_do;
				ack_reg <= 1;
				state <= IDLE;
			end
			else
			begin
				state <= CACHE_MISS; // waiting for slow main memory to answer
				ack_reg <= 0;
			end
		end
		endcase

	end
end

endmodule
