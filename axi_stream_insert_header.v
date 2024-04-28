`timescale 1ns / 1ps

module axi_stream_insert_header 
#(
	parameter 		DATA_WD = 32,
	parameter 		DATA_BYTE_WD = DATA_WD / 8,
	parameter 		BYTE_CNT_WD = $clog2(DATA_BYTE_WD)
)(
	input 			clk,
	input 			rst_n,
	// AXI Stream input original data
	input 							valid_in,
	input 	[DATA_WD-1 : 0] 				data_in,
	input 	[DATA_BYTE_WD-1 : 0] 				keep_in,
	input 							last_in,
	output 							ready_in,
	// AXI Stream output with header inserted
	output 							valid_out,
	output 	[DATA_WD-1 : 0] 				data_out,
	output 	[DATA_BYTE_WD-1 : 0] 				keep_out,
	output 							last_out,
	input 							ready_out,
	// The header to be inserted to AXI Stream input
	input 							valid_insert,
	input 	[DATA_WD-1 : 0] 				data_insert,
	input 	[DATA_BYTE_WD-1 : 0] 				keep_insert,
	input	[BYTE_CNT_WD-1 : 0]				byte_insert_cnt,
	output 							ready_insert
);



/****************************************************/
//计算二进制位宽
function integer clog2(input integer number);
begin
	for(clog2 = 0 ; number > 0 ; clog2 = clog2 + 1)
		number = number << 1;
end
endfunction

/************************参数*************************/


/***********************网表型*************************/
wire 	insert_flag;
wire p_last_in_pulse;
wire	w_in_active;
wire	w_out_active;

/***********************寄存器*************************/
reg						cnt;
reg						r_ready_insert;
reg	[DATA_WD-1:0]		r_header_data_out;
reg	[DATA_BYTE_WD-1:0]	r_keep_insert;
reg	[DATA_WD-1:0]		r_data_out1;
reg	[DATA_WD-1:0]		r_data_out2;
reg						r_last_in1;
reg						r_last_in2;
reg [DATA_WD-1:0]		r_keep_in;
reg	[1:0]				r_last_out_flag;
reg	[DATA_WD-1:0]		r_keep_out;

/**********************组合逻辑*************************/
assign ready_insert = r_ready_insert;
assign insert_flag = valid_insert && ready_insert;
assign data_out = (valid_out && ready_out)?r_header_data_out:r_data_out2;
assign keep_out = r_keep_out;
assign	w_in_active = valid_in && ready_in;
assign	w_out_active = valid_out &&ready_out;

/************************例化*************************/


/*insert*/
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		r_ready_insert <= 'd0;
	else if(insert_flag)
		r_ready_insert <= 'd0;
	else
		r_ready_insert <= 'd1;
end



always@(posedge  clk or negedge rst_n)begin
	if(!rst_n)
		r_keep_insert <= 0;
	else if(insert_flag)
		r_keep_insert <= keep_insert;
	else
		r_keep_insert <= r_keep_insert;
end


/*in*/
always@(posedge  clk or negedge rst_n)begin
	if(!rst_n)begin
		r_data_out1 <= 'd0;
		r_data_out2 <= 'd0;
	end
	else if(w_in_active)begin
		r_data_out1 <= data_in;
		r_data_out2 <= r_data_out1;
	end
	else begin
		r_data_out1 <= r_data_out1;
		r_data_out2 <= r_data_out2;
	end
end


always@(posedge  clk or negedge rst_n)begin
	if(!rst_n)
		r_keep_in <= 0;
	else if(last_in)
		r_keep_in <= keep_in;
	else
		r_keep_in <= r_keep_in;
end



//采集last_in信号下降沿
always@(posedge  clk or negedge rst_n)begin
	if(!rst_n)begin
		r_last_in1 <= 'd0;
		r_last_in2 <= 'd0;
	end
	else begin
		r_last_in1 <= last_in;
		r_last_in2 <= r_last_in2;
	end
end
assign p_last_in_pulse = ~r_last_in1 && r_last_in2;
assign ready_in = ~p_last_in_pulse;


/*out*/
/**header插入到data******/
always@(posedge  clk or negedge rst_n)begin
	if(!rst_n)
		r_header_data_out <= 0;
	else if(insert_flag)
		case(keep_insert)
			4'b1111:r_header_data_out <= data_insert;
			4'b0111:r_header_data_out <= {data_insert[23:0],r_data_out1[31:24]};
			4'b0011:r_header_data_out <= {data_insert[15:0],r_data_out1[31:16]};
			4'b0001:r_header_data_out <= {data_insert[7:0],r_data_out1[31:8]};
		default:r_header_data_out <= r_header_data_out;
		endcase
	else
		case(r_keep_insert)
			4'b1111:r_header_data_out <= r_data_out2;
			4'b0111:r_header_data_out <= {r_data_out2[23:0],r_data_out1[31:24]};
			4'b0011:r_header_data_out <= {r_data_out2[15:0],r_data_out1[31:16]};
			4'b0001:r_header_data_out <= {r_data_out2[7:0],r_data_out1[31:8]};
		default:r_header_data_out <= r_data_out2;
		endcase
end



always@(posedge  clk or negedge rst_n)begin
	if(!rst_n)
		r_last_out_flag <= 2'b0;
	else
		r_last_out_flag <= {r_last_out_flag[0],p_last_in_pulse};
end
assign last_out = ~r_last_out_flag[0] & r_last_out_flag[1];



always@(posedge  clk or negedge rst_n)begin
	if(!rst_n)
		r_keep_out <= 0;
	else if(last_out)
		case(r_keep_insert)
			4'b1111:r_keep_out <= r_keep_in;
			4'b0111:r_keep_out <= r_keep_in << 1;
			4'b0011:r_keep_out <= r_keep_in << 2;
			4'b0001:r_keep_out <= r_keep_in << 3;
		endcase
	else if(valid_out)
		r_keep_out <= 4'b1111;
end


//判断valid_out
//reg [1:0]insert_flag_r;
//always@(posedge clk or negedge rst_n)begin
//    if(!rst_n)
//        insert_flag_r<=0;
//    else
//        insert_flag_r <= {insert_flag_r[0],insert_flag};
//end
//assign valid_out = ~(~insert_flag_r[1]&insert_flag_r[0]);
assign valid_out = 'd1;

endmodule














