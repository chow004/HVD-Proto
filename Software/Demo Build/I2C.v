/*==========================================================
	File: I2C.v

	Author: Cassandra Chow

	Copyright DigiPen Institute of Technology 2014

	Brief: Module for implementing i2c protocol targeted
			 for the Altera DE2-115 Dev. Board
==========================================================*/
module I2C(
clk_50,
WR,
length,
request, 
DE,
SDA, 
SCL, 
txReg, 
rxReg, 
address, 
sub_address, 
busy);
				
input			   clk_50;
input			   WR;
input			   [7:0]length;
input			   request;

input			   [6:0]address;
input			   [7:0]sub_address;

input			   [7:0]txReg;		// transmit register
output reg	   [7:0]rxReg;		// receive register

inout			   SDA;
inout 		   SCL;
output reg	   DE;			// data enable
									// ... indicates when register has processed 1 byte
									
output reg	busy;

// state variables
reg  	[1:0]State;
reg	[1:0]subState;
reg	[1:0]Next;
reg	[1:0]subNext;

// states
parameter 	IDLE 		= 2'b00;
parameter 	SETUP 	= 2'b11;
parameter 	READ		= 2'b10;
parameter 	WRITE		= 2'b01;
// substates
parameter	ssADDR		= 2'b00;
parameter	ssSADDR		= 2'b01;
parameter	ssRECEIVE	= 2'b10;
parameter	ssIDLE		= 2'b11;

// clock control variables
reg			[6:0]counter;
reg         counter_reset;

// data control variables
reg			[7:0]bytes_processed;
reg			[3:0]scl_ticks;
reg		   I2C_READY;
reg		   I2C_DATA;
reg 		   I2C_CLK;

// system clocks
reg			CE;
reg			LCLK;

// bus lines are open-drain
assign SDA = ~I2C_DATA ? 0 : 1'bZ;
assign SCL = ~I2C_CLK ? 0 : 1'bZ;

initial begin
	rxReg = 0;
	DE = 0;
	
	State = IDLE;
	subState = ssADDR;
	Next = IDLE;
	subNext = ssADDR;
	
	LCLK = 0;
	CE = 0;
	counter = 0;
	counter_reset = 0;
	
	I2C_CLK = 1;
	I2C_DATA = 1;
	bytes_processed = 0;
	
	scl_ticks = 0;
	busy = 0;
	I2C_READY = 0;
end

// 7-bit counter -> 390.625 kHz
always @ (posedge clk_50) begin
	counter = counter + 1;
	LCLK = ~counter[6];
	
	if(CE) begin	// if counter clock control enabled...
		if(counter_reset == 0) begin // if the counter hasn't been reset...
		  counter = 7'b1000000;      // reset the counter
		  counter_reset = 1;
		end
		I2C_CLK = counter[6]; // set the SCL according to counter. On reset it's 1
	end
	else if(I2C_CLK == 0) begin
	  I2C_CLK = counter[6];
	  counter_reset = 0;
	end
	else begin
	  counter_reset = 0;
	end
end


