.global _start
.equ HEX0_ADDR, 0xFF200020
.equ HEX4_ADDR, 0xFF200030

// One hot encoded HEX display indices:
// HEX0 = 0x00000001
// HEX1 = 0x00000002
// HEX2 = 0x00000004
// HEX3 = 0x00000008
// HEX4 = 0x00000010
// HEX5 = 0x00000020

_start:
// Test out the HEX display subroutines
	MOV A1, #0x000000C // should match HEX2 and HEX3
	BL HEX_flood_ASM
	BL HEX_clear_ASM
	
	// writing FLAVIE out of HEX digits
	MOV A1, #0x0000020 // should match HEX5
	MOV A2, #0b01110001 // should be F
	BL HEX_write_ASM
	MOV A1, #0x0000012 // should match HEX4 and HEX1
	MOV A2, #0b00000110 // should be 1
	BL HEX_write_ASM
	MOV A1, #0x0000008 // should match HEX3
	MOV A2, #0b01110111 // should be A
	BL HEX_write_ASM
	MOV A1, #0x0000004 // should match HEX2
	MOV A2, #0b00111111 // should be 0
	BL HEX_write_ASM
	MOV A1, #0x0000001 // should match HEX0
	MOV A2, #0b01111001 // should be E
	BL HEX_write_ASM
	MOV A1, #0x000003F // should match all HEX
	BL HEX_clear_ASM
	B end
	
end: 
	B end


// HEX display drivers

// Turns off all the segments of the selected HEX displays.
// pre- A1: selected HEX display indices
HEX_clear_ASM: 
	PUSH {V1-V5}
	MOV V1, #0x00000001 // keep track of which HEX index we are at
	LDR V2, =HEX0_ADDR // store the address of display
	MOV V3, #0 // store the number of times to shift the byte to store at address
	MOV V5, #0b00000000 // cleared HEX display
loop_clear:
	CMP V1, #0x00000040 // stop once we reached past HEX5
	BEQ end_clear
	// test to see if this HEX index is a match
	AND V4, A1, V1 // store bit mask for the HEX display index
	CMP V1, V4
	BNE end_hex_clear // skip this HEX display if not in A1
	// clear the HEX display at correct byte
	STRB V5, [V2, V3]
end_hex_clear:
	LSL V1, V1, #1 // left shift the index once
	ADD V3, V3, #1 // add 4 to shift the bits to store next byte
	CMP V1, #0x00000010 // check if we reached HEX4 to modify address
	BNE loop_clear
	LDR V2, =HEX4_ADDR // jump addresses
	MOV V3, #0 // reset the bit shift counter
	B loop_clear
end_clear:
	POP {V1-V5}
	BX LR
	
	
// Turns on all the segments of the selected HEX displays.
// pre- A1: selected HEX display indices
HEX_flood_ASM:
	PUSH {V1-V5}
	MOV V1, #0x00000001 // keep track of which HEX index we are at
	LDR V2, =HEX0_ADDR // store the address of display
	MOV V3, #0 // store the number of times to shift the byte to store at address
	MOV V5, #0b11111111 // flooded HEX display
loop_flood:
	CMP V1, #0x00000040 // stop once we reached past HEX5
	BEQ end_flood
	// test to see if this HEX index is a match
	AND V4, A1, V1 // store bit mask for the HEX display index
	CMP V1, V4
	BNE end_hex_flood // skip this HEX display if not in A1
	// flood the HEX display at correct byte
	STRB V5, [V2, V3]
end_hex_flood:
	LSL V1, V1, #1 // left shift the index once
	ADD V3, V3, #1 // add 4 to shift the bits to store next byte
	CMP V1, #0x00000010 // check if we reached HEX4 to modify address
	BNE loop_flood 
	LDR V2, =HEX4_ADDR // jump addresses
	MOV V3, #0 // reset the bit shift counter
	B loop_flood
end_flood:
	POP {V1-V5}
	BX LR
	
	
// Displays a integer value 0-15 on the selected HEX display(s).
// pre- A1: HEX display indices
//		A2: hexadecimal integer to display
HEX_write_ASM:
	PUSH {V1-V5}
	MOV V1, #0x00000001 // keep track of which HEX index we are at
	LDR V2, =HEX0_ADDR // store the address of display
	MOV V3, #0 // store the number of times to shift the byte to store at address
loop_write:
	CMP V1, #0x00000040 // stop once we reached past HEX5
	BEQ end_write
	// test to see if this HEX index is a match
	AND V4, A1, V1 // store bit mask for the HEX display index
	CMP V1, V4
	BNE end_hex_write // skip this HEX display if not in A1
	// update the HEX display at correct byte
	STRB A2, [V2, V3]
end_hex_write:
	LSL V1, V1, #1 // left shift the index once
	ADD V3, V3, #1 // add 4 to shift the bits to store next byte
	CMP V1, #0x00000010 // check if we reached HEX4 to modify address
	BNE loop_write 
	LDR V2, =HEX4_ADDR // jump addresses
	MOV V3, #0 // reset the bit shift counter
	B loop_write
end_write:
	POP {V1-V5}
	BX LR


	