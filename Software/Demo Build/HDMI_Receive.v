/*==========================================================
	File: HDMI_Receive.v

	Author: Cassandra Chow

	Copyright DigiPen Institute of Technology 2014

	Brief: Module for interfacing with the Analog Devices
	HDMI Receiver, ADV7611. Top-level
==========================================================*/
module HDMI_Receive (
CLOCK_50,
SW,
KEY,
HEX0,
HEX1,
HEX2,
HEX3,
HEX4,
HEX5,
HEX6,
HEX7,
HDMI0_RX_RESET,
HDMI0_RX_HSYNC,
HDMI0_RX_VSYNC,
HDMI0_RX_MCLK,
HDMI0_RX_LRCLK,
HDMI0_RX_SCLK,
HDMI0_RX_AP,
HDMI0_RX_SCL,
HDMI0_RX_SDA,
HDMI0_RX_DE,
HDMI0_RX_LLC,
HDMI0_RX_P,
LEDG,
LEDR,
VGA_R,
VGA_G,
VGA_B,
VGA_CLK,
VGA_BLANK_N,
VGA_VS,
VGA_HS
);

input 	CLOCK_50;
input 	[17:0]SW;
input 	[3:0]KEY;
input 	[23:0]HDMI0_RX_P;		// pixel data
input		HDMI0_RX_LLC;			// line-locked pixel data clock
input		HDMI0_RX_DE;			// pixel data enable

inout		HDMI0_RX_SDA;			// I2C data line
										// -- cannot read/write at same time, assign highZ for reading
										// -- can NOT be type reg
										// -- must have a condition at which the port is written or read upon
										// -- ex) assign SDA = (condition) ? <value> : n'bZ;										
inout    HDMI0_RX_SCL;			// I2C clock line

input 	HDMI0_RX_AP;			// Audio output from chip
input 	HDMI0_RX_SCLK;			// audio serial clock
input 	HDMI0_RX_LRCLK;		// audio left-right clock
input 	HDMI0_RX_MCLK;			// audio master clock

input		HDMI0_RX_VSYNC;		// THESE ARE
input		HDMI0_RX_HSYNC;		// INPUT ONLY PINS

output reg	HDMI0_RX_RESET;		// ACTIVE LOW, resets HDMI receiver

output reg [9:0]LEDG;
output reg [18:0]LEDR;
output wire[6:0]HEX0;
output wire[6:0]HEX1;
output wire[6:0]HEX2;
output wire[6:0]HEX3;
output wire[6:0]HEX4;
output wire[6:0]HEX5;
output wire[6:0]HEX6;
output wire[6:0]HEX7;

output	  [7:0]VGA_R;
output	  [7:0]VGA_G;
output	  [7:0]VGA_B;
output     VGA_CLK;
output     VGA_BLANK_N;
output     VGA_HS;
output 	  VGA_VS;

reg		  [3:0]val0;
reg		  [3:0]val1;
reg		  [3:0]val2;
reg		  [3:0]val3;
reg		  [3:0]val4;
reg		  [3:0]val5;
reg		  [3:0]val6;
reg		  [3:0]val7;


To_Hex hex_display0(.bin4(val0), .display(HEX0));
To_Hex hex_display1(.bin4(val1), .display(HEX1));
To_Hex hex_display2(.bin4(val2), .display(HEX2));
To_Hex hex_display3(.bin4(val3), .display(HEX3));
To_Hex hex_display4(.bin4(val4), .display(HEX4));
To_Hex hex_display5(.bin4(val5), .display(HEX5));
To_Hex hex_display6(.bin4(val6), .display(HEX6));
To_Hex hex_display7(.bin4(val7), .display(HEX7));

reg		i2c0_wren;				// indicates r/w for i2c
reg		[7:0]i2c0_size;		// indicates r/w size in bytes for i2c
reg		i2c0_req;				// controls i2c requests
wire		i2c0_de;					// indicates when i2c data has been processed
reg		[7:0]i2c0_tx;			// transmit reg
wire		[7:0]i2c0_rx;			// receive reg
reg		[6:0]i2c0_addr;		// address    (HDMI map address)
reg		[7:0]i2c0_saddr;		// subaddress (HDMI subaddress in map)

wire		busy;
wire		[3:0]ticks;
wire		[1:0]state;
wire		[1:0]substate;
wire		[7:0]bytes;

reg		de_oneshot;
reg		[18:0]i2c0_reset_delay;

// i2c module
I2C receiver_i2c(.clk_50(CLOCK_50), .WR(i2c0_wren), .length(i2c0_size),
 .request(i2c0_req), .DE(i2c0_de), .SDA(HDMI0_RX_SDA), .SCL(HDMI0_RX_SCL),
 .txReg(i2c0_tx[7:0]), .rxReg(i2c0_rx[7:0]), .address(i2c0_addr), .sub_address(i2c0_saddr),
 .busy(busy), .scl_ticks(ticks), .State(state), .subState(substate), .bytes_processed(bytes));
 
