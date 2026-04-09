.equ PS2_ADDR, 0xFF200100

.equ VGA_PIX_ADDR, 0xC8000000
.equ VGA_CHAR_ADDR, 0xC9000000
MAX_PIX_X: .word 319
MAX_PIX_Y: .word 239
MAX_CHAR_X: .word 79
MAX_CHAR_Y: .word 59

.global _start
_start:
        bl      input_loop
end:
        b       end


// PS/2 driver

// Checks the RVALID bit in the PS/2 data register. If valid, data is read and stored
// at the given address data and returns 1. Else, returns 0.
// pre- A1: data address
// post- A1: 0 if RVALID bit is invalid, 1 if valid
read_PS2_data_ASM:
	PUSH {V1-V5, LR}
	MOV V1, A1 // data address
	MOV A1, #0 // initially return 0
	// access RVALID bit
	LDR V2, =PS2_ADDR
	LDR V3, [V2]
	LSR V3, V3, #15
	AND V3, V3, #0x1 // V3 contains RVALID bit
	CMP V3, #0
	BEQ .end_read_PS2_data // end and return if invalid
	// if valid
	MOV A1, #1 // return 1
	LDRB V4, [V2] // get final byte
	STRB V4, [V1] // store in data address
.end_read_PS2_data:
	POP {V1-V5, LR}
	BX LR 


// VGA drivers

// Draws a point on the screen at the specified (x, y) coordinates in the indicated color c.
// Verifies that the given coordinates are valid (x in [0, 319] and y in [0, 239]).
// pre- A1: x coordinate 
//      A2: y coordinate
//      A3: c color 
VGA_draw_point_ASM:
	PUSH {V1-V5, LR}
	// verify that x and y are valid coordinates. If not, do nothing
	CMP A1, #0
	BLT .end_draw_point
	LDR V1, MAX_PIX_X
	CMP A1, V1
	BGT .end_draw_point
	CMP A2, #0
	BLT .end_draw_point
	LDR V1, MAX_PIX_Y
	CMP A2, V1
	BGT .end_draw_point
	// access coordinate and write color in buffer
	LDR V1, =VGA_PIX_ADDR
	LSL V2, A2, #10 // y << 10
	LSL V3, A1, #1 // x << 1
	ORR V2, V2, V3
	ORR V1, V1, V2 // 0xc8000000 | (y << 10) | (x << 1)
	STRH A3, [V1] // 16 bit color 
.end_draw_point:
	POP {V1-V5, LR}
	BX LR 
	
// Clears (sets to 0) all the valid memory locations in the pixel buffer.
VGA_clear_pixelbuff_ASM:
	PUSH {V1-V5, LR}
	// call VGA_draw_point_ASM on all valid x and y coordinates with color 0
	MOV A1, #0 // store x coordinate
	MOV A2, #0 // store y coordinate
	MOV A3, #0 // store color (0 to clear)
	LDR V1, MAX_PIX_X 
	LDR V2, MAX_PIX_Y
	// loop over all valid values of x
.loop_x_clear_pixelbuff:
	CMP A1, V1
	BGT .end_clear_pixelbuff
	// loop over all valid values of y
.loop_y_clear_pixelbuff:
	CMP A2, V2
	BGT .end_loop_y_clear_pixelbuff
	// clear the current (x, y) pixel
	BL VGA_draw_point_ASM
	ADD A2, A2, #1 // increment y coordinate
	B .loop_y_clear_pixelbuff
.end_loop_y_clear_pixelbuff:
	MOV A2, #0 // reset y coordinate 
	ADD A1, A1, #1 // increment x coordinate
	B .loop_x_clear_pixelbuff
.end_clear_pixelbuff:
	POP {V1-V5, LR}
	BX LR 
	
// Writes the ASCII code c to the screen at (x, y) coordinate.
// Checks whether the coordinates supplied are valid (x in [0, 79], y in [0, 59]).
// pre- A1: x coordinate 
//      A2: y coordinate
//      A3: c character 
VGA_write_char_ASM:
	PUSH {V1-V5, LR}
	// verify that x and y are valid coordinates. If not, do nothing
	CMP A1, #0
	BLT .end_write_char
	LDR V1, MAX_CHAR_X
	CMP A1, V1
	BGT .end_write_char
	CMP A2, #0
	BLT .end_write_char
	LDR V1, MAX_CHAR_Y
	CMP A2, V1
	BGT .end_write_char
	// access coordinate and write character in buffer
	LDR V1, =VGA_CHAR_ADDR
	LSL V2, A2, #7 // y << 7
	ORR V2, V2, A1 
	ORR V1, V1, V2 // 0xc9000000 | (y << 7) | x
	STRB A3, [V1] // 1 byte ASCII character 
.end_write_char:
	POP {V1-V5, LR}
	BX LR 

// Clears (sets to 0) all the valid memory locations in the character buffer.
VGA_clear_charbuff_ASM:
	PUSH {V1-V5, LR}
	// call VGA_write_char_ASM on all valid x and y coordinates with char 0
	MOV A1, #0 // store x coordinate
	MOV A2, #0 // store y coordinate
	MOV A3, #0 // store char (0 to clear)
	LDR V1, MAX_CHAR_X 
	LDR V2, MAX_CHAR_Y
	// loop over all valid values of x
.loop_x_clear_charbuff:
	CMP A1, V1
	BGT .end_clear_charbuff
	// loop over all valid values of y
.loop_y_clear_charbuff:
	CMP A2, V2
	BGT .end_loop_y_clear_charbuff
	// clear the current (x, y) char
	BL VGA_write_char_ASM
	ADD A2, A2, #1 // increment y coordinate
	B .loop_y_clear_charbuff
.end_loop_y_clear_charbuff:
	MOV A2, #0 // reset y coordinate 
	ADD A1, A1, #1 // increment x coordinate
	B .loop_x_clear_charbuff
.end_clear_charbuff:
	POP {V1-V5, LR}
	BX LR 



write_hex_digit:
        push    {r4, lr}
        cmp     r2, #9
        addhi   r2, r2, #55
        addls   r2, r2, #48
        and     r2, r2, #255
        bl      VGA_write_char_ASM
        pop     {r4, pc}
write_byte:
        push    {r4, r5, r6, lr}
        mov     r5, r0
        mov     r6, r1
        mov     r4, r2
        lsr     r2, r2, #4
        bl      write_hex_digit
        and     r2, r4, #15
        mov     r1, r6
        add     r0, r5, #1
        bl      write_hex_digit
        pop     {r4, r5, r6, pc}
input_loop:
        push    {r4, r5, lr}
        sub     sp, sp, #12
        bl      VGA_clear_pixelbuff_ASM
        bl      VGA_clear_charbuff_ASM
        mov     r4, #0
        mov     r5, r4
        b       .input_loop_L9
.input_loop_L13:
        ldrb    r2, [sp, #7]
        mov     r1, r4
        mov     r0, r5
        bl      write_byte
        add     r5, r5, #3
        cmp     r5, #79
        addgt   r4, r4, #1
        movgt   r5, #0
.input_loop_L8:
        cmp     r4, #59
        bgt     .input_loop_L12
.input_loop_L9:
        add     r0, sp, #7
        bl      read_PS2_data_ASM
        cmp     r0, #0
        beq     .input_loop_L8
        b       .input_loop_L13
.input_loop_L12:
        add     sp, sp, #12
        pop     {r4, r5, pc}