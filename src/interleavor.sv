//-------------------------------------------------------------------------
//	filename: interleavor.sv
//		copyrigh(c)
//--------------------------------------------------------------
//	This design realized a convolutional interlver with interleaver 
//		depth I = 12bytes. 11 cycle counter and 1 ram were used to 
//		realize the FIFO shift registers. It costs only 2 M9ks and 
//		few hundreds LCs at total.
//---------------------------------------------------------------------
//	Revision 	Date		Description		Edited		Author
//	1.0			3/25/2004	finished 		 			Liuchy@cuc
//	2.0			9/15/2013	systemverilog	 			Liuchy@cuc
`timescale 1ns/1ns

module interleavor
(
	iClk, iClrn,
	iData,
	iValid,
	iPSync,
	oData,
	oValid,
	oPSync
);

	input iClk, iClrn;
	input[7:0] iData;
	input iValid;
	input iPSync;
	output logic[7:0] oData;
	output logic oValid;
	output logic oPSync;
	
	localparam LENGTH = 17;
	localparam INTER_B = 12;
	localparam RAMBYTES = LENGTH*INTER_B*(INTER_B-1)/2;
	logic[7:0]dpram [RAMBYTES:0];
	logic[INTER_B-1:0] cntEn;
	logic[$clog2(RAMBYTES)-1:0] addrCnt[0:INTER_B-1];
	logic[$clog2(RAMBYTES)-1:0] addrr, addrw;
	logic[3:0] cnt;
	logic[7:0] ramq, DataR, DataW;
	logic ValidR, PSyncR, ValidW;
	int loop_v;

	initial begin
		for(loop_v=0;loop_v<=RAMBYTES;loop_v++)
			dpram[loop_v] = 8'd0;
	end
	
	assign addrCnt[0] = 'b0;
	genvar gen_var;
	generate 
		for(gen_var = 1; gen_var < INTER_B; gen_var = gen_var + 1) 
		begin : gen_counter
			cycleCounter  #($clog2(RAMBYTES), gen_var*(gen_var-1)*LENGTH/2+1,gen_var*(gen_var+1)*LENGTH/2)
				cnt_insts(iClk, iClrn, cntEn[gen_var]&iValid, addrCnt[gen_var]);
		end
	endgenerate
	
	always_ff@(posedge iClk or negedge iClrn) begin
		if(!iClrn) begin
			cnt <= #1 4'b0;
			cntEn <= #1 'b0;
		end
		else begin
			if(iPSync & iValid) begin
				cnt <= #1 4'd1;
				cntEn <= #1 'b1;
			end
			else if(iValid) begin
				if (cnt < INTER_B-1)
					cnt <= #1 cnt + 4'b1;
				else
					cnt <= #1 4'b0;
				cntEn <= #1 {cntEn[INTER_B-2:0], cntEn[11]};
			end
		end
	end

	assign addrr = addrCnt[cnt];
	
	always_ff@(posedge iClk) begin
		if(ValidW) begin
			dpram[addrw] <= #1 DataW;
		end
		addrw <= #1 addrr;
		ValidW <= #1 iValid;
		DataW <= #1 iData;
		ramq <= #1 dpram[addrr];
	end
	
	always_ff@(posedge iClk or negedge iClrn) begin
		if(!iClrn) begin
			oValid <= #1 1'b0;
			oData <= #1 8'b0;
			oPSync <= #1 1'b0;
			DataR <= #1 8'b0;
			ValidR <= #1 1'b0;
			PSyncR <= #1 1'b0;
		end
		else begin
			oValid <= #1 iValid;
			oPSync <= #1 iPSync;
			ValidR <= #1 iValid;
			PSyncR <= #1 iPSync;
			oValid <= #1 ValidR;
			oPSync <= #1 PSyncR;
			if(iValid) begin
				DataR <= #1 iData;
			end
			if(ValidR) begin
				oData <= #1 (cnt == 4'b1)?DataR:ramq;
			end
		end
	end
	
	//assign oData = (cnt == 4'b0)?DataR:ramq;
endmodule
