/*==========================================================
	File: HDMI_Receive.v

	Author: Cassandra Chow

	Copyright DigiPen Institute of Technology 2014

	Brief: Module for interfacing with the Analog Devices
	HDMI Receiver, ADV7611
==========================================================*/
module HDMI_Receive (
CLOCK_50,
SW,
KEY,
HEX0,
HEX1,
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
LEDR
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
output wire[6:0]HEX4;
output wire[6:0]HEX5;
output wire[6:0]HEX6;
output wire[6:0]HEX7;

reg		  [3:0]val0;
reg		  [3:0]val1;
reg		  [3:0]val4;
reg		  [3:0]val5;
reg		  [3:0]val6;
reg		  [3:0]val7;


To_Hex hex_display0(.bin4(val0), .display(HEX0));
To_Hex hex_display1(.bin4(val1), .display(HEX1));
To_Hex hex_display4(.bin4(val4), .display(HEX4));
To_Hex hex_display5(.bin4(val5), .display(HEX5));
To_Hex hex_display6(.bin4(val6), .display(HEX6));
To_Hex hex_display7(.bin4(val7), .display(HEX7));

reg		i2c0_wren;				// indicates r/w for i2c
reg		[7:0]i2c0_size;		// indicates r/w size in bytes for i2c
reg		i2c0_req;				// controls i2c requests
reg		temp;
wire		i2c0_de;					// indicates when i2c data has been processed
reg		[7:0]i2c0_tx;			// transmit reg
wire		[7:0]i2c0_rx;			// receive reg
reg		[6:0]i2c0_addr;		// address    (HDMI map address)
reg		[7:0]i2c0_saddr;		// subaddress (HDMI subaddress in map)
reg		[3:0]i2c0_bytes_received;

wire		err;

// i2c module
I2C receiver_i2c(.clk_50(CLOCK_50), .WR(i2c0_wren), .length(i2c0_size),
 .request(i2c0_req), .DE(i2c0_de), .SDA(HDMI0_RX_SDA), .SCL(HDMI0_RX_SCL),
 .txReg(i2c0_tx), .rxReg(i2c0_rx), .address(i2c0_addr), .sub_address(i2c0_saddr), .error(err));


initial begin
	i2c0_req = 0;
	i2c0_wren = 1;
	i2c0_bytes_received = 0;
	
	LEDG[8:0] = 0;
	LEDR[17:0] = 0;
	val0 = 0;
	val6 = 0;
	val7 = 0;
	
	HDMI0_RX_RESET = 1;
	temp = 0;
end

always @(posedge CLOCK_50) begin
	val0 <= SW[3:0];
	val1 <= SW[7:4];
	val6 <= SW[13:10];
	val7 <= SW[17:14];
	i2c0_saddr <= SW[17:10];		// subaddress = SW17-S10
	i2c0_addr <= 7'b1001100;		// IO map address = 0x98
	i2c0_tx <= SW[7:0];				// byte to transfer = SW7-SW0
	
	val4 <= i2c0_rx[3:0];			// byte received
	val5 <= i2c0_rx[7:4];
  
  if(KEY[0] == 0 && temp == 0) begin				// KEY0 pressed
    i2c0_wren = 1;					// perform i2c write
	 i2c0_size = 1;					// write only 1 byte
	 i2c0_req = 1;
	 temp = 1;
  end
  else if(KEY[1] == 0 && temp == 0) begin		// KEY1 pressed
    i2c0_wren = 0;					// perform i2c read
	 i2c0_size = 1;					// read only 1 byte
    i2c0_req = 1;
	 temp = 1;
  end
  else if(KEY[2] == 0)begin
    temp = 0;						// else do nothing
  end
  else if(err == 1)begin
    i2c0_req = 0;
  end
	 
  LEDG[7:0] <= i2c0_rx[7:0];
end

/*
always @(posedge i2c0_de) begin
	if(i2c0_wren == 1) begin
	  i2c0_tx <= i2c0_tx << 1;
	end
	else begin
	  i2c0_bytes_received = i2c0_bytes_received + 1;
	  if(i2c0_bytes_received == 1) begin
		 LEDR[17:10] <= i2c0_rx;
	  end
	  else if(i2c0_bytes_received == 2) begin
	    LEDR[9:2] <= i2c0_rx;
		 i2c0_bytes_received = 0;
	  end
	end
	
	if(i2c0_tx == 0) begin
		i2c0_tx <= 8'b0001011;
	end
end
*/

endmodule

