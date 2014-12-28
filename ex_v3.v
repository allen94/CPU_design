//version:1.0
//date:2014-12-27
//author:qiaobo 5122119019


module ex (	clk,    // Clock
			rst_n,  // Asynchronous reset active low
			id_ex_instuct_add,
			id_ex_control_wb,
			id_ex_control_mem,
			id_ex_control_ex,
			funct_field,//sign后六位			
			rs_data,
			rt_data,
			sign,
			rt_add,
			rd_add,
			rs_add,
			mem_wb_rd,
			mem_wb_rd_data,
			mem_wb_regwrite,
			control_wb_out,
			control_mem_out,
			result_out,
			datamem_data_out,
			wb_add_out,
			alu_zero_out_mem,
			alu_zero_out_id,
			beq_out,
			beq_add,
			flush,
			exception_mux_control
			);

input					clk,rst_n;
input		[31:0]		id_ex_instuct_add;
input		[1:0]		id_ex_control_wb;//0 for regwrite, 1 for mux
input		[2:0]		id_ex_control_mem;//0 for datawrite, 1 for dataread, 2 for the other
input		[5:0]		funct_field;	//
input		[3:0]		id_ex_control_ex;							//control_ex
input		[31:0]		rs_data;
input		[31:0]		rt_data;
input		[31:0]		sign;
input		[31:0]		mem_wb_rd_data;
input		[4:0]		rt_add;
input		[4:0]		rd_add;
input		[4:0]		rs_add;
input		[4:0]		mem_wb_rd;
input					mem_wb_regwrite;

output 					alu_zero_out_mem;
output					alu_zero_out_id;
output		[31:0]		beq_add;
output					beq_out;
output 		[1:0] 		control_wb_out;
output 		[2:0] 		control_mem_out;
output 		[31:0]		result_out;
output 		[31:0]		datamem_data_out;
output 		[4:0] 		wb_add_out;
output					flush;
output					exception_mux_control;

wire		[4:0]		ex_mem_rd;
wire 		[31:0]		operate1;
wire 		[31:0]		operate2;
wire 		[31:0]		alusrc1;
wire 		[31:0]		alusrc2;
wire 		[31:0]		sign_out;
wire		[1:0]		forward_a;
wire		[1:0]		forward_b;
wire  		[4:0]		write_add;
wire 		[31:0]		result;
wire					brk_out;
wire		[3:0]		operation;
wire					ex_mem_regwrite;
wire		[1:0]		ex_mem_control_wb;
wire		[2:0]		ex_mem_control_mem;
wire					ex_flush;

