.global _start
_start: br Start  # begin at the main program

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

.equ DECADE, 0x8870
.equ HEXCONTROL, 0x88B0
.equ HEXDISPLAY, 0x88A0
.equ REDLEDS, 0x8880
.equ LCD, 0x88C0
.equ SW, 0x8850


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
	addi r4, r3, 0x04		# r4 = pending the 2nd lsb
	bne r4, r0, int2		# if (r4 != 0 ) then call int2
    
	br endint

	# ****************************
	# IRQ2 service (decade timer)
	int2:
		call action2		# the action done for an interrupt

		movia r4, DECADE	# r4 = the address of the decade register
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
	call init # initialization

here:	
    # PART 2
    call clrscr             #  call the clear display
    ori r3, r0, welcome     # save the ascii array

    br here                 # the entire main program!!
 
# ==========================================


# ==========================================
# subroutines  (after main code)                  
# ------------------------------------------

# ==========================================
# init - subroutines for initiation of stack and address controls
# ------------------------------------------
init:
	movia sp, stacktop			# init stack pt

	# push onto stack
	push r3
	push r4

	# Hex display logic (turn on  HEX3 - HEX0)
	movia r3, HEXCONTROL		# r3 = address of the hex displays
	movia r4, 0x1FF				# r4 = 1111 to for hex 3 - 0
	stwio r4, (r3)				# load r3 with r4 (turn on the displays)


    # SETUP INTERRUPTS IN THREE STEPS 1,2,3
    # ------------------
	# Decade timer logic
    # (1) enable interrupt generation on 100 Hz edge in the decade timer
    moiva r22,  DECADE	        # r22 = address of the decade timer
	ori r3, r0, 0b00001000	    # r4 = set lsb to enable interrupts
	stwio r4, 8(r22)			# load r4 with r22
    # ------------------

    # ienable interrupt logic
    # (2) recognize INT2 (decade timer) in the processor
    rdctl e3, ienable
    ori r3, r3, 0x00000004      # int2 = bit2
    wrctl ienable, r3           # int2 will now be understood by cpu
    # ------------------

    # status interrupt logic
    # (3) turn on master interrupt enable in the processor
    rdctl r3, status            # read the status into r3
    ori r3, r3, 0x01            # get lsb
    wrctl status, r3            # ISR can be called on enabled intrups
	# ------------------

	# button logic
	movia r5, 0xF				# r5 = when no button is pressed

	# pop off stack
	pop r4
	pop r5
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

    ori r5, r5, LCD                 # write the address of LCD
    sthio r4, 0(r5)                 # write to the LCD

    ori r3, r0, 5                   # the delay in ms
    call delayN

    xor r4, r4, r4                  # r4 = find the bit
    ori r5, r0, REDLEDS             # address of the LEDSs
    sthio r4, 0(r5)                 # load the value of r4 to red leds


    pop r5
    pop r4
    pop ra
    ret

# ==========================================
# outspc - Outputs a space character (0x20) to the LCD display.
# ------------------------------------------
outspc:
    ori r3, r0, 0x20            # ascii code for a space
    call outchr                # call `outchr` to send the space char to be written

    ret 

# ==========================================
# delayN - Does nothing but returns after a delay of N msec where N is provided in r3.
# ------------------------------------------
delayN:
    push r3
    push r4
    push r5

    ori r4, r0, 10000               # delay to 10 seconds
    bge r3, r4, maxvalue            # if (r3 == 10sec)
    br max_skip

    maxvalue:
        ori r3, r0, 10000           # reset r3 to 10 seconds
    
    max_skip:
        ori r5, r0, DECADE          # r5 = decade address
    
    falling_edge:
        ldwio r4, (r5)              # load the value of the decade to r4
        andi r4, r4, 4              # get the 4 lsb
        beq r4, r0, falling_edge    # if (r4 == 0 ) loop back 

        addi r3, r3 -1              # decrement the time
        beq r3, r0, done_delay      # if (r3 == 0) then delay is done
    
    rising_edge:
        ldwio r4, (r5)              # load r5 value into r4
        andi r4, r4, 4              # get the 4 lsb
        bne r4, r0, rising_edge     # if (r4 != 0) loop on rising edge until returned to 0
    
    done_delay:
        pop r5
        pop r4
        pop r3
        ret



