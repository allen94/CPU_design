/*********************************************************************************************
*                               Units in IF Stage and ID stage                               *
*                                       By   Hu Kai                                          *
**********************************************************************************************/ 


/*                             FILE INTRODUCTION
 *The codes in this file mainly describe the units in ID stage and IF stage.
 *All of the units are written in separate modules first. After they all have
 *passed the simulation test successfully, they are now listed together 
 *in the following IF_ID_test module as a whole to be linked with other stages.
 */


module IF_ID_test	(	clk,
				  		rst_n,
				  		exception_flush,
				  		exception_mux_control,
		                write_reg,
		                write_data,
		                alu_zero_out,
						beq_add,
						beq_out,
				  		regwrite_wb,
				 		ID_EX);


/*declaration of the input and output ports*/
input clk;                     //clock signal  
input rst_n;                   //reset signal
input				  		exception_flush;
input				  		exception_mux_control;
input [4:0] write_reg;         //the number of the register to be written in
input [31:0] write_data;       //the data to be written in the register
input alu_zero_out;            //signal for whether beq should jump to its dst-address  0:jump
input [31:0] beq_add; 
input beq_out;               
input regwrite_wb;
output [152:0] ID_EX;
reg [152:0] ID_EX;      //the ID_EX register

wire mux;
wire IFID_write;
wire PC_write;
wire id_mux_control;
wire [31:0] beq_mux_result;
wire [31:0] jump_mux_result;
wire [9:0]	ID_mux_result;

reg [10:0]Control;

assign id_mux_control=mux||Control[10]||exception_flush;

/***************************************************************
*                          IF Stage                            *
****************************************************************/   

/******************PC********************/
reg [31:0] PCout;

always@(*)
begin
	if(exception_flush)
		PCout=28*4;
	else
	if(PC_write==0) 
		PCout=jump_mux_result; //next_instruction_add;
end


/***********Instruction Cache************/
reg [63:0] IF_ID_temp;
integer num;
integer a,b,r;
reg [31:0] Instruction[0:31];

always@(*)
begin
	/*the following part is mainly for 
          converting the binary digits to decimal digits*/
	if(!rst_n) 
		begin
			for(r=0;r<32;r=r+1)
			Instruction[r]=32'b0;
		end

	b=1;
	num=0;
	for(a=2;a<32;a=a+1)
	begin
		num=num+PCout[a]*b;
		b=b*2;
	end
	
	IF_ID_temp[31:0]=Instruction[num];
	IF_ID_temp[63:32]=PCout+4;
end


/******************IF_ID********************/
reg [63:0] IF_ID_reg;
reg [63:0] IF_ID;

always@(negedge clk)
begin
	if(!rst_n)
		IF_ID_reg<=64'b0;
	else
	begin
		if(IFID_write==0||exception_flush)
			IF_ID_reg<=IF_ID_temp;
	end
end

always@(posedge clk)
	IF_ID<=IF_ID_reg;
	
/***************************************************************
*                          ID Stage                            *
****************************************************************/ 

/***************Sign_Extension*************/
//reg [152:0]ID_EX_temp;
reg [31:0]sign_extension;


always@(*)
begin
	sign_extension[15:0]=IF_ID[15:0];
	if(sign_extension[15]==0)
		sign_extension[31:16]=16'b0;
	if(sign_extension[15]==1)
		sign_extension[31:16]=16'b1111111111111111;
	//ID_EX_temp[105:74]=sign_extension;
end


/***************Control with mux***************/


/*The following is the definition of Control vector:
Control[0]=ALUSrc     //EX
Control[1]=ALUOp0
Control[2]=ALUOp1
Control[3]=RegDst
Control[4]=Branch     //MEM
Control[5]=MemWrite
Control[6]=MemRead
Control[7]=RegWrite   //WB
Control[8]=MemtoReg
Control[9]=Jump       //Jump
Control[10]=ID_Flush  //signal to clear the control signals in ID_EX register 1:clear
*/

wire addr_eq;

assign addr_eq=(beq_add==(IF_ID[63:32]-4));



always@(*)
begin
	case(IF_ID[31:26])

 	 	6'b000000 : Control[9:0]=10'b1010001100;//R-type instruction:add,sub,and,or,slt
  
	  	6'b100011 : Control[9:0]=10'b1111000001;//lw
	  
 	 	6'b101011 : Control[9:0]=10'b1000100001;//sw

 	 	6'b000100 : Control[9:0]=10'b1000010010;//beq

	  	6'b000010 : Control[9:0]=10'b0000000000;//jump
  
 	 	default: $display("invalid control signals");
 
 	endcase

	if(alu_zero_out&&beq_out&&(!addr_eq))        //PC+4 isn't the right addr
		begin	
			Control[10]=1'b1;
			Control[9]=1;
		end
	else 
		Control[10]=1'b0;//unnecessary to jump to the dst-address of beq

end

/***************Registers***************/
integer num1,num2,num3;
integer i,j,m,n,p,q;
reg [31:0] register[0:31]; //define the registers



/*the following three parts are mainly for 
  converting the binary digits to decimal digits*/
always@(*)
begin
	j=1;
	num1=0;
	for(i=21;i<26;i=i+1)
	begin
		num1=num1+IF_ID[i]*j;
		j=j*2;
	end
end

