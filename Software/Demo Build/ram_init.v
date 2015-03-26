/*==========================================================
	File: ram_init.v

	Author: Cassandra Chow

	Copyright DigiPen Institute of Technology 2014

	Brief: M9K ram used to store all initialization
	i2c operations.
==========================================================*/
module ram_init(
clk,
WE,
address,
data_in,
data_out);

input clk;
input WE;
input [11:0]address;
input [23:0]data_in;
output reg [23:0]data_out;

(* ramstyle = "M9K", ram_init_file = "adv7611.mif" *) reg [23:0] init_mem[0:511];

always @(posedge clk)
begin
	if(WE == 1) begin
		init_mem[address] <= data_in;
	end
	data_out <= init_mem[address];
end

endmodule