reg mem_wr;
reg [11:0]mem_addr;
reg [23:0]mem_in;
wire [23:0]mem_out;
reg mem_done;

reg ready;

ram_init mem(.clk(CLOCK_50), .WE(mem_wr), .address(mem_addr), .data_in(mem_in), .data_out(mem_out));

assign VGA_R = HDMI0_RX_P[7:0];
assign VGA_G = HDMI0_RX_P[15:8];
assign VGA_B = HDMI0_RX_P[23:16];
assign VGA_CLK = HDMI0_RX_LLC;
assign VGA_BLANK_N = HDMI0_RX_DE;
assign VGA_HS = HDMI0_RX_HSYNC;
assign VGA_VS = HDMI0_RX_VSYNC;

initial begin
	i2c0_req = 0;
	i2c0_wren = 1;
	
	LEDG[8:0] = 0;
	LEDR[17:0] = 0;
	
	HDMI0_RX_RESET = 1;
	de_oneshot = 0;
	
	i2c0_addr = 8'b0;
	i2c0_saddr = 8'b0;
	i2c0_reset_delay = 0;
	
	mem_wr = 0;
	mem_addr = 12'h127;
	mem_in = 24'b0;
	mem_done = 1;
  ready = 1;
end

always @(posedge CLOCK_50) begin
	val0 = SW[3:0];
	val1 = SW[7:4];
	val2 = i2c0_rx[3:0];
	val3 = i2c0_rx[7:4];
	val6[3:1] = i2c0_addr[2:0];
	val7 = i2c0_addr[6:3];
	val4 = i2c0_saddr[3:0];
	val5 = i2c0_saddr[7:4];
	
/*	if(i2c0_reset_delay == 0 && busy == 0 && i2c0_req == 0) begin
		// reset main i2c, set registers to default val
		i2c0_tx = 8'h80;
		i2c0_saddr = 8'hFF;
		i2c0_addr = 7'b1001100; // 0x98 (IO)
		i2c0_size = 1;
		i2c0_wren = 1;
		i2c0_req = 1;
		i2c0_reset_delay = i2c0_reset_delay + 19'b1;
	end 
	else if(i2c0_reset_delay[18] & i2c0_reset_delay[15]) begin
		// ^^^ wait until rest delay count reaches 294,912 (approx. 6 ms)
		LEDR[0] = 0; */

		if(~mem_done & ~busy & ~i2c0_req) begin
			i2c0_tx = mem_out[7:0];
			i2c0_saddr = mem_out[15:8];
			i2c0_addr = mem_out[23:17]; 
			i2c0_size = 1;
			i2c0_wren = 1;
			i2c0_req = 1;
			mem_addr = mem_addr + 12'b1;
		end
	
		if(mem_addr == 12'h127) begin
			mem_done = 1;
		end
    
    if(SW[17] == 1) begin
      mem_done = 0;
      mem_addr = 12'b0;
    end
	
		if(~KEY[0] & ~i2c0_req & ~busy & ready) begin			// KEY0 pressed
			i2c0_tx[7:0] = SW[7:0];		// byte to transfer = SW7-SW0
			i2c0_wren = 1;					// perform i2c write
			i2c0_size = 1;					// write only 1 byte
			i2c0_req = 1;
      ready = 0;
		end
		else if(~KEY[1] & ~i2c0_req & ~busy & ready) begin		// KEY1 pressed
			i2c0_wren = 0;					// perform i2c read
			i2c0_size = 1;					// read only 1 byte
			i2c0_req = 1;
      ready = 0;
		end
		else if(~KEY[2]) begin // input address
			i2c0_addr = SW[7:1];
		end 
		else if(~KEY[3]) begin // input sub-address
			i2c0_saddr = SW[7:0];
		end
	
    if(SW[13] == 1) begin
      ready = 1;
    end
/*		if(i2c0_de & !de_oneshot) begin
			i2c0_tx = i2c0_tx >> 8;
		end
  
		de_oneshot = i2c0_de;
	end
	else begin
		i2c0_reset_delay = i2c0_reset_delay + 19'b1;
		LEDR[0] = 1;
	end
*/
		if(busy == 1)begin
			i2c0_req = 0;
		end
	
		LEDG[7:0] = bytes;
		LEDR[17:14] = ticks;
		LEDR[1:0] = substate;
		LEDR[7:6] = state;
		LEDR[12] = busy;
    LEDR[10] = HDMI0_RX_SDA;
		
		if(SW[17]) begin
			mem_done = 0;
			mem_addr = 12'b0;
		end
end

endmodule

