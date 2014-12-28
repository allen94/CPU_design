`timescale 1ns/100ps

module stimulus;

reg clk;
reg  rst_n;


top top1(	.clk(clk),
			.rst_n(rst_n));

initial
fork
	clk=1'b1;
	rst_n=0;

#49 rst_n=1;
#49 $readmemb("binary.txt",top1.IF_ID.Instruction);
#49	$readmemh("data.txt",top1.wb.m1.data1);
forever	#2 clk=~clk;

join

endmodule
