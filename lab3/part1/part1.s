.global _start

.equ SW_ADDR, 0xFF200040 // memory location for slider switch data
.equ LED_ADDR, 0xFF200000 // memory location for LEDs

HEX_CODES:
	.byte 0b00111111, 0b00000110, 0b01011011, 0b01001111 // 0, 1, 2, 3
	.byte 0b01100110, 0b01101101, 0b01111101, 0b00000111 // 4, 5, 6, 7
	.byte 0b01111111, 0b01101111, 0b01110111, 0b01111100 // 8, 9, A, b
	.byte 0b00111001, 0b01011110, 0b01111001, 0b01110001 // C, d, E, F
.equ HEX0_ADDR, 0xFF200020 // address starting at HEX0 display
.equ HEX4_ADDR, 0xFF200030 // address starting at HEX4 display

.equ PB_DATA_ADDR, 0xFF200050 // address of pushbutton data register
.equ PB_INTR_ADDR, 0xFF200058 // address of pushbutton interruptmask register
.equ PB_EDGE_ADDR, 0xFF20005C // address of pushbutton edgecapture register

 
_start:
	// set up initial state
	MOV V1, #0 // store the number of times message has changed 
	MOV V2, #0 // store direction of movement: 0 for left, 1 for right
	MOV V3, #0x00 // store pattern that is being displayed (initial switches state)
	LDR V4, =0x3FF // 1023 for max LED count
	BL write_HEX_C0FFEE // set HEX displays to COFFEE
	MOV A1, V1 
	BL write_LEDs_ASM // clear the LED displays
	BL PB_clear_edgecp_ASM
	BL disable_PB_INT_ASM

poll_loop:
	// check what text should be displayed
	BL read_slider_switches_ASM
	CMP A1, V3 // check if it has changed
	BEQ done_write // skip to next step if message is not changed
	
	MOV V3, A1 // save new message as the previous message
	CMP A1, #0x00
	BEQ case_C0FFEE
	CMP A1, #0x01
	BEQ case_CAFE5
	CMP A1, #0x02
	BEQ case_CAb5
	CMP A1, #0x04
	BEQ case_ACE
	
	B invalid_switch // branches if nothing matches

case_C0FFEE:
	BL write_HEX_C0FFEE
	MOV V1, #0 // reset LED message count
	B done_write
case_CAFE5:
	BL write_HEX_CAFE5
	MOV V1, #0 // reset LED message count
	B done_write
case_CAb5:
	BL write_HEX_CAb5
	MOV V1, #0 // reset LED message count
	B done_write
case_ACE:
	BL write_HEX_ACE
	MOV V1, #0 // reset LED message count
	B done_write
	
done_write:
	// now read edgecap pushbuttons
	// read PB2 and to see if it has been pushed and released
	MOV A1, #0x00000004
	BL PB_edgecp_is_pressed_ASM
	BNE read_PB3 // if equal to 0, did not get pressed and released
	// otherwise, change direction
	CMP V2, #0
	MOVEQ V2, #1
	MOVNE V2, #0
	B done_PBs
	
read_PB3: 
	// read PB3 and to see if it has been pushed and released
	MOV A1, #0x00000008
	BL PB_edgecp_is_pressed_ASM
	BNE done_PBs // if equal to 0, did not get pressed and released
	// otherwise, shift left or right
	CMP V2, #0
	BLEQ shift_HEX_left
	BLNE shift_HEX_right
	CMP V1, V4
	ADDLT V1, V1, #1 // update number of rotations
	BL PB_clear_edgecp_ASM // clear edgecapture registers after actions have been taken care of
	
done_PBs:
	MOV A1, V1
	BL write_LEDs_ASM // update LEDs display
	B poll_loop
	
invalid_switch:
	// reset LED count
	BL clear_HEX // reset message display
	MOV V1, #0 // reset LED message count
	MOV A1, V1
	BL write_LEDs_ASM // update LEDs display
	
	B poll_loop
	
	
// -------------------------- HELPERS --------------------------

