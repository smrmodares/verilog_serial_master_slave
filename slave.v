`define START 8'b10101010
`define MASTER_ADDR 8'b0
`define OK 8'h01
`define FAIL 8'h00
// ----------------------

module slave(
	input [7:0] addr,
	inout serial,
	input reset, clk,
	input CS,
	output reg [15:0] mem_write,
	output reg w
);
	// flip flop registers
	reg [1:0] state_reg, state_next;

	reg [7:0] checksum;

	
	reg [31:0] send_next,send_reg;
	reg [4:0] cnt_next, cnt_reg;

	
	localparam [1:0]
	idle = 2'b00,
	recive = 2'b01,
	check = 2'b10,
	send = 2'b11;

	always @(posedge clk)
	begin
		if(reset == 1)
		begin
			state_reg <= idle;
			send_reg <= 32'b0;
			cnt_reg <= 5'b0;
		end
		else
		begin
			state_reg <= state_next;
			send_reg <= send_next;
			cnt_reg <= cnt_next;	
		end
	end
	
	assign serial = (state_reg == send) ? send_reg[cnt_reg] : 1'bz;
	
	integer i;
	
	always @*
	begin
		// secure initial value
		state_next = state_reg;
		send_next = send_reg;
		cnt_next = cnt_reg;
		checksum = 0;
		w = 1'bz;
		
		
		case(state_reg)
			idle:
				if (CS)
				begin
					cnt_next = 0;
					state_next = recive;
				end
				else
					state_next = idle;
			recive:
			begin
				send_next = {serial, send_reg[31:1]};
				if (cnt_reg == 'd31)
				begin
					state_next = check;
				end
				else
				begin
					cnt_next = cnt_reg + 1;
					state_next = recive;
				end
			end
			
			check:
			begin
				if (send_reg[31:24] != `START)
				begin
					cnt_next = cnt_reg - 8;
					send_next = {send_reg[23:0], 8'b0};
					state_next = recive;
				end
				else if (send_reg[23:16] != addr)
				begin
					cnt_next = cnt_reg - 16;
					send_reg = {send_reg[15:0], 16'b0};
					state_next = recive;
				end
				else
				begin
					// calculate checksum using for
					
					for (i = 0; i <= 7; i = i + 1) begin
						checksum[i] = send_reg[i + 16] + send_reg[i + 8];
					end
					// possible bug
					if (send_reg[7:0] == checksum)
					begin
						w = 1;
						mem_write = send_reg[23:8];
						send_next = {`START, `MASTER_ADDR, `OK, `OK};
						state_next = send;
					end
					else
					begin
						send_next = {`START, `MASTER_ADDR, `FAIL, `FAIL};
						state_next = send;
					end
					cnt_next = 0;
				end
			end	
			
			send:
			begin
				w = 0;
				//serial = send_reg[cnt_reg];
				if (cnt_reg == 'd31)
				begin
					cnt_next = 0;
					send_next = 0;
					state_next = idle;
				end
				else
				begin
					cnt_next = cnt_reg + 1;
					state_next = send;
				end
			end	
		endcase
	end
	

endmodule
