module debounce (clock, noisy, debounced);

	parameter delay = 25; // so 250ms for a 100Hz clk
	input clock, noisy;
	output reg debounced;

	reg [4:0] count; // 5 bits are enough to count up to 25 (1_1001)

	always @(posedge clock)
		if (noisy == 1 && debounced != noisy) begin
			debounced <= 1;
			count <= 0;
			end
		else if (count >= delay) debounced <= 0;
	else count <= count + 1;

endmodule
