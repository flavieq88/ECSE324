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
	PUSH {LR} // A1=N, A2=address for answer
	
	MOV V4, #0 // keep track of index i
	MOV V5, A1 // save N
	
	MOV V1, #0 // store prev value
	MOV V2, #0 // store first possible number rnums
	MOV V3, #0 // store second possible number rnuma
	
	STRB V1, [A2] // initialize the 0th recaman number as 0
	
	
for_loop:
	ADD V4, V4, #1
	CMP V4, V5 // if i - N <= 0
	BGT end
	
	// calculate two possible next numbers
	SUBS V2, V1, V4
	ADD V3, V1, V4
	
	// check rnums > 0 and not already in the sequence
	BLE else
	// perform search (rnums, array, num-1)
	MOV A1, V2 
	SUB A3, V4, #1
	BL search
	CMP A1, #0 // results of search in A1
	BGE else
	STRB V2, [A2, V4] // store rnums at array[num]
	MOV V1, V2 // update prev
	B for_loop
	
else:
	STRB V3, [A2, V4] // store rnuma at array[num]
	MOV V1, V3 // update prev
	B for_loop

end:
	MOV A1, V1 // return prev
	POP {LR}
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
	
