.global _start
_start: br Start  # begin at the main program

# ==========================================
# ECE3221 LAB4 - Display Updates using Interrupts
# -----------------------------------------------
# DATE: March 20th, 2025  NAME: Will Ross #3734692
# DATE: March 20th, 2025  NAME: Alex Cameron #3680202
# -----------------------------------------------
# The LCD display will be used to display ASCII
# -----------------------------------------------
# PORT MAP
# 0x8870 - DECADE
# 0x88B0 - HEXCONTROL
# 0x88A0 - HEXDISPLAY
# 0x8880 - REDLEDS
# 0x88C0 - LCD
# 0x8850 - SW
# -----------------------------------------------

# ==========================================
# macro definitions (push/pop) at the top
# ------------------------------------------

.macro push rx
	addi sp, sp, -4
	stw \rx, 0(sp)
.endm

.macro pop rx
	ldw \rx, 0(sp)
	addi sp, sp, 4
.endm

# ==========================================
# Global Variables
# ------------------------------------------

.equ N, 		    400
.equ lcd,		    0x000088C0 	   # LCD Control
.equ DECADE,		0x00008870     # Decade Timer
.equ DECADECONTROL, 0x000088E0     # Decade Control
.equ REDLEDS,		0x00008880 	   # Red leds
.equ HEXCONTROL,	0x000088B0 	   # display hex digits
.equ SWITCHES, 		0x00008850 	   # switches
.equ HEX, 		    0x000088A0     # display hex digits


# ==========================================
# interrupt service routine (ISR)
# ------------------------------------------
.org 0x0020	 # ISR code lies at this address
ISR:
	push ra
	push r3
	push r4

	# determine source of interrupt
	# ------------------------------------

	rdctl r3, ipending		# r3 = pending an interrupt bit
	andi r4, r3, 0x04		# r4 = pending the 2nd lsb
	bne r4, r0, int2		# if (r4 != 0 ) then call int2
    
	br endint

	# ****************************
	# IRQ2 service (decade timer)
	int2:
		call action2		# the action done for an interrupt

		movia r4, 0x8870	# r4 = the address of the decade register
		sthio r0, 12(r4)	# clear the interrupt request
		br endint			# call endint
	
	endint:
		pop r4
		pop r3
		pop ra

		addi ea, ea, -4 	# adjusting the interrupt return address
		eret				# done 
		


# ==========================================
# main program (after the ISR)               
# ------------------------------------------
.org 0x0100	 # code lies at this address

Start:
	call init       # initialization
    ori r8, r0, SWITCHES    # r8 = address of the switches
    call clrscr
    call outstr
    # Comment out when showing the strings printing out 
    call clrscr



here:	
   # ldwio r3, (r8)		    #load values of switches to r3
	ori r3, r0, 0x180		# cursor to top line
	call outchr
	ldwio r3, (r8)		    # load values of switches to r3
	call out16bin
	ori r3, r0, 0x1C0		# cursor to bottom
	call outchr
	ldwio r3, (r8)		    # load values of switches to r3
	call outhex4
	call out5int
	
	andi r4,r4,0
	or r4,r0,r3

	br here
 
# ==========================================
# --- to here comment out 

# ==========================================
# subroutines  (after main code)                  
# ------------------------------------------

# ==========================================
# init - subroutines for initiation of stack and address controls
# ------------------------------------------
init:
	ori sp, r0, stacktop			# init stack pt

	# push onto stack
	push r3
	push r4
    push r20
    push r22
    push r5

	# Hex display logic (turn on  HEX3 - HEX0)
	ori r5, r0, HEXCONTROL		# r5 = address of the hex displays
	ori r4, r0, 0x1FF				# r4 = 1111 to for hex 3 - 0
	stwio r4, (r5)				# load r5 with r4 (turn on the displays)


/*    	ori r3,r0,DECADECONTROL
    	ori r4,r0,0
    	stwio r4,(r3)            		# start decade timer
    	ori r5,r0,0xF            		# no buttons pressed

  */

    # SETUP INTERRUPTS IN THREE STEPS 1,2,3
    # ------------------
	# Decade timer logic
    # (1) enable interrupt generation on 100 Hz edge in the decade timer
    ori r22, r0,  DECADE	        # r22 = address of the decade timer
	ori r3, r0, 0b00001000	    # r4 = set lsb to enable interrupts
	stbio r3, 8(r22)			# load r4 with r22
    # ------------------

    # ienable interrupt logic
    # (2) recognize INT2 (decade timer) in the processor
    rdctl r3, ienable
    ori r3, r3, 0x00000004      # int2 = bit2
    wrctl ienable, r3           # int2 will now be understood by cpu
    # ------------------

    # status interrupt logic
    # (3) turn on master interrupt enable in the processor
    rdctl r3, status            # read the status into r3
    ori r3, r3, 0x01            # get lsb
    wrctl status, r3            # ISR can be called on enabled intrups
	# ------------------



	# pop off stack
    pop r5
    pop r22
    pop r20
	pop r4
	pop r3
	ret


