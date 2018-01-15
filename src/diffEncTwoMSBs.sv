////////////////////////////////////////////////////////////
//	Filename: diffEncTwoMSBs.v
//	Author: Liuchy@CUC
//	Rev: 1.0
//	Date: May 23, 2008
`timescale 1ns/1ns

module diffEncTwoMSBs
(
	iClk, iClrn, iData, iValid, iMode,
	oData, oValid
);
	parameter WIDTH=10;
	input iClk, iClrn;
	input[3:0] iMode;
	input[WIDTH-1:0] iData;
	input iValid;
	output[WIDTH-1:0] oData;
	output oValid;

	logic ik_leg, qk_leg;
	logic ak, bk, ik, qk;
	logic[WIDTH-1:0] oData;
	logic oValid;
	
	assign ak = iData[iMode-1];
	assign bk = iData[iMode-2];
	
	assign ik = (~(ak ^ bk) & (ak ^ ik_leg)) | ((ak ^ bk) & (ak ^ qk_leg));
	assign qk = (~(ak ^ bk) & (bk ^ qk_leg)) | ((ak ^ bk) & (bk ^ ik_leg));
	
	always_ff @(posedge iClk or negedge iClrn) begin
		if (!iClrn) begin
			oData <= #1 'b0;
			oValid <= #1 1'b0;
			ik_leg <= #1 1'b0;
			qk_leg <= #1 1'b0;
		end
		else begin
			if (iValid) begin
				ik_leg <= #1 ik;
				qk_leg <= #1 qk;
				oData <= #1 iData;
				oData[iMode-1] <= #1 ik;
				oData[iMode-2] <= #1 qk;
			end
			oValid <= #1 iValid;
		end
	end
	
endmodule
