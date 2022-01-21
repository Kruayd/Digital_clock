module freqdivider(clock, newclock);

	input clock;
	
	output newclock;
	
	reg [19:0] counter;
	reg regclock;
	
	always @ (posedge clock)
		if (counter == 20'b0011_1101_0000_1001_0000) begin;
			counter <= 20'b0;
			regclock = ~regclock;
			end
		else
			counter <= counter + 1;
		
	// Statement that helps with dividing reg from wires:
	
	assign newclock = (regclock==0);
		
endmodule