# ==========================================
# outchr - Outputs to the LCD display a single ASCII character in r3. (allow for 9-bit input)
# ------------------------------------------
outchr:
    push ra
    push r3
    push r4
    push r5

    andi r4, r3, 0x001FF            # r4 = make sure we allow for 9-bit
    ori r4, r4, 0x0600              # enable high

    ori r5, r0, lcd                 # write the address of LCD
    sthio r4, 0(r5)                 # write to the LCD

    ori r3, r0, 5                   # the delay in ms
    call delayN

    andi r4, r4, 0x05FF             # enable low
    ori r5, r0, lcd                 # write the address of LCD
    sthio r4, 0(r5)                 # write to lcd

    ori r3, r0, 5                   # delay 
    call delayN

    xor r4, r4, r4                  # r4 = find the bit
    ori r5, r0, REDLEDS             # address of the LEDSs
    sthio r4, 0(r5)                 # load the value of r4 to red leds


    pop r5
    pop r4
    pop r3
    pop ra
    ret

# ==========================================
# outspc - Outputs a space character (0x20) to the LCD display.
# ------------------------------------------
outspc:
    push r3
    push ra

    ori r3, r0, 0x20            # ascii code for a space
    call outchr                # call `outchr` to send the space char to be written

    pop ra
    pop r3
    ret 

# ==========================================
# delayN - Does nothing but returns after a delay of N msec where N is provided in r3.
# ------------------------------------------
delayN:
    push r3
    push r4
    push r5

    ori r4, r0, 20           		# 2 msec
    bge r3, r4, maxvalue
    br max_skip

    maxvalue:
        ori r3, r0, 20          # set the max value to 0xFFFF

    max_skip:
        ori r5, r0, DECADE
    
    falling_edge:
        ldwio r4, (r5)              # load the value of the decade to r4
        andi r4, r4, 4              # get the 4 lsb

        beq r4, r0, falling_edge    # if (r4 == 0 ) loop back 
        addi r3, r3, -1              # decrement the time

        beq r3, r0, done_delay      # if (r3 == 0) then done
    
    rising_edge:
        ldwio r4, (r5)              # load r5 value into r4
        andi r4, r4, 4              # get the 4 lsb
        bne r4, r0, rising_edge     # if (r4 != 0) loop on rising edge until returned to 0
        br falling_edge
    
    done_delay:
        pop r5
        pop r4
        pop r3
        ret



# ==========================================
# clrscr - Clears the LCD screen and moves the cursor to the top line by sending the command character 0x101, followed by a short delay while the clearing operation completes.
# ------------------------------------------
clrscr:

    push r3
    push r5
    push ra

    ori r3,r0,0x101         # command to clear the screen
	call outchr             
	call delayN


    pop ra
    pop r5
    pop r3
    ret

# ==========================================
# outhex - Outputs to the LCD display one ASCII character being the hexadecimal representation of the 4 least significant bits in r3
# ------------------------------------------
outhex:
    push ra
	push r5
	push r3


    ori r5, r0, hex               # gets the hex address
    andi r3,r3, 0xf               # r3 anded with 1111
	add r5,r5,r3                  # add r5 + r3
	ldb r3,(r5)                   # load r3 with r5
	call outchr


    pop r3
    pop r5
    pop ra
    ret

# ==========================================
# out16bin - Outputs to the LCD display 16 characters ‘0’ or ‘1’ being the binary representation of the 16-bit contents of r3.
# ------------------------------------------
out16bin:
	push ra
	push r3
	push r7
	push r8

    ori r2, r0, 16              # init loop count to 16
    ori r4, r0, 0x8000          # init mask to start with bit 15

    outbin16_loop:
        beq r8, r0, out16bin_done			# check if ran through all values
        andi r3, r7, 0b1000000000000000	    # get the msb, since reads backwards
        srli r3, r3, 15
        addi r3, r3, 0x30		            # add 30 to get ascii value
        slli r7, r7, 1 		                # Shift right one time
        addi r8, r8, -1		                # add one to counter
        call outchr
        br outbin16_loop

    out16bin_done: 
        pop r8
        pop r7
        pop r3
        pop ra
        ret

