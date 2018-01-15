//---------------------------------------------------------

//	filename: cycle_counter.sv

//		copyrigh(c)
//---------------------------------------------------------------
//	Cycle_counter Parameters Reference Design: This design provides a 
//		cycle counter from LVALUE to HVALUE.
//---------------------------------------------------------------------
//	Revision 	Date	Description			Edited		Author
//	2.1			3/20	finished 			be 			Hawke
`timescale 1ns/1ns

module cycleCounter
#(parameter ADDRWIDTH = 11, parameter LDATA = 18*55+1, parameter HDATA = 18*66)
(
iClk, iClrn, iEn, oCnt
);

	input iClk, iClrn;
	input iEn;
	output [ADDRWIDTH-1:0] oCnt;

	logic [ADDRWIDTH-1:0] cnt = LDATA;
	logic started = 1'b0;
	assign oCnt = cnt;
	
	always_ff @(posedge iClk or negedge iClrn) begin
		if (!iClrn) begin
			cnt <= #1 'b0;
			started <= #1 1'b0;
		end
		else begin
			started <= #1 1'b1;
			if (!started) begin
				cnt <= #1 LDATA;
			end
			else if (cnt < LDATA)
				cnt <= #1 LDATA;
			else if (iEn) begin
				if (cnt < HDATA)
					cnt <= #1 cnt + 1;
				else
					cnt <= #1 LDATA;
			end
		end
	end
endmodule
