.global _start
_start: br Start  # begin at the main program

# ==========================================
# macro definitions (push/pop) at the top
# ------------------------------------------
.macro push rx
addi sp,sp,-4
stw \rx,0(sp)
.endm

.macro pop rx
ldw \rx,0(sp)
addi sp,sp,4
.endm

.equ N, 		    400
.equ lcd,		    0x000088C0 	#LCD Control
.equ DECADE,		0x00008870  #Decade Timer
.equ DECADECONTROL, 0x00088E0   Decade Control
.equ REDLEDS,		0x00008880 	#Red leds
.equ HEXCONTROL,	0x000088B0 	#display hex digits
.equ SWITCHES, 		0x00008850 	#switches
.equ HEX, 		    0x000088A0
# ==========================================
# interrupt service routine (ISR)
# ------------------------------------------
ISR:
# ==========================================
# interrupt service routine (ISR)
.org 0x0020 # code lies at this address

	push ra
	push r3
	push r4

	# determine source of interrupt
	# ------------------------------------
	rdctl r3,ipending		# r3 = pending interrupt bits
	andi r4,r3,0x04 		# r4 = pending int2 bit
	bne r4,r0,int2 			# service int2 if necessary
	br endint 			# or done (nothing to do)
	# ****************************
	# IRQ2 service (decade timer)
int2:
	call action2 			# provide a specific response to the timer interrupt
					# DO NOT MODIFY ANY REGISTERS
					# timer interrupt request is done
	movia r4,0x8870 		# r4 = addr of decade timer
	sthio r0,12(r4) 		# clear interrupt request
	br endint 			# done
	# ****************************
	# ------------------------------------
endint:
	pop r4
	pop r3
	pop ra
	addi ea,ea,-4 			# adjust interrupt return address
	eret 				# done!
# ==========================================

# ==========================================
# main program (after the ISR)               
# ------------------------------------------
.org 0x0100	 # code lies at this address

Start:
	call init # initialization
	ori r8,r0,SWITCHES	#loading the address of switches
	call clrscr
	call outstr
	call clrscr
top:
	#ldwio r3,(r8)		#load values of switches to r3
	ori r3,r0,0x180		#cursor to top line
	call outchr
	ldwio r3,(r8)		#load values of switches to r3
	call out16bin
	ori r3,r0,0x1C0		#cursor to bottom
	call outchr
	ldwio r3,(r8)		#load values of switches to r3
	call out4hex
	call out5int
	
	andi r4,r4,0
	or r4,r0,r3

	br top

	
# ==========================================


# ==========================================
# subroutines  (after main code)                  
# ------------------------------------------

init:
    ori sp,r0,stacktop        		# initalize stack pointer

    	push r3
    	push r4
    	push r20
 	push r22
	push r5

    	ori r5,r0,HEXCONTROL    
    	ori r4,r0,0x1ff            
    	stwio r4,(r5)            		# display ON, HEX all ON.    
    
/*    	ori r3,r0,DECADECONTROL
    	ori r4,r0,0
    	stwio r4,(r3)            		# start decade timer
    	ori r5,r0,0xF            		# no buttons pressed

  */


	# SETUP INTERRUPTS IN THREE STEPS 1,2,3
	# (1) enable interrupt generation on 100 Hz edge in the decade timer
	ori r22,r0,DECADE
	ori r3,r0,0b00001000 # select 100 Hz output (bit 3)
	stbio r3,8(r22) # bit 3 will now cause timer interrupt (INT2)
	# (2) recognize INT2 (decade timer) in the processor
	rdctl r3,ienable
	ori r3,r3,0x00000004 # INT2 = bit2 = 1
	wrctl ienable,r3 # INT2 will now be recognized by the processor
	# (3) turn on master interrupt enable in the processor
	rdctl r3,status
	ori r3,r3,0x01 # PIE bit = 1
	wrctl status,r3 # ISR will now be called on enabled interrupts

	pop r5
	pop r22
    	pop r20
    	pop r4
    	pop r3

    	ret
    
#============================================================

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

	andi  r4,r3,0x001FF 	# keep 9 data bits 

	ori   r4,r4,0x0600 	# enable high (and lcd ON)	

	ori   r5,r0,lcd
	sthio r4,0(r5)    	# write to lcd 

	ori   r3,r0,5		# N ms delay   
	call  delay

	andi  r4,r4,0x05FF 	# enable low (and LCD ON)  	

	ori   r5,r0,lcd
	sthio r4,0(r5)    	# write to lcd 

	ori   r3,r0,5		# N ms delay   
	call  delay

	xor   r4,r4,r4		
	ori   r5,r0,REDLEDS  
	sthio r4,0(r5)    

	# ------------------------------------ 

	pop r5
	pop r4
	pop r3
	pop ra

	ret

# ------------------------------------------

#outspc
#outputs a space character(0x20) to the display

outspc:
	
	push r3
	push ra

	ori r3,r0,0x20
	call outchr

	pop ra
	pop r3
	
	ret
