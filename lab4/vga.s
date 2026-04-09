.equ VGA_PIX_ADDR, 0xC8000000
.equ VGA_CHAR_ADDR, 0xC9000000
MAX_PIX_X: .word 319
MAX_PIX_Y: .word 239
MAX_CHAR_X: .word 79
MAX_CHAR_Y: .word 59

.global _start
_start:
        bl      draw_test_screen
end:
        b       end

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
	
	
draw_test_screen:
        push    {r4, r5, r6, r7, r8, r9, r10, lr}
        bl      VGA_clear_pixelbuff_ASM
        bl      VGA_clear_charbuff_ASM
        mov     r6, #0
        ldr     r10, .draw_test_screen_L8
        ldr     r9, .draw_test_screen_L8+4
        ldr     r8, .draw_test_screen_L8+8
        b       .draw_test_screen_L2
.draw_test_screen_L7:
        add     r6, r6, #1
        cmp     r6, #320
        beq     .draw_test_screen_L4
.draw_test_screen_L2:
        smull   r3, r7, r10, r6
        asr     r3, r6, #31
        rsb     r7, r3, r7, asr #2
        lsl     r7, r7, #5
        lsl     r5, r6, #5
        mov     r4, #0
.draw_test_screen_L3:
        smull   r3, r2, r9, r5
        add     r3, r2, r5
        asr     r2, r5, #31
        rsb     r2, r2, r3, asr #9
        orr     r2, r7, r2, lsl #11
        lsl     r3, r4, #5
        smull   r0, r1, r8, r3
        add     r1, r1, r3
        asr     r3, r3, #31
        rsb     r3, r3, r1, asr #7
        orr     r2, r2, r3
        mov     r1, r4
        mov     r0, r6
        bl      VGA_draw_point_ASM
        add     r4, r4, #1
        add     r5, r5, #32
        cmp     r4, #240
        bne     .draw_test_screen_L3
        b       .draw_test_screen_L7
.draw_test_screen_L4:
        mov     r2, #72
        mov     r1, #5
        mov     r0, #20
        bl      VGA_write_char_ASM
        mov     r2, #101
        mov     r1, #5
        mov     r0, #21
        bl      VGA_write_char_ASM
        mov     r2, #108
        mov     r1, #5
        mov     r0, #22
        bl      VGA_write_char_ASM
        mov     r2, #108
        mov     r1, #5
        mov     r0, #23
        bl      VGA_write_char_ASM
        mov     r2, #111
        mov     r1, #5
        mov     r0, #24
        bl      VGA_write_char_ASM
        mov     r2, #32
        mov     r1, #5
        mov     r0, #25
        bl      VGA_write_char_ASM
        mov     r2, #87
        mov     r1, #5
        mov     r0, #26
        bl      VGA_write_char_ASM
        mov     r2, #111
        mov     r1, #5
        mov     r0, #27
        bl      VGA_write_char_ASM
        mov     r2, #114
        mov     r1, #5
        mov     r0, #28
        bl      VGA_write_char_ASM
        mov     r2, #108
        mov     r1, #5
        mov     r0, #29
        bl      VGA_write_char_ASM
        mov     r2, #100
        mov     r1, #5
        mov     r0, #30
        bl      VGA_write_char_ASM
        mov     r2, #33
        mov     r1, #5
        mov     r0, #31
        bl      VGA_write_char_ASM
        pop     {r4, r5, r6, r7, r8, r9, r10, pc}
.draw_test_screen_L8:
        .word   1717986919
        .word   -368140053
        .word   -2004318071