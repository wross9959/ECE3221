.global _start
_start: br Start  # begin at the main program

/* ECE3221 LAB #4 - SUBROUTINES AND INTERRUPTS                      
----------------------------------------------- 
DATE: March 22, 2024	  NAME: Olivia Gerry Rice
----------------------------------------------- 
LCD display will be used to display ASCII 
characters and strings.
-----------------------------------------------
*/

# ==========================================
# macro definitions (push/pop) at the top
# ------------------------------------------

.macro push rx
	addi sp ,sp ,-4
	stw \rx ,0(sp)
.endm

.macro pop rx
	ldw \rx ,0(sp)
	addi sp ,sp ,4
.endm

# ==========================================
# Initializing constants
# ------------------------------------------

# Initializing constants
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

	rdctl r3,ipending # r3 = pending interrupt bits
	andi r4,r3,0x04 # r4 = pending int2 bit
	bne r4,r0,int2 # service int2 if necessary
	br endint # or done (nothing to do)

	# ****************************
	# IRQ2 service (decade timer)
int2:
	call action2 	# provide a specific response to the timer interrupt
			# DO NOT MODIFY ANY REGISTERS
			# timer interrupt request is done
	movia r4,0x8870 # r4 = addr of decade timer
 	sthio r0,12(r4) # clear interrupt request
	br endint 	# done
	# ****************************
	# ------------------------------------
endint:
	pop r4
	pop r3
	pop ra
	addi ea,ea,-4 # adjust interrupt return address
	eret # done!
# ==========================================
# main program (after the ISR)               
# ------------------------------------------
.org 0x0100	 		# code lies at this address

Start:
	call init 		# initialization
	call outstr		# sends welcome message to the LCD

here:	
	
	call clrscr		# clear screen
	
	## READING SWITCHES ##
	ori r4, r0, SW	
	ldwio r5, (r4)	# r5 = state of switches
	ori r6, r0, SW	# r6 = memory address reserved for storing the state of switches
	stw r5, 0(r6)	# storing state of switches in memory
	or r3, r0, r5   # getting sw value at memory address
	
	call clrscr	# clear screen
	call out16bin   # sends 16 bits from switches to Line1 of the LCD display
	
	ori   r3, r0, 0x1C0	# command character to move cursor to bottom line
    	call  outchr	    	# call outchr subroutine to send the command character
	
	### ON BOTTOM LINE ####

	ori r3, r0, 0x3D  # getting '=' value in ascii
	call  outchr	  # sending to board
	ori r3, r0, 0x20  # getting ' ' value in ascii
	call  outchr	  # sending to board

	or r3, r0, r5     # getting sw value at memory address
	call  out4hex	  # sending to board
	
	ori r3, r0, 0x20  # getting ' ' value in ascii
	call  outchr	  # sending to board
	ori r3, r0, 0x3D  # getting '=' value in ascii
	call  outchr	  # sending to board
	ori r3, r0, 0x20  # getting ' ' value in ascii
	call  outchr	  # sending to board

	or r3, r0, r5     # getting sw value at memory address
	call  out5int	  # sending to board

	br here   	# the entire main program in here!!
 
# ==========================================


# ==========================================
# subroutines  (after main code)                  
# ------------------------------------------
init:
	ori sp, r0, stacktop      # initalize stack pointer

	push r3
	push r4

	ori r3, r0, HEXCONTROL    
	ori r4, r0, 0x1FF 	  # set all hex displays to on           
	stwio r4, (r3)            # display ON, HEXDISPLAY 0-3 ON.    
    
	#----------------------------------------------
	
	# SETUP INTERRUPTS IN THREE STEPS 1,2,3
	# (1) enable interrupt generation on 100 Hz edge in the decade timer

	ori r22, r0, DECADE
	ori r3, r0, 0b00001000 	# select 100 Hz output (bit 3)
	stbio r3, 8(r22) 	# bit 3 will now cause timer interrupt (INT2)

	# (2) recognize INT2 (decade timer) in the processor

	rdctl r3, ienable
	ori r3, r3, 0x00000004 	# INT2 = bit2 = 1
	wrctl ienable, r3 	# INT2 will now be recognized by the processor

	# (3) turn on master interrupt enable in the processor

	rdctl r3, status
	ori r3, r3, 0x01 	# PIE bit = 1
	wrctl status, r3 	# ISR will now be called on enabled interrupts (COMMENT THIS TO STOP INTERRUPTS)
	
	#----------------------------------------------

    	pop r4
    	pop r3

        ret
