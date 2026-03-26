.global _start
.equ PB_DATA_ADDR, 0xFF200050 // address of pushbutton data register
.equ PB_INTR_ADDR, 0xFF200058 // address of pushbutton interruptmask register
.equ PB_EDGE_ADDR, 0xFF20005C // address of pushbutton edgecapture register

_start:
	B test_interrupts
end:
	B end
	
test_read: // test read_PB_data_ASM
	BL read_PB_data_ASM
	B test_read
	
test_is_pressed_data: // test PB_data_is_pressed_ASM
	MOV A1, #0x0004 // should only return 1 when PB2 is pressed
	BL PB_data_is_pressed_ASM
	B end

test_interrupts:
	MOV A1, #0x000F // should enable interrupt for all
	BL enable_PB_INT_ASM
	MOV A1, #0x000F // should disable interrupt for all
	BL disable_PB_INT_ASM
	MOV A1, #0x000C // should enable interrupt for PB3 and PB2
	BL enable_PB_INT_ASM
	MOV A1, #0x0002 // should enable interrupt for PB1 (in addition)
	BL enable_PB_INT_ASM
	MOV A1, #0x0002 // should disable interrupt for PB1 only
	BL disable_PB_INT_ASM
	MOV A1, #0x000F // should disable interrupt for all
	BL disable_PB_INT_ASM
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