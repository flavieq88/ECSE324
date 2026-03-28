PB_int_flag: .word 0x0
tim_int_flag: .word 0x0

.section .vectors, "ax"
B _start            // reset vector
B SERVICE_UND       // undefined instruction vector
B SERVICE_SVC       // software interrupt vector
B SERVICE_ABT_INST  // aborted prefetch vector
B SERVICE_ABT_DATA  // aborted data vector
.word 0             // unused vector
B SERVICE_IRQ       // IRQ interrupt vector
B SERVICE_FIQ       // FIQ interrupt vector

.text

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

.equ TIMER_ADDR, 0xFFFEC600 // address of A9 private timer

RATES: 
	.word 12500000, 25000000, 50000000, 100000000, 200000000 // 1/16, 1/8, 1/4, 1/2, 1 s 

WORD_08: // characters for word 0x08
	.byte 0b00000111, 0b00111111, 0b01110111, 0b01011110 // 7, 0, A, d
	.byte 0b01101101, 0b00000111, 0b00111111, 0b00111111 // 5, 7, 0, 0
	.byte 0b00000110, 0b01101101 // 1, 5
.space 2 // endure memory aligned
N_08: .word 10 // length of word 0x08

WORD_10: // characters for word 0x10
	.byte 0b00111001, 0b01110111, 0b01110001, 0b01111001 // C, A, F, E
	.byte 0b00000000, 0b01111100, 0b01111001, 0b01111001 // space, b, E, E
	.byte 0b01110001, 0b00000000, 0b00111001, 0b00111111 // F, space, C, 0
	.byte 0b01110001, 0b01110001, 0b01111001, 0b01111001 // F, F, E, E
N_10: .word 16 // length of word 0x10

.global _start