# ------------------------------------------
# Send a character to the LCD  	
#    input: R3 = char (9-bits) 	
# affected: none 			

# bits 7..0 = data    
# bit 9 = 1 = command 
# bit 9 = 0 = ascii   
# bit10 = enable
# bit11 = LCD ON

outchr:
	 
	push ra
	push r3
	push r4
	push r5

	# ------------------------------------ 

	andi  r4, r3, 0x001FF 	# keep 9 data bits 

	ori   r4, r4, 0x0600 	# enable high (and lcd ON)	

	ori   r5, r0, LCD
	sthio r4, 0(r5)    	# write to lcd 

	ori   r3, r0, 5		# N ms delay   
	call  delayN

	andi  r4, r4, 0x05FF 	# enable low (and LCD ON)  	
	ori   r5, r0, LCD
	sthio r4, 0(r5)    	# write to lcd 
	
	ori   r3, r0, 5		# N ms delay
	call  delayN

	xor   r4, r4, r4		
	ori   r5, r0, REDLEDS 
	sthio r4, 0(r5)    

	# ------------------------------------ 

	pop r5
	pop r4
	pop r3
	pop ra

	ret

# ------------------------------------------
# Does nothing but returns after a delay of N msec where N is provided in r3.  	
#    input: r3	
# affected: none 			

delayN:
	push r4
	push r5
	
	ori r5, r0, DECADE		# Load decade timer address

delay_loop:
	beq r3, r0, delay_end		# Check if delay is reached

decade_rising:
	ldwio r4, 0(r5)			# Check timer
	andi r4, r4, 4			# Isolate 1ms bit (bit 2)
	beq r4, r0, decade_rising	# If 0, keep waiting for 1
	addi r3, r3, -1			# Otherwise, decrement counter

delay_falling:
	ldwio r4, 0(r5)			# Repeat check timer
	andi r4, r4, 4			# Repeat isolate bit 2
	bne r4, r0, delay_falling	# If 1, keep waiting for 0
	br delay_loop			# Otherwise, check if time reached

delay_end:
	
	pop r5
	pop r4

	ret

# ------------------------------------------
# Outputs to the LCD diplay 16 characters '0' or '1' being the 
# binary representation of the 16-bit contents of r3.
#    input: r3	
# affected: none 

out16bin:
	push ra
	push r4
	push r5
	
	mov r4, r3		# Load r3 into r4
	roli r4, r4, 16
	ori r5, r0, 16		# Set counter in r5

bit_loop:
	beq r5, r0, done_binout	# If counter is 0, jump to end
	
	roli r4, r4, 1		# Roll r4 left
	andi r3, r4, 1		# Isolate bit 0 (was bit 15)
	addi r5, r5, -1		# Decrement r5
	beq r3, r0, bit_zero	# Check 0 or 1
	
	ori r3, r0, 0x31	# If 1, load '1' (0x31) into r3
	call outchr		# Send to outchr
	br bit_loop
	
bit_zero:
	ori r3, r0, 0x30	# If 0, load '0' (0x30) into r3
	call outchr		# Send to outchr
	br bit_loop

done_binout:
	pop r5
	pop r4
	pop ra

	ret

# ------------------------------------------
# outputs to the LCD one ASCII character being the hexadecimal 
# representation of the 4 least significant bits of r3.
#    input: r3	
# affected: none 

outhex: 
	push ra
	push r4

	ori r4, r0, 9		# Threshold between numbers and letters
	andi r3, r3, 0xF	# Isolate 4 LSBs of input r3
	bgt r3, r4, hex_letter	# If greater than 9, send a letter
	
	addi r3, r3, 0x30	# For number: add offset for '0'
	br done_outhex		# Jump to end
	
hex_letter:
	addi r3, r3, 0x37	# For letter: add offset for 'A'

done_outhex:
	call outchr		# Send with outchr
	
	pop r4
	pop ra

	ret

