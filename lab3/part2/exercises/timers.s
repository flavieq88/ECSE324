.global _start
.equ TIMER_ADDR, 0xFFFEC600
.equ HEX0_ADDR, 0xFF200020
.equ HEX4_ADDR, 0xFF200030

HEX_CODES:
	.byte 0b00111111, 0b00000110, 0b01011011, 0b01001111 // 0, 1, 2, 3
	.byte 0b01100110, 0b01101101, 0b01111101, 0b00000111 // 4, 5, 6, 7
	.byte 0b01111111, 0b01101111, 0b01110111, 0b01111100 // 8, 9, A, b
	.byte 0b00111001, 0b01011110, 0b01111001, 0b01110001 // C, d, E, F

_start:
	// Uses the ARM A9 private timer to count from 0 to 15 every 0.25 seconds.
	MOV V1, #0 // current count
	LDR V2, =TIMER_ADDR
	LDR V3, =HEX_CODES
	BL ARM_TIM_clear_INT_ASM
	LDR A1, =050000000 // timeout = 1/(200MHz) x 50x10^6 = 0.25 sec
	MOV A2, #0b011 // enable auto and enable bits
	BL ARM_TIM_config_ASM
	MOV A1, #0x00000001 // HEX0
	LDRB A2, [V3, #0x0]
	BL HEX_write_ASM
poll:
	// check if interrupt bit is 1
	BL ARM_TIM_read_INT_ASM
	CMP A1, #1
	BEQ update_counter
	B poll

update_counter:
	ADD V1, V1, #1
	CMP V1, #16
	MOVEQ V1, #0 // loop back to 0
	MOV A1, #0x00000001 // HEX0
	LDRB A2, [V3, V1]
	BL HEX_write_ASM // udpate display
	BL ARM_TIM_clear_INT_ASM // reset timer 
	B poll

// Timers

// Configures the timer.
// pre- A1: load value (initial count value)
//      A2: configuration bits
ARM_TIM_config_ASM:
	PUSH {V1-V5}
	LDR V1, =TIMER_ADDR
	STR A1, [V1] // write initial count value into the timer load register
	STR A2, [V1, #8] // write config bits to control register
	POP {V1-V5}
	BX LR
	
// Returns the "F" value of the timer interrupt status register.
// post- A1: 0x00000000 or 0x00000001 (F bit value)
ARM_TIM_read_INT_ASM:
	PUSH {V1-V5}
	LDR V1, =TIMER_ADDR
	LDR A2, [V1, #0xC] // read timer interrupt register
	AND A2, A2, #0x00000001 // clean up rest of data
	POP {V1-V5}
	BX LR
	
// Clears the "F" value of the timer interrupt status register.
ARM_TIM_clear_INT_ASM:
	PUSH {V1-V5}
	LDR V1, =TIMER_ADDR
	MOV V2, #0x00000001
	STR V2, [V1, #0xC] // write to timer interrupt register
	POP {V1-V5}
	BX LR
	
	
	
// HEX display drivers
// One hot encoded HEX display indices:
// HEX0 = 0x00000001
// HEX1 = 0x00000002
// HEX2 = 0x00000004
// HEX3 = 0x00000008
// HEX4 = 0x00000010
// HEX5 = 0x00000020

// Turns off all the segments of the selected HEX displays.
// pre- A1: selected HEX display indices
HEX_clear_ASM: 
	PUSH {V1-V5}
	MOV V1, #0x00000001 // keep track of which HEX index we are at
	LDR V2, =HEX0_ADDR // store the address of display
	MOV V3, #0 // store the number of times to shift the byte to store at address
	MOV V5, #0b00000000 // cleared HEX display
loop_hex_clear:
	CMP V1, #0x00000040 // stop once we reached past HEX5
	BEQ end_hex_clear
	// test to see if this HEX index is a match
	AND V4, A1, V1 // store bit mask for the HEX display index
	CMP V1, V4
	BNE end_loop_hex_clear // skip this HEX display if not in A1
	// clear the HEX display at correct byte
	STRB V5, [V2, V3]
end_loop_hex_clear:
	LSL V1, V1, #1 // left shift the index once
	ADD V3, V3, #1 // add 4 to shift the bits to store next byte
	CMP V1, #0x00000010 // check if we reached HEX4 to modify address
	BNE loop_hex_clear
	LDR V2, =HEX4_ADDR // jump addresses
	MOV V3, #0 // reset the bit shift counter
	B loop_hex_clear
end_hex_clear:
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
loop_hex_flood:
	CMP V1, #0x00000040 // stop once we reached past HEX5
	BEQ end_hex_flood
	// test to see if this HEX index is a match
	AND V4, A1, V1 // store bit mask for the HEX display index
	CMP V1, V4
	BNE end_loop_hex_flood // skip this HEX display if not in A1
	// flood the HEX display at correct byte
	STRB V5, [V2, V3]
end_loop_hex_flood:
	LSL V1, V1, #1 // left shift the index once
	ADD V3, V3, #1 // add 4 to shift the bits to store next byte
	CMP V1, #0x00000010 // check if we reached HEX4 to modify address
	BNE loop_hex_flood 
	LDR V2, =HEX4_ADDR // jump addresses
	MOV V3, #0 // reset the bit shift counter
	B loop_hex_flood
end_hex_flood:
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
loop_hex_write:
	CMP V1, #0x00000020 // stop once we reached past HEX5
	BGT end_hex_write
	// test to see if this HEX index is a match
	AND V4, A1, V1 // store bit mask for the HEX display index
	CMP V1, V4
	BNE end_loop_hex_write // skip this HEX display if not in A1
	// update the HEX display at correct byte
	STRB A2, [V2, V3]
end_loop_hex_write:
	LSL V1, V1, #1 // left shift the index once
	ADD V3, V3, #1 // add 1 to shift the bits to store next byte
	CMP V1, #0x00000010 // check if we reached HEX4 to modify address
	BNE loop_hex_write 
	LDR V2, =HEX4_ADDR // jump addresses
	MOV V3, #0 // reset the bit shift counter
	B loop_hex_write
end_hex_write:
	POP {V1-V5}
	BX LR