# ==========================================
# outhex4 - Outputs to the LCD display ‘0’ and ‘x’ followed by 4 characters being the hexadecimal representation of the 16-bit contents of r3
# ------------------------------------------
outhex4:
    push ra
    push r3
    push r4
    push r5

    or r5,r0,r3                 # set r5 to r3
    andi r3,r3,0x0		        # set r3 to 0
	ori r4,r0,0x04
	ori r3,r0,0x3d		        # set r3 to '=' in ascii
	call outchr

    call outspc

    andi r3,r3,0x0		# set r3 to 0
	ori r3,r0,0x30		# set r3 to '0' in ascii
	call outchr

	andi r3,r3,0x0		# set r3 to 0
	ori r3,r0,0x78		# set r3 to 'x' in ascii
	call outchr

    outhex4_loop:
        andi r3, r5, 0xf000	# find first 4 digits
        srli r3, r3, 12
        call outhex
        slli r5, r5, 4	    # shift to 4 new digits
        addi r4, r4, -1	    # decrement counter
        bne r4, r0, outhex4_loop # if ( r4 != 0) loop

        pop r5
        pop r4
        pop r3
        pop ra
        ret 

# ==========================================
# out5int - Outputs to the LCD display five ASCII characters being the 5-digit decimal representation of the 16-bit contents of r3.
# ------------------------------------------
out5int:
    push r3
	push r4
	push r5
	push r6
	push r7
	push ra


	or r5,r0,r3		                # loads r3 in r5
    call outspc
    andi r3, r0, 0x0000             # clear r3
    ori r3, r0, 0x3d                # ascii value for =
    call outchr                     # write to display


    call outspc

    # for 10000
    ori r4, r0, 10000               # r4 = divide by 10000 to get base 10
    divu r3, r5, r4		            # Gets the quotient copy(r5) / r4 (base)
	mul r6, r3, r4		            # multiply to find remainder
	sub r7, r5, r6		            # get Remainder
	addi r3, r3, 0x30
	call outchr		

    # for 1000
    ori r4, r0, 1000                # r4 = divide by 1000 
	divu r3, r7, r4	                # Gets the quotient copy(r5) / r4 (base)
	mul r6, r3, r4                  # multiply to find remainder
	sub r7, r7, r6                  # get Remainder
	addi r3, r3, 0x30                 
	call outchr		

    # for 100
    ori r4, r0, 100                 # r4 = divide by 1000
	divu r3, r7, r4	                # Gets the quotient copy(r5) / r4 (base)
	mul r6, r3, r4                  # multiply to find remainder
	sub r7, r7, r6                  # get Remainder
	addi r3, r3, 0x30                 
	call outchr		

    # for 10
    ori r4, r0, 10                  # r4 = divide by 10
	divu r3, r7, r4	                # Gets the quotient copy(r5) / r4 (base)
	mul r6, r3, r4                  # multiply to find remainder
	sub r7, r7, r6                  # get Remainder
	addi r3, r3, 0x30                 
	call outchr		


    andi r3,r7,0xF
	addi r3,r3,0x30
	call outchr		

    pop ra
	pop r7
	pop r6
	pop r5
	pop r4
	pop r3
	ret

# ==========================================
# outstr - Outputs to the LCD display a null-terminated ASCII string at the address provided in r3
# ------------------------------------------
outstr:
   
    push ra 
    push r3
    push r5
    
    ori r5, r0, welcome                 # address of string

    outstr_loop:
        ldb r3, (r5)                    # put chars in r3
        beq r3, r0, outstr_loopDone     # if ( r3 == NULL ), break out of loop
        call outchr

        addi r5, r5, 1                  # move to the next char in str
        br outstr_loop                  # while ( r4 != NULL ), loop outstr_loop

    outstr_loopDone:
        pop r5
        pop r3
        ret 

# ==========================================
# action2 - 
# ------------------------------------------
action2:
    push r3
    push r4
    push r5
    push r6

	ori r6, r0, HEX		                # loads adress of hex display
	movia r3, counter

    ldwio r4, (r3)                       # load the r3 value to r4
    addi r4, r4, 1                      # add 1 to r4
    stwio r4, (r3)                      # send that signal back to r4
    stwio r4, (r6)                      # send it to the hex

    pop r6
    pop r5
    pop r4
    pop r3
    ret


# ==========================================
# data storage (after all code)
# ------------------------------------------        
# reserve 400 bytes = 100 words for stack     

.skip 400 
        
stacktop:

counter: .word 0

# ------------------------------------------
# stored strings

welcome: .asciz "Welcome to Lab 4"
# Uncomment for AAAA
# welcome: .asciz "AAAA"
hex: .ascii "0123456789ABCDEF"
# ------------------------------------------
