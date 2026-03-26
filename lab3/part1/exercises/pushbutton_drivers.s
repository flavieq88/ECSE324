.global _start
.equ PUSHBUTTON_ADDR, 0xFF200050

_start:
	B test_is_pressed_data
end:
	B end
	
test_read: // test read_PB_data_ASM
	BL read_PB_data_ASM
	B test_read
	
test_is_pressed_data:
	MOV A1, #0x0004 // should only return 1 when PB2 is pressed
	BL PB_data_is_pressed_ASM
	B end


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
	LDR V1, =PUSHBUTTON_ADDR
	LDR A1, [V1] // load contents of pushbutton data register. already one hot encoded!
	POP {V1-V5}
	BX LR
	
	
// Receives a pushbutton index and returns 0x00000001 if that pushbutton is pressed.
// pre- A1: index of pushbutton
// post- A1: 0x00000001 if corresponding pushbutton is pressed, 0x00000000 if not
PB_data_is_pressed_ASM:
	PUSH {V1-V5}
	LDR V1, =PUSHBUTTON_ADDR
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
	POP {V1-V5}
	BX LR
	
	
// Receives a pushbutton index as an argument and returns 0x00000001 if that pushbutton has been pressed and released.
// pre- A1: index of pushbutton
// post- A1: 0x00000001 if corresponding pushbutton has been pressed and released, 0x00000000 if not
PB_edgecp_is_pressed_ASM:
	PUSH {V1-V5}
	POP {V1-V5}
	BX LR
	
	
// Clears the pushbutton Edgecapture register.
PB_clear_edgecp_ASM:
	PUSH {V1-V5}
	POP {V1-V5}
	BX LR
	
	
// Receives pushbutton indices and enables the interrupt function for the corresponding pushbuttons,
// by setting the interrupt mask bits to '1'.
// pre- A1: indices of pushbuttons
enable_PB_INT_ASM:
	PUSH {V1-V5}
	POP {V1-V5}
	BX LR
	
	
// Receives pushbutton indices and disables the interrupt function for the corresponding pushbuttons,
// by setting the interrupt mask bits to '0'.
// pre- A1: indices of pushbuttons
disable_PB_INT_ASM:
	PUSH {V1-V5}
	POP {V1-V5}
	BX LR