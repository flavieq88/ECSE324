N: .word 4
matrix: .short 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15
vector: .space 32 // initialized to 0

.global _start

_start:
	LDR A1, N // store matrix dimension in V1
	LDR A2, =matrix // store matrix address in V2
	LDR A3, =vector // store vector address in V3
	
	MOV V1, #0 // store the element index of vector (seq)
	MOV V2, #0 // store the row index
	MOV V3, #0 // store the column index
	MOV V4, #1 // store direction (dir): 1 for up/right, -1 for down/left
	
loop: 
	// continue loop if seq < N*N
	MLS V5, A1, A1, V1 // V5 := (V1 - A1*A1)
	CMP V5, #0
	BGE stop
	
	// copy current element into vector
	MLA V5, A1, V2, V3 // V5 := V3 + A1*V2 to get offset for matrix (row*N + col)
	LSL V5, V5, #1
	LDRH V7, [A2, V5] // get matrix[row][column] halfword
	LSL V5, V1, #1
	STRH V7, [A3, V5] // store into vector[seq] (LSL since halfwords so 2*seq bytes)
	
	// update row and col
	
	SUB V7, A1, #1 // V7 stores N-1
	
	// moving up and right
	CMP V4, #1 // if dir == 1
	BNE downleft
	
	CMP V3, V7 // if col == n-1
	BNE elseif1
	// we're at the right edge, down and turn
	ADD V2, V2, #1 // row++
	MOV V4, #-1 // dir = -1
	B endloop
elseif1:
	CMP V2, #0
	BNE else1
	// we're along the top, right and turn
	ADD V3, V3, #1 // col++
	MOV V4, #-1 // dir = -1
	B endloop
else1: 
	// we're in the middle, continue
	ADD V3, V3, #1 // col++
	SUB V2, V2, #1 // row--
	B endloop

downleft: 
	// moving down and left
	CMP V2, V7 // if row == n-1
	BNE elseif2
	// we're at the bottom, right and turn
	ADD V3, V3, #1 // col++
	MOV V4, #1 // dir = 1
	B endloop
elseif2: 
	// we're at the left edge, down and turn
	CMP V3, #0 // if col == 0
	BNE else2
	ADD V2, V2, #1 // row++
	MOV V4, #1 // dir = 1
	B endloop
else2:
	// we're in the middle, continue
	SUB V3, V3, #1 // col--
	ADD V2, V2, #1 // row++

	
endloop:
	ADD V1, V1, #1 // seq++
	B loop
	
stop:
	B stop