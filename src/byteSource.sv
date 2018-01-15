//	Filename:	byteSource.sv
//	Descript:
//	By Liuchy@CUC
//	Sep 16, 2013
//	Rev 3.1
`timescale 1ns/1ns
module byteSource
(
	iClk, iClrn,
	iData,
	iValid,
	iReq,
	iPsync,
	oData, oPSync, oValid,
	oCheck, oFull, oEmpty
);
// Port Declaration

	output logic[7:0] oData;
	output logic oPSync;
	output logic oValid;
	output logic oCheck;
	output logic oFull;
	output logic oEmpty;
	input iValid;
	input iClrn;
	input iReq;
	input iPsync;
	input [7:0] iData;
	input iClk;
	
	localparam BUFFERBYTES = 1024;
	localparam ADDRWIDTH = $clog2(BUFFERBYTES);
	logic[7:0] dpram[0:BUFFERBYTES-1];
	logic[ADDRWIDTH-1:0] addrr, addrw;
	logic tspack = 1'b0;//sending = 'b0, 
	byte unsigned sendcnt = 8'd0;
	//byte unsigned packbytes = 8'd188; // 188 or 204
	logic signed [ADDRWIDTH:0] usefulbytes = 'd0;
	logic rd;
	logic[7:0] rdData, nullPackData;
	
	assign #1 oCheck = (sendcnt > 187);
	
	initial begin
		for(int loop_v=0; loop_v<BUFFERBYTES; loop_v++)
			dpram[loop_v] <= 8'd0;
	end
	
	always_ff @(posedge iClk) begin
		if(iValid)
			dpram[addrw] <= #1 iData;
		rdData <= #1 dpram[addrr];
	end
	
	always_ff @(posedge iClk or negedge iClrn) begin
		if(!iClrn) begin
			addrr <= #1 'd0;
			addrw <= #1 'd0;
			usefulbytes <= #1 'd0;
			oFull <= #1 1'b0;
			oEmpty <= #1 1'b0;
		end
		else begin
			if(iValid) begin
				if(addrw < BUFFERBYTES-1)
					addrw <= #1 addrw + 1'd1;
				else
					addrw <= #1 'd0;
			end
			if(rd) begin
				if(addrr < BUFFERBYTES-1)
					addrr <= #1 addrr + 1'd1;
				else
					addrr <= #1 1'd0;
			end
			if({iValid, rd} == 2'b10) begin
				if(usefulbytes == BUFFERBYTES)
					oFull <= #1 1'b1;
				usefulbytes <= #1 usefulbytes + 1;
			end
			else if({iValid, rd} == 2'b01) begin
				if(usefulbytes == 0)
					oEmpty <= #1 1'b1;
				usefulbytes <= #1 usefulbytes - 1;
			end
		end
	end
	
	always_ff @(posedge iClk or negedge iClrn) begin
		if(!iClrn) begin
			sendcnt <= #1 'd0;
			tspack <= #1 1'b0;
			//oCheck <= #1 1'b0;
		end
		else begin
			if (iReq) begin
				if(sendcnt < 203) begin
					sendcnt <= #1 sendcnt + 8'd1;
					if(sendcnt == 187 && tspack)
						tspack <= #1 iPsync;
					//oCheck <= #1 1'b1;
				end
				else begin
					sendcnt <= #1 8'd0;
					//oCheck <= #1 1'b1;
					if(usefulbytes >= 204)
						tspack <= #1 1'b1;
					else
						tspack <= #1 1'b0;
				end
			end
		end
	end
	
	always_ff @(posedge iClk or negedge iClrn) begin
		if(!iClrn) begin
			oValid <= #1 1'b0;
			oData <= #1 8'd0;
			oPSync <= #1 1'b0;
		end
		else begin
			oValid <= #1 iReq;
			if (tspack)
				oData <= #1 rdData;
			else
				oData <= #1 nullPackData;
			if (sendcnt == 8'd0)
				oPSync <= #1 1'b1;
			else
				oPSync <= #1 1'b0;
		end
	end
	
	always_comb begin
		case(sendcnt)
			8'd0 : nullPackData <= 8'h47;
			8'd1 : nullPackData <= 8'h1F;
			8'd2 : nullPackData <= 8'hFF;
			8'd3 : nullPackData <= 8'h10;
			default: nullPackData <= 8'hFF;
		endcase
	end
	
	assign #1 rd = tspack & iReq;
	
	endmodule
