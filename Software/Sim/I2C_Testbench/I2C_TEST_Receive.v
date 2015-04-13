/*==========================================================
	File: I2C_TEST_Receive.v
	Author: Cassandra Chow
	Copyright DigiPen Institute of Technology 2014
	Brief: Testbench Module for the receive operations of
	       the I2C module in i2c.v
==========================================================*/
`timescale 1 ns / 100 ps
module I2C_TEST_Receive();
  // module parameters
  reg clk;           // master clock
  reg wren;          // write enable
  reg [7:0]length;   // tranceive length
  reg request;       // request flag     
  reg [7:0]Tdata;    // transmit reg
  wire [7:0]Rdata;   // receive reg
  reg [6:0]addr;     // address reg
  reg [7:0]saddr;    // sub-address reg
  wire sda;          // data line
  wire de;           // data enable line
  wire scl;          // clock line
  
  wire busy;
  wire [3:0]scl_count;
  
  // i2c modules
  I2C M_i2c(.clk_50(clk), .WR(wren), .length(length), .request(request), .DE(de),
      .SDA(sda), .SCL(scl), .txReg(Tdata), .rxReg(Rdata), .address(addr), .sub_address(saddr),
      .busy(busy), .scl_ticks(scl_count));
  
  reg [8:0]temp;
  
  initial begin
    addr = 7'b1001100;
    saddr = 8'b00000001;
    wren = 0; // READ operation
    length = 1; // receive 1 byte
    
    #5000 request = 1;
    #2560 request = 0;
  end
  
  //always @ (posedge de) begin
  //  $display("rx -> %b", temp);
  //end
  
  // 50MHz clock
  always begin
    #10 clk = 0; // 10 ns low
    #10 clk = 1; // 10 ns high
  end
  
endmodule