# ------------------------------------------
# send 16-bits in r3 to the hex display
#    input: r3	
# affected: none 

out4hex:
	push ra
	push r4
	push r5
	
	mov r4, r3		# Load r3 into r4
	roli r4, r4, 16
	ori r5, r0, 4		# Set counter in r5
	
	ori r3, r0, 0x30	# Load '0' into r3
	call outchr		# Send with outchr
	ori r3, r0, 0x78	# Load 'x' into r3
	call outchr		# Send with outchr
	
hex_loop:
	beq r5, r0, done_4hex	# Check if ounter is 0
	roli r4, r4, 4		# Roll r4 left 4 bits
	andi r3, r4, 0xF	# Load 4 LSBs of r4 into r3
	addi r5, r5, -1		# Decrement counter
	call outhex		# Send with outchr
	br hex_loop		# Repeat

done_4hex:
	pop r5
	pop r4
	pop ra
	
	ret 

# ------------------------------------------  
# outputs to the LCD display five ASCII characters being the 
# 5-digit decimal representation of the 16-bit contents of r3.
#    input: r3	
# affected: none 

out5int:
	push ra
	push r4
	push r5
	push r6
	push r7
	push r8
	
	mov r4, r3		# Load r3 into r4
	ori r5, r0, 10000	# Load largest order of dec digit into r5
	ori r6, r0, 5		# Start counter at 5
	ori r7, r0, 10		# Divisor 10 into r7

int5_loop:
	beq r6, r0, done_5int	# If counter is 0, done
	divu r3, r4, r5 	# Store quotient of r4/r5 into r3
	mul r8, r5, r3		# Put value of digit into r8
	sub r4, r4, r8		# Subtract r8 from r4

	divu r5, r5, r7		# Divide r5 by 10
	addi r3, r3, 0x30	# Offset for '0' (0x30)
	call outchr		# Send with outchr

	addi r6, r6, -1		# Decrement Counter
	br int5_loop		# Repeat

done_5int:
	pop r8
	pop r7
	pop r6
	pop r5
	pop r4
	pop ra

	ret

# ------------------------------------------ 

action2:
	
	push r3
	push r4
	push r5

	ori r3, r0, counter   
	ori r5, r0, HEXDISPLAY   
	ldw r4, 0(r3)		  # loading value stored at counter address
	addi r4, r4, 1		  # increment counter by 1
	stw r4, 0(r3)		  # store value back to counter
	stwio r4, (r5)
	
	pop r5
	pop r4
	pop r3

	ret

# ------------------------------------------  
# Clears the LCD screen and moves the cursor to the top line by sending the command character
# 0x101, followed by a short delay while the clearing operation completes. 
#    input: r3	
# affected: none 

clrscr:
	push ra
	push r3
	
	ori r3, r0, 0x101	# Load command char into r3
	call outchr		# Send with outchar

	ori r3, r0, 0x180	# Load command char into r3
	call outchr		# Send with outchar
		
	ori r3, r0, 10		# Load 10 msec value into r3
	call delayN		# Send to delay
	
	pop r3
	pop ra
	
	ret

# ------------------------------------------

# Outputs to the LCD display a null-terminated ASCII string at the address provided in r3.
#    input: r3
# affected: none

outstr:		
	push ra	
	call clrscr
	pop ra
	push r4
	push r3
	ori r4, r0, welcome		# r4 = address of string 
	cont:
		ldb r3, (r4)		# places a character from string into r3
		beq r3, r0, done	# if the character is a null character, stop iterating
		push ra
		call outchr		# displays character on LCD
		pop ra
		addi r4, r4, 1		# r4++ => go to the next character
		br cont
	done:
		
		pop r4
		pop r3			# make r3 point to the initial address again
		
	ret
# ------------------------------------------

outspc:
	push ra
	push r3
 
	ori r3, r0, 0x20 # r3 = ASCII hex for space
	call outchr
 
	pop r3
	pop ra
	ret

# ==========================================
# data storage (after all code)
      
# reserve 400 bytes = 100 words for stack     

.skip 400 
        
stacktop:

counter: .word 0

sw: .word 0	#allocating space for storing state of switches

# ------------------------------------------
# stored strings

welcome: .asciz "Welcome to Lab 4"

# ------------------------------------------
