//version:1.0
//date:2014-12-13
//author:qiaobo 5122119019

module top (clk,
			rst_n);

input 					clk,rst_n;

wire 		[4:0] 		write_reg;//写寄存器号
wire 		[31:0] 		write_data;//写寄存器数据

wire		[4:0]		mem_wb_rd;//wire from MEM
wire		[31:0]		mem_wb_rd_data;
wire					mem_wb_regwrite;

wire 					alu_zero_out;
wire 		[1:0] 		control_wb_out;
wire 		[2:0] 		control_mem_out;
wire 		[31:0]		result_out;
wire 		[31:0]		datamem_data_out;
wire 		[4:0] 		wb_add_out;


wire		[152:0] 	ID_EX;//
wire 		[70:0]		MEM_WB;
	
wire 		[31:0] 		wb_data;
wire 					regwrite_wb;
wire 		[4:0] 		wb_add1;
wire  					alu_zero_out_mem;
wire 					alu_zero_out_id;
wire 		[31:0]		beq_add;
wire 					beq_out;
wire 					flush;
wire 					exception_mux_control;


IF_ID_test		IF_ID 	(	clk,
							rst_n,
							flush,
				  			exception_mux_control,
							wb_add1,
							wb_data,
							alu_zero_out_id,
							beq_add,
							beq_out,
							regwrite_wb,
							ID_EX);


ex 	ex 	(	clk,    // Clock
			rst_n,  // Asynchronous reset active low
			ID_EX[152:121],
			ID_EX[8:7],
			ID_EX[6:4],
			ID_EX[3:0],
			ID_EX[79:74],//sign后六位
			ID_EX[41:10],
			ID_EX[73:42],
			ID_EX[105:74],
			ID_EX[115:111],
			ID_EX[110:106],
			ID_EX[120:116],
			wb_add1,
			wb_data,
			regwrite_wb,
			//ex_flush,
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


wb 	wb 	( 	alu_zero_out_mem,
 			clk,
			rst_n,
			control_wb_out,
			control_mem_out,
			result_out,
			datamem_data_out,
			wb_add_out,
			wb_data,
			regwrite_wb,
			wb_add1);


endmodule
