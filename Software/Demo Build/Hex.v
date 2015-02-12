/*==========================================================
	File: Hex.v

	Author: Cassandra Chow

	Copyright DigiPen Institute of Technology 2014

	Brief: Module for converting 4-bit binary to hex display
	       output
==========================================================*/
module To_Hex(bin4, display);

input  	 [3:0]bin4;
output reg[6:0]display;

always begin
	if(bin4 == 0) begin
		display <= 64;
	end
	else if(bin4 == 1) begin
		display <= 121;
	end
	else if(bin4 == 2) begin
		display <= 36;
	end
	else if(bin4 == 3) begin
		display <= 48;
	end
	else if(bin4 == 4) begin
		display <= 25;
	end
	else if(bin4 == 5) begin
		display <= 18;
	end
	else if(bin4 == 6) begin
		display <= 2;
	end
	else if(bin4 == 7) begin
		display <= 120;
	end
	else if(bin4 == 8) begin
		display <= 0;
	end
	else if(bin4 == 9) begin
		display <= 16;
	end
	else if(bin4 == 10) begin
		display <= 8;
	end
	else if(bin4 == 11) begin
		display <= 3;
	end
	else if(bin4 == 12) begin
		display <= 39;
	end
	else if(bin4 == 13) begin
		display <= 33;
	end
	else if(bin4 == 14) begin
		display <= 6;
	end
	else if(bin4 == 15) begin
		display <= 14;
	end
end

endmodule

