.global _start
_start:

// turns the LEDs on/off based on the corresponding switches
loop: 
	BL read_slider_switches_ASM // read state of slider switches into A1
	BL write_LEDs_ASM // turn on corresponding LEDs from switch state
	B loop
	
// Slider switches driver
// returns the state of slider switches in A1
// post- A1: slide switch state
.equ SW_ADDR, 0xFF200040 // memory location for slider switch data
read_slider_switches_ASM: 
	LDR A2, =SW_ADDR // load address of slider switch state
	LDR A1, [A2] // read slider switch state into A1
	BX LR

// LEDs driver
// writes the state of LEDs (on/off) in A1 to the LED's control register
// pre- A1: data to write to LED state
.equ LED_ADDR, 0xFF200000 // memory location for LEDs
write_LEDs_ASM: 
	LDR A2, =LED_ADDR // load the address of the LED's state
	STR A1, [A2] // update LED state with the contents of A1
	BX LR
	

	