# ==========================================
# clrscr - Clears the LCD screen and moves the cursor to the top line by sending the command character 0x101, followed by a short delay while the clearing operation completes.
# ------------------------------------------
clrscr:

    push ra
    push r3

    ori r3, r0, 0x101           # command to clear the screen and restart the cursor
    call outchr                # call the outchr to clear it 
    ori r3, r0, 10              # delay for 10 ms
    call delayN                 # call to action the delay 

    pop r3
    pop ra
    ret

# ==========================================
# outhex - Outputs to the LCD display one ASCII character being the hexadecimal representation of the 4 least significant bits in r3
# ------------------------------------------
outhex:
    push r3
    push r4

    ori r4, r0, HEX             # load r4 with hex address
    andi r3, r3, 0xFFFF         # load a value for all F
    stwio r3, (r4)              # send FFFF to hex

    pop r4
    pop r3
    ret

# ==========================================
# out16bin - Outputs to the LCD display 16 characters ‘0’ or ‘1’ being the binary representation of the 16-bit contents of r3.
# ------------------------------------------
out16bin:
    push ra
    push r2
    push r4

    ori r2, r0, 16              # init loop count to 16
    ori r4, r0, 0x8000          # init mask to start with bit 15

    outbin16_loop:
        andi r5, r3, r4         # get the current bit
        srli r5, r5, 15         # shift the bit to lsb 
        addi r5, r5, 0x30       # convert to ascii (0 or 1)
        call outchr            # send the data to display 

        slli r4, r4, 1          # shift the mask to the next bit

        addi r2, r2, -1         # decrement the loop by 1
        bnez r2, out16bin_loop  # while (r2 > 0), loop on outbin16_loop

        pop r4
        pop r2
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

    slli r3, r3, 4              # r3 shift to get the bit to write
    
    ori r4, r0, 0x30            # ascii value for 0
    call outchr                # write to display

    ori r4, r0, 0x78            # ascii value for x
    call outchr                # write to the display

    ori r5, r0, 4               # set loop to 4

    outhex4_loop:
        srl r3, r3, 4           # shift it 4 bits
        andi r3, r3, 0xF        # mask 4 lsb bits
        call outhex             # write to hex

        subi r5, r5, 1          # subtract one from count
        bnez r5, outhex4_loop   # while ( r5 > 0 ), loop on outhex4_loop

        pop r5
        pop r4
        pop r3
        pop ra
        ret 

# ==========================================
# out5int - Outputs to the LCD display five ASCII characters being the 5-digit decimal representation of the 16-bit contents of r3.
# ------------------------------------------
out5int:
    push ra 
    push r3
    push r4

    ori r4, r0, 10000               # r4 = divider which the largest it could be is 10000
    ori r3, r0, 5                   # r3 = counter at 5

    out5int_loop:
        divu r5, r3, r4             # divide rr5 = r3/r4
        mfhi r5                     # store quotient
        addi r5, r5, 0x30           # convert to ascii
        call outchr                 # write to display

        subi r3, r3, 1              # subtract one from the counter
        bnez r3, out5int_loop       # while (r3 > 0), loop on out5int_loop

        pop r4
        pop r3
        pop ra
        ret

# ==========================================
# outstr - Outputs to the LCD display a null-terminated ASCII string at the address provided in r3
# ------------------------------------------
outstr:
    push ra
    push r3
    push r4
    push r5

    outstr_loop:
        ldub r4, (r3)                   # load the byte from the address
        beq r4, r0, outstr_loopDone     # if ( r4 == NULL ), break out of loop

        call outchr                     # write the data to teh display 
        addi r3, r3, 1                  # move to the next char in str
        br outstr_loop                  # while ( r4 != NULL ), loop outstr_loop

    outstr_loopDone:
        pop r5
        pop r4
        pop r5
        pop ra
        ret 

# ==========================================
# action2 - 
# ------------------------------------------
action2:
    push r3
    push r4
    push r5

    ori r3, r0, counter                 # set r3 to teh counter
    ori r5, r0, HEXDISPLAY              # r5 = hexdisplay reg

    lwd r4, 0(r3)                       # load the r3 value to r4
    addi r4, r4, 1                      # add 1 to r4
    stw r4, 0(r3)                       # send that signal back to r4
    stwio r4, (r5)                      # send it to the hex

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

welcome: .asciz “Welcome to Lab 4”

# ------------------------------------------