assign ex_flush=flush;
assign ex_mem_regwrite=control_wb_out[0];
assign ex_mem_rd=wb_add_out;
assign alu_zero_out_id=brk_out;
assign beq_out=id_ex_control_mem[0];
assign beq_add=(id_ex_instuct_add+{sign[29:0],2'b0});


mux_a 	muxa 	(	alusrc1,
					result_out,
					mem_wb_rd_data,
					rs_data,
					forward_a);

mux_b 	muxb 	(	alusrc2,
					result_out,
					mem_wb_rd_data,
					rt_data,
					forward_b);

mux_c 	muxc 	(	write_add,
					rt_add,
					rd_add,
					id_ex_control_ex[3]);

alusrc 	alusrcx	(	operate2,
					alusrc2,
					sign,
					id_ex_control_ex[0]);

alusrc 	buffer1	(	operate1,
					alusrc1,
					alusrc1,
					id_ex_control_ex[0]);

alusrc 	buffer2	(	sign_out,
					sign,
					sign,
					forward_b[0]);
	
alu 	alux 	(	operate2,
					operate1,
					operation,
					result,
					brk_out);

alucontrol alu_c(	funct_field,	
					id_ex_control_ex[2:1],
					operation);

forwarding forwd(	rs_add, 
					rt_add, 
					ex_mem_rd, 
					mem_wb_rd,
					mem_wb_regwrite,
					ex_mem_regwrite,
					forward_a,
					forward_b);

mux_flush_wb muxfw(	ex_mem_control_wb,
					id_ex_control_wb,
					ex_flush);

mux_flush_mem muxfm(ex_mem_control_mem,
					id_ex_control_mem,
					ex_flush);

exception exception(rst_n,  // Asynchronous reset active low
					result,
					id_ex_control_mem,
					id_ex_instuct_add,
					flush,
					exception_mux_control
);

ex_mem 		ex_memx(clk,
					rst_n,
					ex_mem_control_wb,
					ex_mem_control_mem,
					result,
					alusrc2,
					write_add,
					brk_out,
					control_wb_out,
					control_mem_out,
					result_out,
					datamem_data_out,
					wb_add_out,
					alu_zero_out_mem);

endmodule






module exception (	rst_n,  // Asynchronous reset active low
					result,
					control_mem,
					id_ex_instuct_add,
					flush,
					exception_mux_control
);
input					rst_n;  // Asynchronous reset active low
input		[31:0]		result;
input		[2:0]		control_mem;
input		[31:0]		id_ex_instuct_add;
output		reg			flush;
output		reg			exception_mux_control;

reg		[31:0]		exception_add;

always	@(*)
if(!rst_n)
	begin
		exception_add<=32'b0;
		flush<=0;
		exception_mux_control<=0;
	end

else
	begin
		if((control_mem[1]||control_mem[2])&&(result>63))
		begin
			flush<=1;
			exception_mux_control<=1;
			exception_add<=id_ex_instuct_add;
		end
		else
		begin
			flush<=0;
			exception_mux_control<=0;
		end
	end
endmodule




module forwarding (	id_ex_rs, 
					id_ex_rt, 
					ex_mem_rd, 
					mem_wb_rd,
					mem_wb_regwrite,
					ex_mem_regwrite,
					forwarda,
					forwardb);
 
    input 	[4:0] 		id_ex_rt,id_ex_rs,ex_mem_rd,mem_wb_rd;
    input  				mem_wb_regwrite,ex_mem_regwrite;

	output 	[1:0]		forwarda;
	output 	[1:0]		forwardb;

    reg 	[1:0] 		forwardb,forwarda;

always @(*)
	begin
		if((ex_mem_rd==id_ex_rs)&&(ex_mem_rd!=0)&&(ex_mem_regwrite)) 
			forwarda=2'b10;
		else
		begin
			if((mem_wb_rd==id_ex_rs)&&(mem_wb_rd!=0)&&(mem_wb_regwrite)) 
			begin
				forwarda=2'b01;
			end
			else forwarda=2'b00;
		end

		if((ex_mem_rd==id_ex_rt)&&(ex_mem_rd!=0)&&(ex_mem_regwrite)) 
			forwardb=2'b10;
		else
		begin
			if((mem_wb_rd==id_ex_rt)&&(mem_wb_rd!=0)&&(mem_wb_regwrite)) 
			begin
				forwardb=2'b01;
			end
			else forwardb=2'b00;
		end
	end

endmodule



module mux_flush_wb (	ex_mem_control_wb,
						id_ex_control_wb,
						ex_flush);
  
  input 	[1:0]		id_ex_control_wb;
  input 				ex_flush;

  output	[1:0] 		ex_mem_control_wb;

  reg 		[1:0] 		ex_mem_control_wb;
  
always @(*)
  
case (ex_flush)
  
  1'd0 : ex_mem_control_wb = id_ex_control_wb;
  
  1'd1 : ex_mem_control_wb = 0;
  
  default: $display("invalid control signals");
 
 endcase
 
endmodule




module mux_flush_mem (ex_mem_control_mem,
						id_ex_control_mem,
						ex_flush);
  
  input 	[2:0]		id_ex_control_mem;
  input 				ex_flush;

  output	[2:0] 		ex_mem_control_mem;

  reg 		[2:0] 		ex_mem_control_mem;
  
always @(*)
  
case (ex_flush)
  
  1'd0 : ex_mem_control_mem = id_ex_control_mem;
  
  1'd1 : ex_mem_control_mem = 0;
  
  default: $display("invalid control signals");
 
 endcase
 
endmodule







module mux_a (	operate1,
				ex_mem_register_rd,
				mem_wb_register_rd,
				rt_data,
				forward_a);
  
  input 	[1:0]		forward_a; 

  output	[31:0] 		operate1;
  input		[31:0]		ex_mem_register_rd,mem_wb_register_rd,rt_data;

  reg 		[31:0] 		operate1;
  
always @(*)
  
case (forward_a)
  
  2'd2 : operate1 = ex_mem_register_rd;
  
  2'd1 : operate1 = mem_wb_register_rd;
  
  2'd0 : operate1 = rt_data;
  
  default: $display("invalid control signals");
 
 endcase
 
endmodule




module mux_b (	alusrc_1,
				ex_mem_register_rd,
				mem_wb_register_rd,
				rs_data,
				forward_b);

  input 	[31:0]		ex_mem_register_rd,mem_wb_register_rd,rs_data;
  input 	[1:0]		forward_b; 

  output	[31:0] 		alusrc_1;

  reg 		[31:0] 		alusrc_1;
  
always @(*)
  
case (forward_b)
  
  2'd2 : alusrc_1 = ex_mem_register_rd;
  
  2'd1 : alusrc_1 = mem_wb_register_rd;
  
  2'd0 : alusrc_1 = rs_data;
  
  default: $display("invalid control signals");
 
 endcase
 
endmodule




module alusrc (	operate2,
				alusrc1,
				sign,
				alusrc_control);
  
  input 	[31:0]		alusrc1,sign;
  input 				alusrc_control;

  output	[31:0] 		operate2;

  reg 		[31:0] 		operate2;
  
always @(*)
  
case (alusrc_control)
  
  1'd0 : operate2 = alusrc1;
  
  1'd1 : operate2 = sign;
  
  default: $display("invalid control signals");
 
 endcase
 
endmodule





module mux_c (	write_add,
				rt_add,
				rd_add,
				regdst);
  
  input 	[4:0]		rt_add,rd_add;
  input 				regdst;

  output	[4:0] 		write_add;

  reg 		[4:0] 		write_add;
  
always @(*)
  
case (regdst)
  
  1'd0 : write_add = rt_add;
  
  1'd1 : write_add = rd_add;
  
  default: $display("invalid control signals");
 
 endcase
 
endmodule




module alu (operate2,
			operate1,
			operation,
			result,
			brk_out);

  input 	[31:0]		operate1,operate2;
  input 	[3:0]		operation; 

  output	[31:0] 		result;
  output 				brk_out;

  reg 		[31:0] 		result;

  assign brk_out=(result==0);
  
always @(*)
  
case (operation)
  
  0 : result = operate1 & operate2;
  
  1 : result = operate1 | operate2;
  
  2 : result = operate1 + operate2;

  6 : result = operate1 - operate2;

  7 : result = operate1 < operate2;

  12 : result = operate1 ^ operate2;

  default: result = 0;
 
 endcase
 
endmodule





module alucontrol (	funct_field,	
					aluop,
					operation);

  input 		[1:0]		aluop;
  input			[5:0]		funct_field;
	
  output 		[3:0]		operation;
	
  reg 			[3:0]		operation;

always @(*)
  
casex ({aluop,funct_field})
  
  8'b00xxxxxx : operation = 4'b0010;
  
  8'bx1xxxxxx : operation = 4'b0110;
  
  8'b1xxx0000 : operation = 4'b0010;

  8'b1xxx0010 : operation = 4'b0110;

  8'b1xxx0100 : operation = 4'b0000;

  8'b1xxx0101 : operation = 4'b0001;

  8'b1xxx1010 : operation = 4'b0111;

  default: operation = 4'b0000;
 
 endcase
 
endmodule




module ex_mem (	clk,
				rst_n,
				control_wb_in,
				control_mem_in,
				result_in,
				datamem_data_in,
				wb_add_in,
				alu_zero_in,
				control_wb_out,
				control_mem_out,
				result_out,
				datamem_data_out,
				wb_add_out,
				alu_zero_out_mem);

input 					clk,rst_n,alu_zero_in;
input 		[1:0] 		control_wb_in;
input 		[2:0] 		control_mem_in;
input 		[31:0] 		result_in;
input 		[31:0] 		datamem_data_in;
input 		[4:0] 		wb_add_in;

output 					alu_zero_out_mem;
output 		[1:0] 		control_wb_out;
output 		[2:0] 		control_mem_out;
output 		[31:0]		result_out;
output 		[31:0]		datamem_data_out;
output 		[4:0] 		wb_add_out;

reg 					alu_zero_out_mem;
reg 		[1:0] 		control_wb_out;
reg 		[2:0] 		control_mem_out;
reg 		[31:0]		result_out;
reg 		[31:0]		datamem_data_out;
reg 		[4:0] 		wb_add_out;
reg 		[75:0]		temp;

always@(negedge clk)
	begin
		if(!rst_n)
			temp<=0;
		else
			temp<={control_wb_in,control_mem_in,datamem_data_in,alu_zero_in,result_in,wb_add_in};
	end

always@(posedge clk)
	{control_wb_out,control_mem_out,datamem_data_out,alu_zero_out_mem,result_out,wb_add_out}<=temp;

endmodule