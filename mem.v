module mem(r,w,in,out,address,clk,cs);
	input r,w,cs;
	input [15:0] in;
	output reg [15:0] out;
	input clk;
	input [3:0] address;
	
	reg [15:0] mem[0:15];
	
	always @(posedge clk)
	begin
		if(cs)
		begin
			if(r)
				out<=mem[address];
			else if(w)
				mem[address]<=in;
		end	
		else
			out<=16'bz;
	end	
endmodule