////////////////////////////////////////////////////////////
//	Filename: sync1invert_prbs.sv
//
//		copyright(c)
//	Sync1invert_prbs Design:
//		The System input stream shall be organized in fixed length packets, 
//		following the MPEG-2 transport multiplexer. The total packet length 
//		of the MPEG-2 transport MUX packet is 188 bytes. This includes 1 
//		sync-word byte (i.e. 47HEX). The processing order at the transmitting 
//		side shall always start from the MSB (i.e. 0) of the sync word-byte
//		(i.e. 01000111). Loading of the sequence "100101010000000" into the 
//		PRBS registers, shall be initiated at the start of every eight transport 
//		packets. To provide an initialization signal for the descrambler, 
//		the MPEG-2 sync byte of the first transport packet in a group of 
//		eight packets shall be bitwise inverted from 47HEX to B8HEX. The first 
//		bit at the output of the PRBS generator shall be applied to the first
//		bit of the first byte following the inverted MPEG-2 sync byte (i.e.B8HEX).
//		To aid other synchronization functions, during the MPEG-2 sync bytes 
//		of the subsequent 7 transport packets, the PRBS generation continues, 
//		but its output shall be disabled, leaving these bytes unrandomized. 
//		The period of the PRBS sequence shall therefore be 1 503 bytes. The 
//		randomization process shall be active also when the modulator input 
//		bit-stream is non-existant, or when it is noncompliant with the MPEG-2 
//		transport stream format (i.e. 1 sync byte + 187 packet bytes). This 
//		is to avoid the emission of an unmodulated carrier from the modulator.

//////////////////////////////////////////////////////////////////////////-
//	rev: 1.0
//	author: liuchy
//	date: May 9, 2008
/////////////////////////////////////////////////////////////////////////-
`timescale 1ns/1ns

module sync1InvertPRBS(
	iClk,
	iValid,
	iClrn,
	iData,
	iPSync,
	iCheck,
	oData,
	oValid,
	oCheck,
	oPSync
	);
	
	output logic [7:0] oData = 8'b0;
	output logic oValid = 1'b0, oPSync = 1'b0;
	output logic oCheck = 1'b0;
	input iClk, iClrn;
	input iPSync, iValid, iCheck;
	input[7:0] iData;
	
	localparam	INITIALBITS = 15'b000000010101001;
	
////////////////////////////////////////////////////////////////////////-
	logic[2:0] packCnt = 3'b0;//sync words counter (package counter)
	logic[15:1] prbs = INITIALBITS;
	logic[7:0] serial;
////////////////////////////////////////////////////////////////////////-
	assign serial[7:0] = prbs[15:8] ^ prbs[14:7];

	always_ff @(posedge iClk or negedge iClrn) begin
		if (!iClrn) begin
			packCnt <= #1 3'b0;
			oValid <= #1 1'b0;
			oPSync <= #1 1'b0;
			oData <= #1 8'b0;
			prbs <= #1 15'b0;
			oCheck <= #1 1'b0;
		end
		else begin
			oValid <= #1 iValid;
			oCheck <= #1 iCheck;
			oPSync <= #1 iPSync;
			if (iValid) begin
				if (iCheck)
					oData <= #1 8'd0;
				else begin
					prbs <= #1 {prbs[7:1], serial};
					oData <= #1 serial ^ iData;
					if (iPSync) begin
						packCnt <= #1 packCnt + 3'b1;
						oData <= #1 iData;
						if (packCnt == 3'b0) begin
							prbs <= #1 INITIALBITS;
							oData <= #1 ~iData;
						end
					end
				end
			end
		end
	end
endmodule
