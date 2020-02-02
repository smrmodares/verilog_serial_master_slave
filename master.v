`define START 8'b10101010
`define MASTER_ADDR 8'b0
`define OK 'h01
`define FAIL 'h00
// ----------------------

module master(
	inout serial,
	input reset, clk,
	input CS,
	input [15:0] mem_read,
	output reg r,
	output reg ready, ok, fail, checkerr, noAnswer
);
	// flip flop registers
	reg [2:0] state_reg, state_next;
	reg [7:0] checksum;
	
	reg [31:0] send_next,send_reg;
	reg [4:0] cnt_next, cnt_reg;

	
	localparam [2:0]
	idle = 3'b000,
	init = 3'b001,
	send = 3'b010,
	recive = 3'b011,
	check = 3'b100,
	waiting = 3'b101;

	always @(posedge clk)
	begin
		if(reset == 1)
		begin
			state_reg <= idle;
			send_reg <= 0;
			cnt_reg <= 0;
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
		checksum = 8'b0;
		send_next = send_reg;
		cnt_next = cnt_reg;
		r = 0;
		ready = 1'b0;
		ok = 1'b0;
		fail = 1'b0;
		checkerr = 1'b0;
		
		case(state_reg)
			idle:
				if (CS)
				begin
					state_next = init;
					r = 1;
				end
				else
					state_next = idle;
			init:
			begin
				r = 0;
				// calculate checksum using for
				
				for (i = 0; i <= 7; i = i + 1) begin
					checksum[i] = mem_read[i + 8] + mem_read[i];
				end
				
				send_next = {`START, mem_read, checksum};
				
				cnt_next = 8'b0;
				r = 0;
				state_next = send;
			end
			send:
			begin
				//serial = send_reg[cnt_reg];
				if (cnt_reg == 'd31)
				begin
					cnt_next = 0;
					send_next = 0;
					state_next = waiting;
				end
				else
				begin
					cnt_next = cnt_reg + 1;
					state_next = send;
				end
			end
			
			recive:
			begin
				send_next = {serial, send_reg[31:1]};
				if (cnt_reg == 'd31)
				begin
					cnt_next = 0;
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
				if (send_reg[31:24] != `START || send_reg[23:16] != `MASTER_ADDR)
				begin
					noAnswer = 1;
					state_next = idle;
					ready = 1;
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
						if (send_reg[15:8] == `OK)
							ok = 1;
						else if (send_reg[15:8] == `FAIL)
							fail = 1;
						else
							noAnswer = 1;
							ready = 1;
							state_next = init;
					end
					else
					begin
						checkerr = 1;
						ready = 1;
						state_next = init;
					end
				end
			end
			
			waiting:
				state_next = recive;

		endcase
	end
	

endmodule