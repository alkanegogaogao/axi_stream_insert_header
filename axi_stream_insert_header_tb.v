`timescale 1ns / 1ps

module axi_stream_insert_header_tb();

parameter DATA_DEPTH =256;
parameter DATA_WD = 32;
parameter DATA_BYTE_WD = DATA_WD / 8;
parameter DATA_CNT=DATA_DEPTH/DATA_WD;
parameter BYTE_CNT_WD = $clog2(DATA_BYTE_WD);

reg 						clk;
reg 						rst_n;
// AXI Stream input original data
reg valid_in;
reg [DATA_WD-1 : 0] 		data_in;
reg [DATA_BYTE_WD-1 : 0] 	keep_in;
reg 						last_in;
wire 						ready_in;
// AXI Stream output with header inserted
wire 						valid_out;
wire [DATA_WD-1 : 0] 		data_out;
wire [DATA_BYTE_WD-1 : 0] 	keep_out;
wire 						last_out;
reg 						ready_out;
// The header to be inserted to AXI Stream input
reg 						valid_insert;
reg [DATA_WD-1 : 0] 		data_insert;
reg [DATA_BYTE_WD-1 : 0] 	keep_insert;
reg	[BYTE_CNT_WD-1 : 0]		byte_insert_cnt;
wire 						ready_insert;
reg [3:0]					cnt;

initial begin
	clk=0;
	rst_n=0;
	valid_in=1;
	last_in=0;
	keep_in=4'b1111;
	ready_out=1;
	valid_insert=0;
	byte_insert_cnt=0;
	#20
	rst_n=1;
end

always #10 clk=!clk;


reg [3:0]rand_interval;
always@(posedge clk)begin
     rand_interval = $random % 10+6;
     repeat (rand_interval) @(posedge clk);
     valid_in<=0;
     repeat (1) @(posedge clk);
     valid_in<=1;
end


reg [3:0]interval;
always@(posedge clk)begin
     interval = $random % 10+6;
     repeat (interval) @(posedge clk);
     ready_out<=0;
     repeat (1) @(posedge clk);
     ready_out<=1;
end


always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        data_in<=0;
    else if(valid_in && ready_in)
        data_in<={$random}%2**(DATA_WD-1)-1;    
end


always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        cnt<=0;
    else 
        cnt<=cnt==10? 0:cnt+1;
end
   

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        data_insert={$random}%2**(DATA_WD-1)-1;
    else if(cnt==7)
            valid_insert=1;

    else    if(cnt==9)
    begin

        data_insert<={$random}%2**(DATA_WD-1)-1;
        valid_insert<=0;
    end
end

   
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        last_in=0;
    else if(cnt==8)
        last_in=1;
    else
        last_in=0;
end

reg [2:0]num;
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
    begin
        keep_insert<=0;
    end
    else
    begin
        num ={$random}%4;
        if(num == 'd0)
            keep_insert<=4'b1111;
        else if(num == 'd1)
            keep_insert<=4'b0111;   
        else if(num == 'd2)
            keep_insert<=4'b0011;         
        else
            keep_insert<=4'b0001;
    end
end


/****************************************************/
//计算二进制位宽
function integer clog2(input integer number);
begin
	for(clog2 = 0 ; number > 0 ; clog2 = clog2 + 1)
		number = number << 1;
end
endfunction


axi_stream_insert_header
#(
	.DATA_WD 				(DATA_WD		),
	.DATA_BYTE_WD 			(DATA_BYTE_WD	),
	.BYTE_CNT_WD 			(BYTE_CNT_WD	)
)
axi_stream_insert_header_inst(
	.clk					(clk			),
	.rst_n					(rst_n			),
	.valid_in				(valid_in		),
	.data_in				(data_in		),
	.keep_in				(keep_in		),
	.last_in				(last_in		),
	.ready_in				(ready_in		),
	.valid_out				(valid_out		),
	.data_out				(data_out		),
	.keep_out				(keep_out		),
	.last_out				(last_out		),
	.ready_out				(ready_out		),
	.valid_insert			(valid_insert	),
	.data_insert			(data_insert	),
	.keep_insert			(keep_insert	),
	.byte_insert_cnt		(byte_insert_cnt),
	.ready_insert			(ready_insert	)
);


endmodule




