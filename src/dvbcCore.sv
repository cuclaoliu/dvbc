//	filename: dvbcCore.sv
//	TS package Sync is omited for github.
//	by Liuchy@CUC

module dvbcCore(
	iClk, iClrn,
	iValid,
	iData,
	iPsync,
	iMode,
	iReq,
	oSymbol,
	oValid);
	
	localparam SYMBOLWIDTH = 10;
	input iClk;
	input iClrn;
	input iValid;
	input iPsync;
	input iReq;
	input[3:0] iMode;
	input[7:0] iData;
	output[7:0] oByte;
	output oByteValid;
	output[SYMBOLWIDTH-1:0] oSymbol;
	output oValid;
	
	logic ByteReq;
	logic Valid0, Valid1, Valid2, Valid3, Valid4, Valid5, Valid6;
	logic Check1, Check2;
	logic PSync1, PSync2, PSync3, PSync4;
	logic[7:0] Data0, Data1, Data2, Data3, Data4;
	logic[SYMBOLWIDTH-1:0] Symbol5, Symbol6;
	
	assign oSymbol = Symbol6;
	assign oValid = Valid6;
	
	byteSource byteSource_inst(
		.iClk(iClk), .iClrn(iClrn),
		.iData(iData), .iValid(iValid),
		.iReq(iReq), .iPsync(iPsync),
		.oData(Data1), .oValid(Valid1),
		.oPSync(PSync1),
		.oCheck(Check1)//, oFull, oEmpty
		);

	sync1InvertPRBS prbs_inst(
		.iClk(iClk), .iClrn(iClrn), .iCheck(Check1),
		.iValid(Valid1), .iData(Data1), .iPSync(PSync1),
		.oCheck(Check2),
		.oData(Data2), .oValid(Valid2), .oPSync(PSync2));
		
	rsenc rs_inst(
		.iClk(iClk), .iClrn(iClrn), .iCheck(Check2),
		.iData(Data2), .iValid(Valid2), .iPSync(PSync2),
		.oData(Data3), .oPSync(PSync3), .oValid(Valid3));
		
	interleavor interleaver_inst(
		.iClk(iClk), .iClrn(iClrn),
		.iData(Data3), .iValid(Valid3), .iPSync(PSync3),
		.oData(Data4), .oValid(Valid4), .oPSync(PSync4));
	
	byteToSymbol symbol_inst(
		.iClk(iClk), .iClrn(iClrn),
		.iMode(iMode), .iReq(iReq), 
		.iPSync(PSync4), .iValid(Valid4), .iData(Data4),
		.oValid(Valid5), .oData(Symbol5), .oReq(ByteReq));
		defparam symbol_inst.WIDTH = SYMBOLWIDTH;
		
	diffEncTwoMSBs diffenc_inst(
		.iClk(iClk), .iClrn(iClrn),
		.iMode(iMode),
		.iData(Symbol5), .iValid(Valid5),
		.oData(Symbol6), .oValid(Valid6));
		defparam diffenc_inst.WIDTH = SYMBOLWIDTH;
		
endmodule
