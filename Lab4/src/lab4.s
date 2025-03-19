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
	andi r4, r3, 0x04		# r4 = pending the 2nd lsb
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
	call init       # initialization
    call outstr     # send welcome

here:	
    # PART 3
    call clrscr             #  call the clear display
    
    # Read switches
    movia r4, SW            # r5 = switches
    ldwio r5, (r4)          # load the switches
    movia r6, SW            # r6 = switches
    stw r5, 0(r6)           # store the state on what the swicthes are
    or r3, r0, r5           # getting the switch vales at the memory add
    # ------------------

    call clrscr             # clear display 
    call out16bin           # send the 16 bits from the switches

    # move the cursor to next line
    ori r3, r0, 0x1C0       # move the cursor to the bottom line
    call outchr             # send the command to the display 
    # ------------------

    # write a = value in ascii
    ori r3, r0, 0x3D        # get = value in ascii
    call outchr             # write to board
    # ------------------

    # write a space value in ascii
    ori r3, r0, 0x20        # get a space value in ascii
	call  outchr	        # write to board
    # ------------------

    # get switch values
	or r3, r0, r5           # getting sw value at memory address
	call  out4hex	        # write to board
	# ------------------

    # write a space value in ascii
	ori r3, r0, 0x20        # get a space value in ascii
	call  outchr	        # write to board
    # ------------------

    # write a = value in ascii
	ori r3, r0, 0x3D        # get = value in ascii
	call  outchr	        # write to board
    # ------------------

    # write a space value in ascii
	ori r3, r0, 0x20        # get a space value in ascii
	call  outchr	        # write to board
    # ------------------

    # get switch values
	or r3, r0, r5           # get switch value at memory add
	call  out5int	        # write to board
    # ------------------

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
    movia r22,  DECADE	        # r22 = address of the decade timer
	ori r3, r0, 0b00001000	    # r4 = set lsb to enable interrupts
	stwio r4, 8(r22)			# load r4 with r22
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

    ori r5, r5, LCD                 # write the address of LCD
    sthio r4, 0(r5)                 # write to the LCD

    ori r3, r0, 2                   # the delay in ms
    call delayN

    andi r4, r4, 0x05FF             # enable low
    ori r5, r0, LCD                 # write the address of LCD
    sthio r4, 0(r5)                 # write to lcd

    ori r3, r0, 2                   # delay 
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
    push ra
    push r3

    ori r3, r0, 0x20            # ascii code for a space
    call outchr                # call `outchr` to send the space char to be written

    pop r3
    pop ra
    ret 

# ==========================================
# delayN - Does nothing but returns after a delay of N msec where N is provided in r3.
# ------------------------------------------
delayN:
    push r4
    push r5

    ori r5, r0, DECADE              # load decade timer


    delay_loop:
        beq r3, r0, delay_end       # if (r3 == 0), end the loop 
    
    falling_edge:
        ldwio r4, 0(r5)              # load the value of the decade to r4
        andi r4, r4, 4              # get the 4 lsb
        beq r4, r0, falling_edge    # if (r4 == 0 ) loop back 
        addi r3, r3 -1              # decrement the time
    
    rising_edge:
        ldwio r4, (r5)              # load r5 value into r4
        andi r4, r4, 4              # get the 4 lsb
        bne r4, r0, rising_edge     # if (r4 != 0) loop on rising edge until returned to 0
        br delay_loop
    
    done_delay:
        pop r5
        pop r4
        ret



# ==========================================
# clrscr - Clears the LCD screen and moves the cursor to the top line by sending the command character 0x101, followed by a short delay while the clearing operation completes.
# ------------------------------------------
clrscr:

    push ra
    push r3

    ori r3, r0, 0x101           # command to clear the screen and restart the cursor
    call outchr                 # call the outchr to clear it 

    ori r3, r0, 0x180           # load the command chat into r3
    call outchr                 # call the outchr

    ori r3, r0, 10              # delay for 10 ms
    call delayN                 # call to action the delay 

    pop r3
    pop ra
    ret

# ==========================================
# outhex - Outputs to the LCD display one ASCII character being the hexadecimal representation of the 4 least significant bits in r3
# ------------------------------------------
outhex:
    push ra
    push r4

    ori r4, r0, 9               # a thresehold for numbers and letters
    andi r3, r3, 0xF            # get 4 lsb
    bgt r3, r4, hex_letter      # if ( r3 > 9) send a letter to the display

    addi r3, r3, 0x30           # if a number add a offset for 0
    br hex_complete             # if done

    hex_letter:
        addi r3, r3, 0x37       # add a offset for A
    
    hex_complete:
        call outchr             # send to outchar 

    pop r4
    pop ra
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
    push r4
    push r5

    mov r4, r3                  # load r4 with r3
    roli r4, r4, 16             # shitf 16 bits
    ori r5, r0, 4               # set counter
    
    ori r4, r0, 0x30            # ascii value for 0
    call outchr                 # write to display

    ori r4, r0, 0x78            # ascii value for x
    call outchr                 # write to the display


    outhex4_loop:
        beq r5, r0, out4hex_done# if (counter is == 0), we are done and can exit 
        roli r4, r4, 4          # shift it 4 bits
        andi r3, r4, 0xF        # mask 4 lsb bits
        addi r5, r5, -1         # subtract 1 
        call outhex             # write to hex
        br outhex4_loop

    outhex4_done:
        pop r5
        pop r4
        pop ra
        ret 

# ==========================================
# out5int - Outputs to the LCD display five ASCII characters being the 5-digit decimal representation of the 16-bit contents of r3.
# ------------------------------------------
out5int:
    push ra 
    push r4
    push r5
    push r6
    push r7
    push r8

    mov r4, r3                      # load r3 into r4
    ori r4, r0, 10000               # r4 = divider which the largest it could be is 10000
    ori r6, r0, 5                   # r6 = counter at 5
    ori r7, r0, 10                  # r7 is divider at 10

    out5int_loop:
        beg r6, r0, out5int_done    # if (r6 == 0), done

        divu r3, r4, r5             # divide r3 = r4/r5
        mul r8, r5, r3              # put value in r8
        sub r4, r4, r8              # subtract r8 from r4

        divu r5, r5, r7             # divide r5 by 10
        addi r3, r3, 0x30           # offset for 0
        call outchr                 # write to dosplay

        addi r6, r6, -1             # subtract one form count
        br out5int_loop

    out5int_done:
        pop r8
        pop r7
        pop r6
        pop r5
        pop r4
        pop ra
        ret

# ==========================================
# outstr - Outputs to the LCD display a null-terminated ASCII string at the address provided in r3
# ------------------------------------------
outstr:
    push ra
    call clrscr
    pop ra

    
    push r3
    push r4
    
    ori r4, r0, welcome                 # address of string

    outstr_loop:
        ldb r3, (r4)                    # put chars in r3
        beq r3, r0, outstr_loopDone     # if ( r3 == NULL ), break out of loop

        push ra
        call outchr                     # write the data to teh display 
        pop ra

        addi r4, r4, 1                  # move to the next char in str
        br outstr_loop                  # while ( r4 != NULL ), loop outstr_loop

    outstr_loopDone:
        pop r4
        pop r3
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
sw: .word 0
# ------------------------------------------
# stored strings

welcome: .asciz “Welcome to Lab 4”

# ------------------------------------------