// Write C0FFEE on the HEX displays
write_HEX_C0FFEE:
	PUSH {LR, V1-V5}
	LDR V1, =HEX_CODES
	MOV A1, #0x0000020 // HEX5
	LDRB A2, [V1, #0xC] // C
	BL HEX_write_ASM
	MOV A1, #0x0000010 // HEX4
	LDRB A2, [V1] // 0
	BL HEX_write_ASM
	MOV A1, #0x000000C // HEX3 and HEX2
	LDRB A2, [V1, #0xF] // F
	BL HEX_write_ASM
	MOV A1, #0x0000003 // HEX1 and HEX0
	LDRB A2, [V1, #0xE] // E
	BL HEX_write_ASM
	POP {LR, V1-V5}
	BX LR
	
// Write CAFE5 on the HEX displays, left justified
write_HEX_CAFE5:
	PUSH {LR, V1-V5}
	LDR V1, =HEX_CODES
	MOV A1, #0x0000020 // HEX5
	LDRB A2, [V1, #0xC] // C
	BL HEX_write_ASM
	MOV A1, #0x0000010 // HEX4
	LDRB A2, [V1, #0xA] // A
	BL HEX_write_ASM
	MOV A1, #0x0000008 // HEX3
	LDRB A2, [V1, #0xF] // F
	BL HEX_write_ASM
	MOV A1, #0x0000004 // HEX2
	LDRB A2, [V1, #0xE] // E
	BL HEX_write_ASM
	MOV A1, #0x0000002 // HEX1
	LDRB A2, [V1, #0x5] // 5
	BL HEX_write_ASM
	MOV A1, #0x0000001 // HEX0
	BL HEX_clear_ASM
	POP {LR, V1-V5}
	BX LR
	
// Write CAb5 on the HEX displays, left justified
write_HEX_CAb5:
	PUSH {LR, V1-V5}
	LDR V1, =HEX_CODES
	MOV A1, #0x0000020 // HEX5
	LDRB A2, [V1, #0xC] // C
	BL HEX_write_ASM
	MOV A1, #0x0000010 // HEX4
	LDRB A2, [V1, #0xA] // A
	BL HEX_write_ASM
	MOV A1, #0x0000008 // HEX3
	LDRB A2, [V1, #0xB] // b
	BL HEX_write_ASM
	MOV A1, #0x0000004 // HEX2
	LDRB A2, [V1, #0x5] // 5
	BL HEX_write_ASM
	MOV A1, #0x0000003 // HEX1 and HEX0
	BL HEX_clear_ASM
	POP {LR, V1-V5}
	BX LR
	
// Write ACE on the HEX displays, left justified
write_HEX_ACE:
	PUSH {LR, V1-V5}
	LDR V1, =HEX_CODES
	MOV A1, #0x0000020 // HEX5
	LDRB A2, [V1, #0xA] // A
	BL HEX_write_ASM
	MOV A1, #0x0000010 // HEX4
	LDRB A2, [V1, #0xC] // C
	BL HEX_write_ASM
	MOV A1, #0x0000008 // HEX3
	LDRB A2, [V1, #0xE] // E
	BL HEX_write_ASM
	MOV A1, #0x0000007 // HEX2, HEX1 and HEX0
	BL HEX_clear_ASM
	POP {LR, V1-V5}
	BX LR
	
// Write nothing on the HEX displays
clear_HEX:
	PUSH {LR, V1-V5}
	MOV A1, #0x000003F // all HEX displays
	BL HEX_clear_ASM
	POP {LR, V1-V5}
	BX LR
	
// shift contents of HEX displays to the left
shift_HEX_left:
	PUSH {V1-V5}
	LDR V1, =HEX0_ADDR
	LDR V2, =HEX4_ADDR
	LDRB V3, [V1] // get what is in HEX0 
	LDRB V4, [V2, #1] // get what is in HEX5
	STRB V4, [V1] // write HEX5 to HEX0
	LDRB V5, [V1, #1] // get what is in HEX1
	STRB V3, [V1, #1] // write HEX0 to HEX1
	LDRB V3, [V1, #2] // get what is in HEX2
	STRB V5, [V1, #2] // write HEX1 to HEX2
	LDRB V5, [V1, #3] // get what is in HEX3
	STRB V3, [V1, #3] // write HEX2 to HEX3
	LDRB V3, [V2] // get what is in HEX4
	STRB V5, [V2] // write HEX3 to HEX4
	STRB V3, [V2, #1] // write HEX4 to HEX5
	STRB V4, [V1] // write HEX5 to HEX0	
	POP {V1-V5}
	BX LR

// shift contents of HEX displays to the right
shift_HEX_right:
	PUSH {V1-V5}
	LDR V1, =HEX0_ADDR
	LDR V2, =HEX4_ADDR
	LDRB V3, [V1] // get what is in HEX0 
	LDRB V4, [V2, #1] // get what is in HEX5
	STRB V3, [V2, #1] // write HEX0 to HEX5
	LDRB V3, [V1, #1] // get what is in HEX1
	STRB V3, [V1] // write HEX1 to HEX0
	LDRB V3, [V1, #2] // get what is in HEX2
	STRB V3, [V1, #1] // write HEX2 to HEX1
	LDRB V3, [V1, #3] // get what is in HEX3
	STRB V3, [V1, #2] // write HEX3 to HEX2
	LDRB V3, [V2] // get what is in HEX4
	STRB V3, [V1, #3] // write HEX4 to HEX3
	STRB V4, [V2] // write HEX5 to HEX4
	POP {V1-V5}
	BX LR

	

// -------------------------- DRIVERS --------------------------

// Slider switches driver
// returns the state of slider switches in A1
// post- A1: slide switch state
read_slider_switches_ASM: 
	LDR A2, =SW_ADDR // load address of slider switch state
	LDR A1, [A2] // read slider switch state into A1
	BX LR


// LEDs driver
// writes the state of LEDs (on/off) in A1 to the LED's control register
// pre- A1: data to write to LED state
write_LEDs_ASM: 
	LDR A2, =LED_ADDR // load the address of the LED's state
	STR A1, [A2] // update LED state with the contents of A1
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
	

// Pushbutton drivers	
// One-hot encoding scheme:
// PB0 = 0x00000001
// PB1 = 0x00000002
// PB2 = 0x00000004
// PB3 = 0x00000008

// Returns the indices of the pressed pushbuttons (keys from pushbuttons data register).
// post- A1: indices of pressed pushbuttons based on one-hot encoding scheme
read_PB_data_ASM:
	PUSH {V1-V5}
	LDR V1, =PB_DATA_ADDR
	LDR A1, [V1] // load contents of pushbutton data register. already one hot encoded!
	POP {V1-V5}
	BX LR
	
	
// Receives a pushbutton index and returns 0x00000001 if that pushbutton is pressed.
// pre- A1: index of pushbutton
// post- A1: 0x00000001 if corresponding pushbutton is pressed, 0x00000000 if not
PB_data_is_pressed_ASM:
	PUSH {V1-V5}
	LDR V1, =PB_DATA_ADDR
	LDR V2, [V1] // load contents of pushbutton data register
	// just need to right shift V2 until the selected index is at the end
loop_pb_data_is_pressed:
	CMP A1, #0x0001 // check if chosen index has arrived to last bit yet
	BEQ end_pb_data_is_pressed
	// right shift pushbutton index and result
	LSR A1, A1, #1
	LSR V2, V2, #1
	B loop_pb_data_is_pressed
end_pb_data_is_pressed:
	MOV A1, V2 // store result in A1 to return
	AND A1, A1, #0x0001 // clean up rest of data
	POP {V1-V5}
	BX LR
	
	
// Returns the indices of the pushbuttons that have been pressed and then released.
// Uses the edge bits from the pushbutton's Edgecapture register.
// post- A1: indices of pressed and released pushbuttons
read_PB_edgecp_ASM:
	PUSH {V1-V5}
	LDR V1, =PB_EDGE_ADDR
	LDR A1, [V1] // load contents of pushbutton edgecapture register
	POP {V1-V5}
	BX LR
	
	
// Receives a pushbutton index as an argument and returns 0x00000001 if that pushbutton 
// has been pressed and released.
// pre- A1: index of pushbutton
// post- A1: 0x00000001 if corresponding pushbutton has been pressed and released, 0x00000000 if not
PB_edgecp_is_pressed_ASM:
	PUSH {V1-V5}
	LDR V1, =PB_EDGE_ADDR
	LDR V2, [V1] // load contents of pushbutton edgecapture register
	// just need to right shift V2 until the selected index is at the end
loop_pb_edgecp_is_pressed:
	CMP A1, #0x0001 // check if chosen index has arrived to last bit yet
	BEQ end_pb_edgecp_is_pressed
	// right shift pushbutton index and edgecapture contents
	LSR A1, A1, #1
	LSR V2, V2, #1
	B loop_pb_edgecp_is_pressed
end_pb_edgecp_is_pressed:
	MOV A1, V2 // store result in A1 to return
	AND A1, A1, #0x0001 // clean up rest of data
	POP {V1-V5}
	BX LR
	
	
// Clears the pushbutton Edgecapture register.
PB_clear_edgecp_ASM:
	PUSH {V1-V5}
	LDR V1, =PB_EDGE_ADDR
	LDR V2, [V1] // load contents of pushbutton edgecapture register
	STR V2, [V1] // write back contents of edgecapture register to clear
	POP {V1-V5}
	BX LR
	
	
// Receives pushbutton indices and enables the interrupt function for the corresponding pushbuttons,
// by setting the interrupt mask bits to '1'.
// pre- A1: indices of pushbuttons
enable_PB_INT_ASM:
	PUSH {V1-V5}
	LDR V1, =PB_INTR_ADDR
	LDR V2, [V1] // store the current interrupt mask
	ORR V2, V2, A1 // turn on if was not turned on previously for given indices, leave others unchanged
	STR V2, [V1]
	POP {V1-V5}
	BX LR
	
	
// Receives pushbutton indices and disables the interrupt function for the corresponding pushbuttons,
// by setting the interrupt mask bits to '0'.
// pre- A1: indices of pushbuttons
disable_PB_INT_ASM:
	PUSH {V1-V5}
	LDR V1, =PB_INTR_ADDR
	LDR V2, [V1] // store the current interrupt mask
	MVN V3, A1 // complement of the indices. Those who want to be disabled will be 0
	AND V2, V2, V3 // turn off if index is given, leave others unchanged
	STR V2, [V1]
	POP {V1-V5}
	BX LR