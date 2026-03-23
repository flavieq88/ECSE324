.global _start
_start:

// HEX display drivers
//
// One hot encoded HEX display indices
// HEX0 = 0x00000001
// HEX1 = 0x00000002
// HEX2 = 0x00000004
// HEX3 = 0x00000008
// HEX4 = 0x00000010
// HEX5 = 0x00000020

// Turns off all the segments of the selected HEX displays.
// pre- A1: selected HEX display indices
HEX_clear_ASM: 
	
	BX LR
	
// Turns on all the segments of the selected HEX displays.
// pre- A1: selected HEX display indices
HEX_flood_ASM:

	BX LR
	
// Displays a integer value 0-15 on the selected HEX display(s).
// pre- A1: HEX display indices
//		A2: hexadecimal integer to display
HEX_write_ASM:
	
	BX LR


	