.global _start
.equ PUSHBUTTON_ADDR, 0xFF200050

_start:
	B test_read_pb
	
	
test_read_pb: // test read_PB_data_ASM
	BL read_PB_data_ASM
	B test_read_pb
	
	
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