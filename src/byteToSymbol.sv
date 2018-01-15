`timescale 1ns/1ns
module byteToSymbol(
	iClk,
	iClrn,
	iMode,
	iReq,
	iPSync,
	iValid,
	iData,
	oValid,
	oData,
	oReq
);

	parameter WIDTH = 10;
	input iClk;
	input iClrn;
	input[3:0] iMode;
	input iReq;
	input iPSync;
	input iValid;
	input[7:0] iData;
	output logic oValid;
	output logic oReq;
	output logic [WIDTH-1:0] oData;
	
	logic [WIDTH-1:0] RegOut;
	logic [7:0] RegIn;
	
	byte unsigned packs;
	logic reqed;
	byte unsigned BitsCntIn, BitsCntOut;

	always_ff@(posedge iClk or negedge iClrn) begin
		if(!iClrn) begin
			RegIn <= #1 8'd0;
			RegOut <= #1 'b0;
			BitsCntIn <= #1 0;
			BitsCntOut <= #1 0;
			oReq <= #1 1'b0;
			reqed <= #1 1'b0;
			oData <= #1 'b0;
			oValid <= #1 1'b0;
		end
		else begin
			if ((BitsCntIn > 0) && (BitsCntOut < iMode)) begin
				RegOut <= #1 {RegOut[WIDTH-2:0], RegIn[7]};
				RegIn <= #1 {RegIn[6:0], 1'b0};
				BitsCntIn <= #1 BitsCntIn - 1;
				BitsCntOut <= #1 BitsCntOut + 1;
			end
			if(BitsCntIn == 0) begin
				if(!reqed) begin
					oReq <= #1 1'b1;
					reqed <= #1 1'b1;
				end
				else
					oReq <= #1 1'b0;
			end
			if(BitsCntOut == iMode) begin
				if(iReq) begin
					oData <= #1 RegOut;
					RegOut <= #1 'b0;
					oValid <= #1 1'b1;
					BitsCntOut <= #1 0;
				end
				else 
					oValid <= #1 1'b0;
			end
			else
				oValid <= #1 1'b0;
			if(iValid) begin
				RegIn <= #1 iData;
				BitsCntIn <= #1 8;
				reqed <= #1 1'b0;
			end
		end
	end

endmodule	//end of byteToSymbol