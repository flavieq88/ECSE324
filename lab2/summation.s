// int a[4] = {1, 2, 3, 4};
matrixA: .word 1, 2, 3, 4
lengthA: .word 4

// int b[8] = {2, 3, 5, 7, 11. 13, 17, 19};
matrixB: .word 2, 3, 5, 7, 11, 13, 17, 19
lengthB: .word 8

// we will save our results here
results: .space 8


.global _start

// Summation
// Sum the integers in the given array
// pre-- A1: address of array
// pre-- A2: length of array
// post- A1: sum of elements

sum:
	// push registers used onto the stack
	PUSH {V1-V3}
	MOV V1, #0 // use V1 to accumulate sum
	MOV V2, #0 // use V2 to store index
	
sumIter: // for (int index=0; index<length; index++)
	SUBS V3, V2, A2 // check if index < length => branch if index - length >= 0
	BGE sumDone
	LDR V3, [A1], #4 // get element of array and post increment
	ADD V1, V1, V3
	ADD V2, V2, #1 // index++
	B sumIter
	
sumDone:
	MOV A1, V1 // save result into A1 to return it
	POP {V1-V3}
	BX LR // return

_start:
	LDR A1, =matrixA
	LDR A2, lengthA
	BL sum
	LDR V1, =results
	STR A1, [V1]  // save answer in A1 at results+0
	
	LDR A1, =matrixB
	LDR A2, lengthB
	BL sum
	LDR V1, =results
	STR A1, [V1, #4]  // save answer in A1 at results+4
	
inf:
	B inf // stop with infinite loop
	