always@(*)
begin
	n=1;
	num2=0;
	for(m=16;m<21;m=m+1)
	begin
		num2=num2+IF_ID[m]*n;
		n=n*2;
	end	
end

always@(*)
begin
	q=1;
	num3=0;
	for(p=0;p<5;p=p+1)
	begin
		num3=num3+write_reg[p]*q;
		q=q*2;
	end
end

/*write data into the certain register 
  in the first half of the clock cycle*/

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		begin
			for(r=0;r<32;r=r+1)
			register[r]<=32'b0;
		end
end

always@(negedge clk)
begin
	if(regwrite_wb==1)//the register can be written in
		register[num3]<=write_data;
	/*if(regwrite_wb&&(num3==num1))
		begin
			ID_EX_temp[41:10]<=write_data;
			ID_EX_temp[73:42]<=register[num2];
			register[num3]<=write_data;
		end
	else 
		begin
			if(regwrite_wb&&(num3==num2))
			begin
				ID_EX_temp[41:10]<=register[num1];
				ID_EX_temp[73:42]<=write_data;
				register[num3]<=write_data;
			end		
			else
			begin
				ID_EX_temp[41:10]<=register[num1];
				ID_EX_temp[73:42]<=register[num2];
			end
		end	*/	
end

/*read data out from the certain registers
  in the second half of the clock cycle*/



/***************ID_others***************/
/*always@(*)
begin
	ID_EX_temp[120:106]=IF_ID[25:11];
	ID_EX_temp[152:121]=IF_ID[63:32];
	ID_EX_temp[9:0]=ID_mux_result;
end
*/	


/*****************ID_EX*****************/
reg [152:0] ID_EX_reg;

always@(negedge clk)
begin
	if(!rst_n)
		ID_EX_reg=0;
	else
	begin
		if(regwrite_wb&&(num3==num1))
			ID_EX_reg<={IF_ID[63:32],IF_ID[25:11],sign_extension,register[num2],write_data,ID_mux_result};
		else 
		begin
			if(regwrite_wb&&(num3==num2))
				ID_EX_reg<={IF_ID[63:32],IF_ID[25:11],sign_extension,write_data,register[num1],ID_mux_result};	
			else
				ID_EX_reg<={IF_ID[63:32],IF_ID[25:11],sign_extension,register[num2],register[num1],ID_mux_result};
		end	
	end
end

always@(posedge clk)
	ID_EX<=ID_EX_reg;


hazard_detector		hazard_detector	(	ID_EX[6],
  										ID_EX[115:111],
  										IF_ID[31:0],
  										mux,
  										IFID_write,
  										PC_write);


ID_mux				ID_mux			(	id_mux_control,
  										Control[9:0],
 										ID_mux_result);


beq_mux 			beq_mux 		(	IF_ID[63:32],//unbeq_add
  										beq_add,
  										Control[10],
										beq_mux_result);


jump_mux 			jump_mux 		(	IF_ID[31:0],
  										beq_mux_result,
										Control[9],
										jump_mux_result);

/*exception_mux 			exception_mux 	(jump_mux_result,
										exception_mux_control,
										next_instruction_add);
/***************************************************************
*                       That's the end                         *
****************************************************************/ 
endmodule






module hazard_detector(input IDEX_memread
  ,input [4:0] IDEX_register_rt
  ,input [31:0]  IFID_register
  ,output mux
  ,output IFID_write
  ,output PC_write);
  
wire [4:0] rs;
wire [4:0] rt;

assign rs=IFID_register[25:21];
assign rt=IFID_register[20:16];

assign PC_write=(IDEX_memread&&((IDEX_register_rt==rs)||(IDEX_register_rt==rt)));
assign IFID_write=(IDEX_memread&&((IDEX_register_rt==rs)||(IDEX_register_rt==rt)));
assign mux=(IDEX_memread&&((IDEX_register_rt==rs)||(IDEX_register_rt==rt)));

endmodule 



module ID_mux(input mux
  ,input [9:0] control
  ,output reg [9:0] ID_mux_result);
always@(*)
begin
  ID_mux_result=mux?0:control;
end
endmodule



module beq_mux(input [31:0] unbeq_add
  ,input [31:0] beq_add
  ,input control_beq_mux
,output reg [31:0] beq_mux_result);
  
always@(*)
  
case (control_beq_mux)
  
  1'd1 : beq_mux_result = beq_add;
  
  1'd0 : beq_mux_result = unbeq_add;
  
  default: $display("invalid control signals");
 
 endcase

endmodule



module jump_mux(input [31:0] IF_ID_temp
  ,input [31:0] IF_addresult
,input jump
,output reg [31:0] jump_mux_result);
  
wire [31:0] tmp;

 assign tmp[31:28] = IF_addresult[31:28];
 assign tmp[27:2]  = IF_ID_temp[25:0]; 
 assign tmp[1:0]  = 0;
 
always@(*)
  begin
  jump_mux_result = jump?IF_addresult:tmp;
 end

endmodule


module 	exception_mux 	(jump_mux_result,
						exception_mux_control,
						next_instruction_add);

output	reg	[31:0]		next_instruction_add;
input					exception_mux_control;
input		[31:0]		jump_mux_result;

always@(*)
  
case (exception_mux_control)
  
  1'd1 : next_instruction_add = 28;
  
  1'd0 : next_instruction_add = jump_mux_result;
  
  default: $display("invalid control signals");
 
 endcase

endmodule