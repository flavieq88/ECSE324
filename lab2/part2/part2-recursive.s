.global _start

N: 		.word 20 // input parameter n
SEQ: 	.space 21 // Recaman sequence of n+1 elements
		.space 3 // for correct alignment of instructions
		
_start:
	LDR A1, N // get the input parameter num
	LDR A2, =SEQ // get the address for results
	BL recaman 
	
stop: 
	B stop
	
recaman:
	PUSH {V1-V5, LR} // A1 = num, A2 = array
	CMP A1, #0
	BNE recursive_case
	// base case: num = 0
	MOV A4, #0 // move return value into A4 temporarily
	STRB A4, [A2]  
	B end_recaman

recursive_case:
	MOV V1, #0 // store prev value
	MOV V2, #0 // store first possible number rnums
	MOV V3, #0 // store second possible number rnuma
	MOV V4, A1 // num
	MOV V5, A2 // address
	
	// calculate recaman(num-1, array)
	SUB A1, V4, #1
	BL recaman
	MOV V1, A1 // A1 holds the return value of recaman.
	
	// calculate the two possible next numbers
	SUBS V2, V1, V4
	ADD V3, V1, V4
	
	// check rnums > 0 and not already in the sequence
	BLE else
	// perform search
	MOV A1, V2 
	SUB A3, V4, #1
	BL search
	CMP A1, #0 // results of search in A1
	BGE else
	
	MOV A1, V2 // return value is rnums
	STRB A1, [V5, V4] // store rnums at array[num]
	B end_recaman
else:
	MOV A1, V3 // return value is rnuma
	STRB A1, [V5, V4] // store rnuma at array[num]
	MOV A4, A1
	
	
end_recaman:
	// A4 holds return value temporarily
	POP {V1-V5, LR}
	BX LR

search:
	PUSH {V1-V4, LR}
	// assume A1 = tgt, A2 = array address and A3 = size
	MOV V1, #-1 // idx
	MOV V2, #-1 // store index i
loop:
	ADD V2, V2, #1
	CMP V2, A3  
	BGE end_loop
	LDRB V3, [A2, V2] // get array[i]
	CMP V3, A1 // if array[i] = tgt
	BNE loop
	MOV V1, V2 // idx = i return value
	
end_loop:
	MOV A1, V1
	POP {V1-V4, LR} // restore values
	BX LR
	

