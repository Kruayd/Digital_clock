module clock(CLOCK_50, GPIO_1, , HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7, LEDR);

	// The main idea is to create a finite state machine that,
	// as soon as it is turned on, starts synchronizing with
	// the signal emitted by the antenna of the atomic clock
	// at Frankfurt. Once synchronized it starts listening to
	// the time data transmitted by the radio station and,
	// once it has it, it goes on by itself as a standard
	// clock



	// In the clock section the 50 MHz clock is passed to
	// the freqdivider module in order to get a 100 Hz signal.
	// This new clock is going to be the base clock for
	// the state machine
	input CLOCK_50;
	wire clock;
	freqdivider(CLOCK_50, clock);
	
	// The DCF reciever output is connected to the 0th pin
	// of the GPIO_1 port
	input [1:0] GPIO_1;
	// Since the signal posedges seem to be not well detected
	// a debounced signal is generated for counting the ticks
	wire debounced;
	debounce(clock, GPIO_1, debounced);
	
	// The time data shoudl be displayed ont the HEX displays
	// of the board
	output [6:0] HEX0;
	output [6:0] HEX1;
	output [6:0] HEX2;
	output [6:0] HEX3;
	output [6:0] HEX4;
	output [6:0] HEX5;
	output [6:0] HEX6;
	output [6:0] HEX7;
	
	// Since the needed states are 3, the minimum number
	// of bits required to describe them is 2
	reg [1:0] state = 2'b0;
	// This counter is used many times and for differetn
	// purposes so it is good to make it a byte length
	reg [7:0] counter = 8'b0;
	
	// time related variables
	reg [7:0] cent = 8'b0;
	reg [7:0] sec = 8'b0;
	reg [7:0] min = 8'b0;
	reg [7:0] hour = 8'b0;
	
	// time multiplyers
	reg [7:0] min_u = 8'b0000_0001;
	reg [7:0] min_d = 8'b0000_0001;
	reg [7:0] hour_u = 8'b0000_0001;
	reg [7:0] hour_d = 8'b0000_0001;
	
	// Main always block
	always @ (posedge clock)
	case (state)

	
	2'b00: // sync
		// In the sync state the machine looks for the 2 seconds low pattern
		// in the signal at the end of each minute. To do so it counts up from
		// 0 whenever the 100 Hz clock is ticking and when the counter reaches
		// the value 1001_0110 (150 in decimal), it means that around 1.5 seconds
		// have passed from the previous low state and, therefore the state is
		// changed to 01. The number of tickings N
		// in a time interval T is evalueted as N = clock_frequency * T.
		// Whenever the signal is high, the counter is reset
		if (GPIO_1[0])
			counter <= 8'b0;
		else if (counter >= 8'b1001_0110) begin;
			state <= 2'b01;
			counter <= 8'b0;
			end
		else
			counter <= counter + 1;

	
	2'b01: // listen
		// In the listen state the machine decodes the signal and each time add
	   //	the gathered value to the relevant rega variables (min or hour).
		// Since the signal is PWM, whenever it is high, starting from 0, the counter
		// increases by 1 at each clock cycle. When the signal gets down again,
		// the counter is compared to different values If it is grater than 15
		// (0000_1111), then it corresponds to a 1 and an addition is performed,
		// the corresponding time multiplyer factor is doubled and the counter is
		// reset. If it is just grater than 7 (0000_0111), then it corresponds to a 0
		// and only the multiplication and the reset operations are performed.
		// If none of the previous condition is satysfied, then probably we have
		// noise and the counter is reset to 0.
		// Furthermore, we are only interested in specific bits, namely the
		// ones (starting from 1 not from 0) from 22 (0001_0110) to 28 (0001_1100)
		// and the ones from 30 (0001_1110) to 35 (0010_0011).
		if (GPIO_1[0])
			counter <= counter + 1;
		else begin;
		
			// Minute block that corresponds to a 1 in the signal.
			// The first 4 bits express units (1, 2, 4, 8), thus, they are added
			// without any prefactor to the min reg variable.
			if (counter >= 8'b0000_1111 && 
			(tick >= 8'b0001_0110 && tick <= 8'b0001_1001))begin;
				min <= min + min_u;
				min_u <= min_u * 2;
				counter <= 8'b0;
				end
			// The 3 remaining bits express tens (10, 20, 40), so a prefactor equals
			// to ten must be used before adding min_d to min
			else if (counter >= 8'b0000_1111 && 
			(tick >= 8'b0001_1010 && tick <= 8'b0001_1100))begin;
				min <= min + (10 * min_d);
				min_d <= min_d * 2;
				counter <= 8'b0;
				end
			
			// Hour block that corresponds to a 1 in the signal.
			// Everything is like the minute block execpt from the fact that
			// --->
			else if (counter >= 8'b0000_1111 && 
			(tick >= 8'b0001_1110 && tick <= 8'b0010_0001))begin;
				hour <= hour + hour_u;
				hour_u <= hour_u * 2;
				counter <= 8'b0;
				end
			// ---> the tens bits are 2 (10, 20) and not 3.
			else if (counter >= 8'b0000_1111 && 
			(tick >= 8'b0010_0010 && tick <= 8'b0010_0011))begin;
				hour <= hour + (10 * hour_d);
				hour_d <= hour_d * 2;
				counter <= 8'b0;
				end
				
			// Minute block that corresponds to a 0 in the signal.
			// No addition is performed but the multiplyer must still be 
			// doubled
			else if (counter >= 8'b0000_0111 && 
			(tick >= 8'b0001_0110 && tick <= 8'b0001_1001))begin;
				min_u <= min_u * 2;
				counter <= 8'b0;
				end
			else if (counter >= 8'b0000_0111 && 
			(tick >= 8'b0001_1010 && tick <= 8'b0001_1100))begin;
				min_d <= min_d * 2;
				counter <= 8'b0;
				end
			
			// Hour block that corresponds to a 0 in the signal.
			else if (counter >= 8'b0000_0111 && 
			(tick >= 8'b0001_1110 && tick <= 8'b0010_0001))begin;
				hour_u <= hour_u * 2;
				counter <= 8'b0;
				end
			else if (counter >= 8'b0000_0111 && 
			(tick >= 8'b0010_0010 && tick <= 8'b0010_0011))begin;
				hour_d <= hour_d * 2;
				counter <= 8'b0;
				end

			// As soon the next minute starts at the 60th (0011_1100) tick,
			// the state is changed to clock (10)
			else if (tick >= 8'b0011_1100)
				state <= 2'b10;
			else
				counter <= 8'b0;
			end



	2'b10: // clock
		// Inthe clock state the board just works as a standard clock:
		// At each clock cycle it checks for different conditions:
		// time = 23:59:59.99 : reset all reg variables
		// time = XX:59:59.99 : reset everything execpt hour and add
		//								1 to it
		// time = XX:YY:59.99 : reset sec and cent and add 1 to minute
		// time = XX:YY:ZZ.99 : reset cent and add 1 to sec
		// time = XX:YY:ZZ.WW : add 1 to cent
		
		// Since the clock is running at 100 Hz, the cent variable
		// should increase with the same frequency, thus, counting
		// hundredths of a second
			if (cent >= 8'b0110_0011)
				if (sec >= 8'b0011_1011)
					if (min >= 8'b0011_1011)
						if (hour >= 8'b0001_0111) begin;
							hour <= 8'b0;
							min <= 8'b0;
							sec <= 8'b0;
							cent <= 8'b0;
							end
						else begin;
							hour <= hour + 1;
							min <= 8'b0;
							sec <= 8'b0;
							cent <= 8'b0;
							end
					else begin
						min <= min +1;
						sec <= 8'b0;
						cent <= 8'b0;
						end
				else begin;
					sec <= sec + 1;
					cent <= 8'b0;
					end
			
			else
				cent <= cent + 1;
	
	default: begin //error
		// Everything is reset to the initial state
		counter <= 8'b0;
		min_u <= 8'b0000_0001;
		min_d <= 8'b0000_0001;
		hour_u <= 8'b0000_0001;
		hour_d <= 8'b0000_0001;
		cent <= 8'b0;
		sec <= 8'b0;
		min <= 8'b0;
		hour <= 8'b0;
		state <= 2'b0;
		end
	
	endcase
	
	

	reg [7:0] tick = 8'b0;
	// The following always block counts the ticks of the signal but only if the
	// machine is in the listen state
	always @ (posedge debounced)
	if (state == 2'b01)
		tick <= tick + 1;
	else
		tick <= 0;
	

	bcddisplay d0 (cent, HEX1, HEX0);
	bcddisplay d1 (sec, HEX3, HEX2);
	bcddisplay d2 (min, HEX5, HEX4);
	bcddisplay d3 (hour, HEX7, HEX6);
	
	// debugging
	output [1:0] LEDR = state;

endmodule