#============================================================
# delay for N msec where N is supplied in r3
delay: 
    push r3
    push r4
    push r5
    
    ori r4,r0,20           		# 2 msec
    bge r3,r4,maxvalue
    br max_skip
    
    maxvalue:
        ori r3,r0,20       		# reset to 2 m sec delay
        
    max_skip:
        ori r5,r0,DECADE
        
    falling_edge:
        ldwio r4,(r5)
        andi r4,r4,4        		# isolate 1 ms 
        beq r4,r0,falling_edge    	# wait for rising_edge
        
        addi r3,r3,-1        		# decrement time value
        beq r3,r0,done_delay
    
    rising_edge:
        ldwio r4,(r5)
        andi r4,r4,4        		# isolate 1 ms
        bne r4,r0,rising_edge    	# wait for falling_edge
        br falling_edge    
    
    done_delay:
        
    
    pop r5
    pop r4
    pop r3

    ret

#============================================================  
#clrscr

#clears the lcd screen and moves cursor to the top line by sending the command character 0x101, followed by short delay while clearing operation completes

clrscr:
	push r3
	push r5
	push ra

	ori r3,r0,0x101
	call outchr
	call delay

	pop ra
	pop r5
	pop r3

	ret

#-------------------------------------------------------

outhex:

#outputs lcd display ine ascii character being the hex representation of the 4 least sig bits in r3.
	
	push ra
	push r5
	push r3

	ori r5,r0,hex		
	andi r3,r3, 0xf
	add r5,r5,r3
	ldb r3,(r5)
	call outchr

	pop r3
	pop r5
	pop ra

	ret
# ==========================================	
out16bin:

	#Outputs to the lcd display 16 characters '0' or '1' being the binary representation pf the 16-bit contents or r3.
	push ra
	push r3
	push r7
	push r8


	or r7,r0,r3		#copy of r3
	andi r8,r8,0x0		#set r8 to 0
	ori r8,r0,0x10		#set r8 to 16 to count
loop1:	
	beq r8,r0,empty			#check if ran through all values
	andi r3,r7,0b1000000000000000	#get the msb, since reads backwards
	srli r3,r3,15
	addi r3,r3,0x30		#add 30 to get ascii value
	slli r7,r7,1 		#Shift right one time
	addi r8,r8,-1		#add one to counter
	call outchr
	br loop1
empty:

	pop r8
	pop r7
	pop r3
	pop ra
	ret

# ==========================================
#outhex4hex
#Outputs to the LCD display '0' and 'x' followed by 4 characters being the hexadecimal representation 
out4hex:
	push r3
	push r4
	push r5
	push ra

	or r5,r0,r3
	andi r3,r3,0x0		#set r3 to 0
	ori r4,r0,0x04
	ori r3,r0,0x3d		set r3 to '=' in ascii
	call outchr

	call outspc

	andi r3,r3,0x0		#set r3 to 0
	ori r3,r0,0x30		#set r3 to '0' in ascii
	call outchr

	andi r3,r3,0x0		#set r3 to 0
	ori r3,r0,0x78		#set r3 to 'x' in ascii
	call outchr
loop2:
	andi r3,r5,0xf000	#find first 4 digits
	srli r3,r3,12
	call outhex
	slli r5,r5,4	#shift to 4 new digits
	addi r4,r4,-1	#decrement counter

	bne r4,r0,loop2

	pop ra
	pop r5
	pop r4
	pop r3

	ret

# ==========================================

#Out5int
#Outputs to the lcd display five ascii characters being the 5 digit decimal representation of the 16-bit contents of r3

out5int:
	push r3
	push r4
	push r5
	push r6
	push r7
	push ra

	or r5,r0,r3		#loads r3 in r5
	
	call outspc
	andi r3,r3,0x0		#set r3 to 0
	ori r3,r0,0x3d		#set r3 to '=' in ascii
	call outchr

	call outspc

	ori r4,r0,10000	#divide by 10000 to convert to base 10
	divu r3,r5,r4		#Gets the quotient copy(r5) / r4 (base)
	mul r6,r3,r4		#multiply to find remainder
	sub r7,r5,r6		#get Remainder
	addi r3,r3,0x30
	call outchr		
				#Do the same steps each time 

	ori r4,r0,1000
	divu r3,r7,r4	
	mul r6,r3,r4
	sub r7,r7,r6
	addi r3,r3,0x30
	call outchr		


	ori r4,r0,100
	divu r3,r7,r4	
	mul r6,r3,r4
	sub r7,r7,r6
	addi r3,r3,0x30
	call outchr				


	ori r4,r0,10
	divu r3,r7,r4	
	mul r6,r3,r4
	sub r7,r7,r6
	addi r3,r3,0x30
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
#----------------------------------------------
#outstr
outstr:
	push ra
	push r5
	push r3

	ori r5,r0,welcome

loop3:
	ldb r3,(r5)
	beq r3,r0,escape	#Checks if null, if so skip to escape
	call outchr		
	addi r5,r5,1		#increments one loacation
	br loop3		

escape:
	pop r3
	pop r5
	pop ra

	ret
#----------------------------------------
action2:

	push r3
	push r4
	push r5
	push r6

    @ TODO: r5 is not used
	ori r6,r0,HEX		#loads adress of hex display
	movia r3,counter
	ldwio r4,(r3)		#loads value of counter
	addi r4,r4,1		#increments address of counter
	stwio r4,(r3)		#stores values
	stwio r4,(r6) 

	pop r6
	pop r5
	pop r4	
	pop r3
	
	ret
# data storage (after all code)
# ------------------------------------------        
# reserve 400 bytes = 100 words for stack     

.skip 400 
        
stacktop:

counter: .word 0

# ------------------------------------------
# stored strings

welcome: .asciz "Welcome to Lab 4"
hex: .ascii "0123456789ABCDEF"
#------------------------------------------
