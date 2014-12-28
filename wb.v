module wb(input alu_zero
,input clk
,input rst_n
,input [1:0] control_wb
,input [2:0] control_mem
,input [31:0] result
,input [31:0] datamem_data
,input [4:0] wb_add_in
,output [31:0] wb_data
,output regwrite_wb
,output [4:0] wb_add_out
);


wire [70:0] MEM_WB;
wire [31:0] datatransfer;

assign wb_add_out=MEM_WB[70:66];
assign regwrite_wb=MEM_WB[0];

memory m1(.rst_n(rst_n)
,.memread(control_mem[2])
,.memwrite(control_mem[1])
,.address(result)
,.writemem_data(datamem_data)
,.readdata(datatransfer));

MEM_WBregister r1(.readdata(datatransfer)
,.clk(clk)
,.rst_n(rst_n)
,.result(result)
,.write_reg(wb_add_in)
,.WB(control_wb)
,.MEM_WB(MEM_WB));


WB_mux	WB_mux(
 MEM_WB[33:2]
,MEM_WB[65:34]
,MEM_WB[1]
,wb_data);

endmodule

//memory
module memory(
input rst_n
,input memwrite
,input memread
,input [31:0] address
,input [31:0] writemem_data
,output reg [31:0]readdata);

reg [31:0] data1 [63:0];
wire [31:0] num;
integer r;
assign num={2'b00,address[31:2]};

always@(*)
begin
	if(!rst_n) 
		begin
			for(r=0;r<64;r=r+1)
			data1[r]=32'b0;
		end
	else if(memwrite)  data1[num]<=writemem_data;
	else if (memread) readdata<=data1[num];
end

endmodule

//MEM_WBregister
module MEM_WBregister(
	input clk, 
	input rst_n,
	input [31:0] readdata,
	input [31:0] result,
	input [4:0] write_reg,
	input [1:0]  WB,
	output reg [70:0] MEM_WB);
  
  reg [70:0]  data;

 always@(negedge clk)
 begin
 	if(!rst_n)
 		data<=0;
 	else
 	begin
		data[33:2]<=readdata[31:0];
		data[65:34]<=result;
		data[70:66]<=write_reg[4:0];
		data[1:0]<=WB[1:0];
	end
 end
 always@(posedge clk)  
		MEM_WB<=data;

endmodule




module WB_mux(
 input [31:0] readdata
,input [31:0] aluresult
,input PCsrc
,output reg [31:0] PC);

always@(*)
begin
PC=PCsrc?readdata:aluresult;
end
endmodule