_start:
    /* Set up stack pointers for IRQ and SVC processor modes */
    MOV R1, #0b11010010      // interrupts masked, MODE = IRQ
    MSR CPSR_c, R1           // change to IRQ mode
    LDR SP, =0xFFFFFFFF - 3  // set IRQ stack to A9 on-chip memory
    /* Change to SVC (supervisor) mode with interrupts disabled */
    MOV R1, #0b11010011      // interrupts masked, MODE = SVC
    MSR CPSR, R1             // change to supervisor mode
    LDR SP, =0x3FFFFFFF - 3  // set SVC stack to top of DDR3 memory
    BL  CONFIG_GIC           // configure the ARM GIC
    // NOTE: write to the pushbutton KEY interrupt mask register
    // Or, you can call enable_PB_INT_ASM subroutine from previous task
	// to enable interrupt for ARM A9 private timer, 
    // use ARM_TIM_config_ASM subroutine
    LDR R0, =0xFF200050      // pushbutton KEY base address
    MOV R1, #0xF             // set interrupt mask bits
    STR R1, [R0, #0x8]       // interrupt mask register (base + 8)
    // enable IRQ interrupts in the processor
    MOV R0, #0b01010011      // IRQ unmasked, MODE = SVC
    MSR CPSR_c, R0
	
	// variables
	MOV V1, #1 // store if characters are moving
	MOV V2, #0 // store direction of movement: 0 for left, 1 for right
	MOV V3, #0x00 // store state for HEX display
	MOV V4, #2 // store the speed with 0 being fastest, 4 being slowest
	MOV A4, #0 // store starting byte for long words
	
	// clear all to start initial state
	MOV A1, #0b0000111111
	BL write_LEDs_ASM // setup the LED displays
	BL PB_clear_edgecp_ASM
	BL ARM_TIM_clear_INT_ASM
	LDR A1, =50000000 // timeout = 1/(200MHz) x 50x10^6 = 0.25 sec
	MOV A2, #0b00000111 // enable interrupt, auto and enable bits
	BL ARM_TIM_config_ASM
	
	
IDLE: // poll switches 
    BL read_slider_switches_ASM
	
	CMP A1, #0x00
	BEQ case_C0FFEE
	CMP A1, #0x01
	BEQ case_CAFE5
	CMP A1, #0x02
	BEQ case_CAb5
	CMP A1, #0x04
	BEQ case_ACE
	CMP A1, #0x08
	BEQ case_08
	CMP A1, #0x10
	BEQ case_10
	
	B case_invalid // branches if nothing matches

case_C0FFEE:
	CMP A1, V3 // check if message has changed
	BEQ service_PBs
	// otherwise if not changed
	MOV V3, A1 // save new message as the previous message
	BL write_HEX_C0FFEE
	B service_PBs
case_CAFE5:
	CMP A1, V3 // check if message has changed
	BEQ service_PBs
	// otherwise if not changed
	MOV V3, A1 // save new message as the previous message
	BL write_HEX_CAFE5
	B service_PBs
case_CAb5:
	CMP A1, V3 // check if message has changed
	BEQ service_PBs
	// otherwise if not changed
	MOV V3, A1 // save new message as the previous message
	BL write_HEX_CAb5
	BL service_PBs
	B IDLE
case_ACE:
	CMP A1, V3 // check if message has changed
	BEQ service_PBs
	// otherwise if not changed
	MOV V3, A1 // save new message as the previous message
	BL write_HEX_ACE
	B service_PBs
case_08:
	CMP A1, V3 // check if message has changed
	BEQ service_PBs
	// otherwise if not changed
	MOV V3, A1 // save new message as the previous message
	MOV A4, #0 // write first 6 chars
	MOV A1, A4
	BL write_HEX_08
	B service_PBs
case_10:
	CMP A1, V3 // check if message has changed
	BEQ service_PBs
	// otherwise if not changed
	MOV V3, A1 // save new message as the previous message
	MOV A4, #0 // write first 6 chars
	MOV A1, A4
	BL write_HEX_10
	B service_PBs
case_invalid:
	MOV V3, A1 // save switch state as previous state
	BL clear_HEX // reset message display
    B service_PBs 
	
service_PBs:
	LDR A1, =PB_int_flag // read the flag
	LDR V5, [A1]
	CMP V5, #0
	BEQ check_timer // skip these if no interrupts
	// reset flag
	MOV V7, #0
	STR V7, [A1]
	
CHECK_PB0:
	MOV V7, #0x1
	ANDS V7, V7, V5 // check for KEY0
	BEQ CHECK_PB1
	// PB0 was pressed
	// check if paused
	CMP V1, #1
	BNE IDLE
	// make movement slower 
	CMP V4, #4
	BEQ check_timer // don't do anything if already at min speed
	ADD V4, V4, #1
	LDR V7, =RATES
	// configure timer to use new rate 
	LDR A1, [V7, V4, LSL #2] // get new rate
	MOV A2, #0b00000111 // enable interrupt, auto and enable bits
	BL ARM_TIM_config_ASM
	B update_LEDs

CHECK_PB1:
	MOV V7, #0x2
	ANDS V7, V7, V5 // check for KEY1
	BEQ CHECK_PB2
	// PB1 was pressed
	// check if paused
	CMP V1, #1
	BNE IDLE
	// make movement faster
	CMP V4, #0
	BEQ check_timer // don't do anything if already at max speed
	SUB V4, V4, #1
	LDR V7, =RATES
	// configure timer to use new rate 
	LDR A1, [V7, V4, LSL #2] // get new rate
	MOV A2, #0b00000111 // enable interrupt, auto and enable bits
	BL ARM_TIM_config_ASM
	B update_LEDs

update_LEDs:
	CMP V4, #0
	LDREQ A1, =0b1111111111
	CMP V4, #1
	MOVEQ A1, #0b0011111111
	CMP V4, #2
	MOVEQ A1, #0b0000111111
	CMP V4, #3
	MOVEQ A1, #0b0000001111
	CMP V4, #4
	MOVEQ A1, #0b0000000011
	BL write_LEDs_ASM
	B check_timer
	
CHECK_PB2:
	MOV V7, #0x4
	ANDS V7, V7, V5 // check for KEY2
	BEQ IS_PB3
	// PB2 was pressed
	// check if paused
	CMP V1, #1
	BNE IDLE
	// reverses direction of movement
	CMP V2, #0
	MOVEQ V2, #1
	MOVNE V2, #0
	// update LEDs
	B check_timer

IS_PB3:
	// PB3 was pressed
	// pause or resume character movement
	CMP V1, #0
	// want to restart
	MOVEQ V1, #1
	BEQ update_LEDs
	// want to pause
	MOVNE V1, #0
	// clear LEDs
	MOV A1, #0b0000000000
	BL write_LEDs_ASM
	B check_timer

check_timer: 
	LDR V5, =tim_int_flag // check the flag
	LDR V7, [V5]
	CMP V7, #1 // 1 if interrupt happened
	BNE IDLE
	// if interrupt did happen, reset flag
	MOV V7, #0
	STR V7, [V5]
	// check if characters are supposed to move
	CMP V1, #1
	BNE IDLE
	// otherwise, make the characters rotate
	CMP V2, #0
	// check if it is a long word
	BEQ case_shift_left
	BNE case_shift_right

case_shift_left:
	// check if it is a long word
	CMP V3, #0x08
	BNE left_10
	// if yes, shift left means the starting index is one bigger
	ADD A4, A4, #1 // add one
	// if went over the limit, go back to 0
	LDR A3, =N_08
	LDR A3, [A3]
	CMP A4, A3
	MOVGE A4, #0 // if over the limit
	MOV A1, A4
	BL write_HEX_08
	B IDLE
left_10:
	CMP V3, #0x10
	BNE short_word_left
	// if yes, shift left means the starting index is one bigger
	ADD A4, A4, #1 // add one
	// if went over the limit, go back to 0
	LDR A3, =N_10
	LDR A3, [A3]
	CMP A4, A3
	MOVGE A4, #0 // if over the limit
	MOV A1, A4
	BL write_HEX_10
	B IDLE
short_word_left:	
	BL shift_HEX_left
	B IDLE

case_shift_right:
	// check if it is a long word
	CMP V3, #0x08
	BNE right_10
	// if yes, shift right means the starting index is one smaller
	SUB A4, A4, #1 // substract one
	// if went under 0, go back to highest
	LDR A3, =N_08
	LDR A3, [A3]
	CMP A4, #0
	ADDLT A4, A4, A3
	MOV A1, A4
	BL write_HEX_08
	B IDLE
right_10:
	CMP V3, #0x10
	BNE short_word_right
	// if yes, shift right means the starting index is one smaller
	SUB A4, A4, #1 // substract one
	// if went under 0, go back to highest
	LDR A3, =N_10
	LDR A3, [A3]
	CMP A4, #0
	ADDLT A4, A4, A3
	MOV A1, A4
	BL write_HEX_10
	B IDLE
short_word_right:
	BL shift_HEX_right
	B IDLE



CONFIG_GIC:
    PUSH {LR}
/* To configure the FPGA KEYS interrupt (ID 73):
* 1. set the target to cpu0 in the ICDIPTRn register
* 2. enable the interrupt in the ICDISERn register */
/* CONFIG_INTERRUPT (int_ID (R0), CPU_target (R1)); */
/* NOTE: you can configure different interrupts
   by passing their IDs to R0 and repeating the next 3 lines */
    MOV R0, #73            // KEY port (Interrupt ID = 73)
    MOV R1, #1             // this field is a bit-mask; bit 0 targets cpu0
    BL CONFIG_INTERRUPT
	
	MOV R0, #29            // KEY port (Interrupt ID = 73)
    BL CONFIG_INTERRUPT

/* configure the GIC CPU Interface */
    LDR R0, =0xFFFEC100    // base address of CPU Interface
/* Set Interrupt Priority Mask Register (ICCPMR) */
    LDR R1, =0xFFFF        // enable interrupts of all priorities levels
    STR R1, [R0, #0x04]
/* Set the enable bit in the CPU Interface Control Register (ICCICR).
* This allows interrupts to be forwarded to the CPU(s) */
    MOV R1, #1
    STR R1, [R0]
/* Set the enable bit in the Distributor Control Register (ICDDCR).
* This enables forwarding of interrupts to the CPU Interface(s) */
    LDR R0, =0xFFFED000
    STR R1, [R0]
    POP {PC}

/*
* Configure registers in the GIC for an individual Interrupt ID
* We configure only the Interrupt Set Enable Registers (ICDISERn) and
* Interrupt Processor Target Registers (ICDIPTRn). The default (reset)
* values are used for other registers in the GIC
* Arguments: R0 = Interrupt ID, N
* R1 = CPU target
*/
CONFIG_INTERRUPT:
    PUSH {R4-R5, LR}
/* Configure Interrupt Set-Enable Registers (ICDISERn).
* reg_offset = (integer_div(N / 32) * 4
* value = 1 << (N mod 32) */
    LSR R4, R0, #3    // calculate reg_offset
    BIC R4, R4, #3    // R4 = reg_offset
    LDR R2, =0xFFFED100
    ADD R4, R2, R4    // R4 = address of ICDISER
    AND R2, R0, #0x1F // N mod 32
    MOV R5, #1        // enable
    LSL R2, R5, R2    // R2 = value
/* Using the register address in R4 and the value in R2 set the
* correct bit in the GIC register */
    LDR R3, [R4]      // read current register value
    ORR R3, R3, R2    // set the enable bit
    STR R3, [R4]      // store the new register value
/* Configure Interrupt Processor Targets Register (ICDIPTRn)
* reg_offset = integer_div(N / 4) * 4
* index = N mod 4 */
    BIC R4, R0, #3    // R4 = reg_offset
    LDR R2, =0xFFFED800
    ADD R4, R2, R4    // R4 = word address of ICDIPTR
    AND R2, R0, #0x3  // N mod 4
    ADD R4, R2, R4    // R4 = byte address in ICDIPTR
/* Using register address in R4 and the value in R2 write to
* (only) the appropriate byte */
    STRB R1, [R4]
    POP {R4-R5, PC}

/*--- Undefined instructions --------------------------------------*/
SERVICE_UND:
    B SERVICE_UND
/*--- Software interrupts ----------------------------------------*/
SERVICE_SVC:
    B SERVICE_SVC
/*--- Aborted data reads ------------------------------------------*/
SERVICE_ABT_DATA:
    B SERVICE_ABT_DATA
/*--- Aborted instruction fetch -----------------------------------*/
SERVICE_ABT_INST:
    B SERVICE_ABT_INST
/*--- IRQ ---------------------------------------------------------*/
SERVICE_IRQ:
    PUSH {R0-R7, LR}
/* Read the ICCIAR from the CPU Interface */
    LDR R4, =0xFFFEC100
    LDR R5, [R4, #0x0C] // read from ICCIAR
/* NOTE: Check which interrupt has occurred (check interrupt IDs)
   Then call the corresponding ISR
   If the ID is not recognized, branch to UNEXPECTED
   See the assembly example provided in the DE1-SoC Computer Manual
   on page 46 */
Interrupt_check:
	CMP R5, #73
	BEQ Pushbutton_check
	CMP R5, #29
	BEQ Timer_check
	B UNEXPECTED
Pushbutton_check:
    BL KEY_ISR
	B EXIT_IRQ
Timer_check:
    BL ARM_TIM_ISR
	B EXIT_IRQ // ??????????????
UNEXPECTED:
    BNE UNEXPECTED      // if not recognized, stop here
	
EXIT_IRQ:
/* Write to the End of Interrupt Register (ICCEOIR) */
    STR R5, [R4, #0x10] // write to ICCEOIR
    POP {R0-R7, LR}
    SUBS PC, LR, #4
/*--- FIQ ---------------------------------------------------------*/
SERVICE_FIQ:
    B SERVICE_FIQ

KEY_ISR:
	PUSH {LR, V1-V5}
    LDR V1, =PB_EDGE_ADDR
    LDR V2, =PB_int_flag
    LDR V1, [V1] // read edge capture register
    STR V1, [V2] // save in flag
    MOV R2, #0xF
    BL PB_clear_edgecp_ASM // clear the interrupt
    POP {LR, V1-V5}
    BX LR
	
ARM_TIM_ISR:
	PUSH {LR, V1-V5}
    LDR V1, =tim_int_flag
	MOV V2, #1
    BL ARM_TIM_read_INT_ASM
    STR V2, [V1] // write 1 into the flag
    BL ARM_TIM_clear_INT_ASM // clear interrupt
    POP {LR, V1-V5}
    BX LR

	
	

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

// Write 70Ad570015 on HEX displays, six characters starting from nth character
// pre- A1: n'th character to start from (0 for beginning)
write_HEX_08:
	PUSH {LR, V1-V5}
	MOV V4, A1 // store beginning index
	LDR V1, =N_08 // number of characters total
	LDR V1, [V1]
	LDR V2, =WORD_08 // address of first byte
	MOV V3, #0x00000020 // index of HEX, starting at 5
loop_write_08:
	CMP V3, #0x00000001 // CMP with HEX0
	BLT done_write_HEX_08
	MOV A1, V3
	LDRB A2, [V2, V4] // load byte and write
	BL HEX_write_ASM
	LSR V3, V3, #1 // now deincrement HEX index
	ADD V4, V4, #1 // add one to character index
	CMP V4, V1 // reset to 0 if went over the character total
	SUBGE V4, V4, V1
	B loop_write_08
done_write_HEX_08:
	POP {LR, V1-V5}
	BX LR

// Write CAFE bEEF C0FFEE on HEX displays, six characters starting from nth character
// pre- A1: n'th character to start from (0 for beginning)
write_HEX_10:
	PUSH {LR, V1-V5}
	MOV V4, A1 // store beginning index
	LDR V1, =N_10 // number of characters total
	LDR V1, [V1]
	LDR V2, =WORD_10 // address of first byte
	MOV V3, #0x00000020 // index of HEX, starting at HEX5
loop_write_10:
	CMP V3, #0x00000001 // CMP with HEX0
	BLT done_write_HEX_10
	MOV A1, V3
	LDRB A2, [V2, V4] // load byte and write
	BL HEX_write_ASM
	LSR V3, V3, #1 // now deincrement HEX index
	ADD V4, V4, #1 // add one to character index
	CMP V4, V1 // reset to 0 if went over the character total
	SUBGE V4, V4, V1
	B loop_write_10
done_write_HEX_10:
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

// Timer

// Configures the timer.
// pre- A1: load value (initial count value)
//      A2: configuration bits
ARM_TIM_config_ASM:
	PUSH {V1-V5}
	LDR V1, =TIMER_ADDR
	STR A1, [V1] // write initial count value into the timer load register
	STR A2, [V1, #8] // write config bits to control register
	POP {V1-V5}
	BX LR
	
// Returns the "F" value of the timer interrupt status register.
// post- A1: 0x00000000 or 0x00000001 (F bit value)
ARM_TIM_read_INT_ASM:
	PUSH {V1-V5}
	LDR V1, =TIMER_ADDR
	LDR A2, [V1, #0xC] // read timer interrupt register
	AND A2, A2, #0x00000001 // clean up rest of data
	POP {V1-V5}
	BX LR
	
// Clears the "F" value of the timer interrupt status register.
ARM_TIM_clear_INT_ASM:
	PUSH {V1-V5}
	LDR V1, =TIMER_ADDR
	MOV V2, #0x00000001
	STR V2, [V1, #0xC] // write to timer interrupt register
	POP {V1-V5}
	BX LR
	
	
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
