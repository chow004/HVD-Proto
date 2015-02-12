/*==========================================================
	File: I2C_TEST_Transmit.v

	Author: Cassandra Chow

	Copyright DigiPen Institute of Technology 2014

	Brief: Testbench Module for the transmit operations of
	       the I2C module in i2c.v
==========================================================*/
`timescale 1 ns / 100 ps
module I2C_TEST_Transmit();
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
  
  reg [55:0]Data;    // buffer of data to transmit
  
  // i2c modules
  I2C M_i2c(.clk_50(clk), .WR(wren), .length(length), .request(request), .DE(de),
      .SDA(sda), .SCL(scl), .txReg(Tdata), .rxReg(Rdata), .address(addr), .sub_address(saddr));
  
  reg [8:0]temp;
  reg [2:0]num_xmit;
  
  initial begin 
    // start testing
    Data = 56'h153ABCF800EC2A;
    addr = 7'b0011111;
    saddr = 8'b11001100;
    wren = 1; // WRITE operation
    length = 2; // 2x 8-bit data chunks
    
    Tdata = Data[7:0];  // load first 7-bit chunk into transmit reg
    Data = Data >> 8;
    
    num_xmit = 0;
    #5000 request = 1;
  end
  
  always @ (posedge de) begin
    Tdata = Data[7:0];
    Data = Data >> 8;
    num_xmit = num_xmit + 1;
    if(num_xmit == 3) begin
      request = 0;
    end
    $display("sda -> %b", temp);
  end
  
  always @ (posedge scl) begin
    temp = temp << 1;
    temp[0] = sda;
  end
  
  // 50MHz clock
  always begin
    #10 clk = 0; // 10 ns low
    #10 clk = 1; // 10 ns high
  end
      
endmodule