// state machine logic
always @ (posedge LCLK) begin
	State = Next;
	subState = subNext;
	
	case(State)
		IDLE: begin
		   busy <= 0;
			I2C_DATA <= 1;
			I2C_READY <= 1;
			if(request) begin
				Next <= SETUP;			  // goto SETUP state
				subNext <= ssADDR;
		      I2C_DATA <= 0;     // send start bit
				CE <= 1;
				I2C_READY <= 0;
			end
		end
		SETUP: begin
			case(subState)
				ssADDR: begin
					busy <= 1;
					if(scl_ticks < 7) begin			// send 7-bit addr
						I2C_DATA = address[6 - scl_ticks];
					end
					else if(scl_ticks == 7) begin // send R/W = 0
						I2C_DATA <= 0;
					end
					else begin
						I2C_DATA <= 1;
						subNext <= ssSADDR;
					end
				end
				ssSADDR: begin
					if(scl_ticks < 8) begin			// send 7-bit sub addr
						I2C_DATA = sub_address[7 - scl_ticks];
					end
					else if(scl_ticks == 8) begin	// set SDA to 'Z'
					  I2C_DATA <= 1;				   // to receive ACK
						if(WR == 1) begin
							Next <= WRITE;				// goto WRITE next state execution
						end
						else begin
							Next <= READ;				// goto READ next state execution
							subNext <= ssIDLE;	
						end
					end
				end
			endcase
		end
		READ: begin
			case(subState)
				ssIDLE: begin
				  if(I2C_DATA == 0) begin // prep for start cond.		
					  I2C_DATA <= 1;
					end
					else if(CE == 1) begin
					  CE <= 0;		        // SCL = Z for repeating start cond.
					end
					else begin
					  subNext <= ssADDR;
					  I2C_DATA <= 0;       // send repeated start
					  CE <= 1;
					end
				end
				ssADDR: begin
					if(scl_ticks < 7) begin			// send 7-bit addr
						I2C_DATA = address[6 - scl_ticks];
					end
					else if(scl_ticks == 7) begin // send R/W = 1
						I2C_DATA <= 1;
					end
					else begin							            // set SDA to 'Z'
						I2C_DATA <= 1;						         // to receive ACK
						subNext <= ssRECEIVE;
					end
				end
				ssRECEIVE: begin
					if(bytes_processed < length) begin
						if(scl_ticks < 8) begin
							I2C_DATA <= 1;						      // SDA is 'Z'
						end
						else if(scl_ticks == 8) begin // send ACK/NACK
							if(bytes_processed + 1 == length) begin
								I2C_DATA <= 1; // NACK
							end
							else begin
								I2C_DATA <= 0; // ACK
							end
						end
					end
					else if(bytes_processed == length) begin
					  // setup for stop cond.
			        I2C_DATA <= 0;
					  CE <= 0;
					end
					else begin
						I2C_DATA <= 1;
						Next <= IDLE;
						subNext <= ssIDLE;
					end
				end
			endcase
		end
		WRITE: begin
			if(bytes_processed < length) begin
				if(scl_ticks < 8) begin				         // Send data bits
					I2C_DATA <= txReg[7 - scl_ticks]; // MSB first
				end
				else if(scl_ticks == 8) begin // receive ACK
				  I2C_DATA <= 1;
				end
			end
			else if(bytes_processed == length) begin
			  // setup for stop cond.
			  CE <= 0;
			  I2C_DATA <= 0;						
			end
			else begin
				I2C_DATA <= 1;
				Next <= IDLE;
				subNext <= ssIDLE;
			end
		end
	endcase
end

always @ (posedge SCL) begin
	
	scl_ticks = scl_ticks + 1;
	
	case(State)
	  IDLE: begin
	    scl_ticks <= 0;
	    DE <= 0;
	  end
	  SETUP: begin
		  DE <= 0;
		  bytes_processed <= 0;
		  if(scl_ticks == 9) begin
		    scl_ticks <= 0;
		  end
		end
		READ: begin
			case(subState)
			  ssIDLE: begin
			    scl_ticks <= 0;
			  end
			  ssADDR: begin
				 if(subNext == ssRECEIVE) begin
					scl_ticks <= 0;
				 end
			  end
			  ssRECEIVE: begin
					if(scl_ticks < 9) begin
						rxReg[8 - scl_ticks] <= SDA;
					end
					if(scl_ticks == 9 || CE == 0) begin
						bytes_processed <= bytes_processed + 1;
						scl_ticks <= 0;
						DE <= 1;
					end
					else begin
						DE <= 0;
					end
			  end
			endcase
		end
		WRITE: begin
			if(scl_ticks == 9 || CE == 0) begin
				scl_ticks <= 0;
				bytes_processed <= bytes_processed + 1;
				DE <= 1;
			end
			else begin
			  DE <= 0;
			end
		end
	endcase
end

endmodule

