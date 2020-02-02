module test;
	reg MCS, SCS, reset, clk;
	wire serial;
	wire [15:0] Data_out_mem,Data_in_mem;
	wire r, w;
	wire ready, ok, fail, checkerr, noAnswer;
	
	mem m(r,w,Data_in_mem,Data_out_mem,4'b0001,clk,1'b1);
	master M(
		serial, reset, clk, MCS, Data_out_mem,r,
		ready, ok, fail, checkerr, noAnswer
	);
	
	slave s1(
		8'h01, serial, reset, clk,
		SCS,Data_in_mem,w
	);
	
	slave s2(
		8'h02, serial, reset, clk,
		SCS,Data_in_mem,w
	);
	
	slave s3(
		8'h03, serial, reset, clk,
		SCS,Data_in_mem,w
	);
	
	slave s4(
		8'h04, serial, reset, clk,
		SCS, Data_in_mem, w
	);
	
	always #10 clk=~clk;
	
	initial
	begin
		$readmemb("test_arith.bin",m.mem);
		clk=0;
		reset=1;
		MCS = 0;
		SCS = 0;
		#25 reset=0; MCS = 1;
		#10 SCS = 1;
	
	end
endmodule
