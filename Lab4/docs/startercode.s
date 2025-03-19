.global _start
_start: br Start  # begin at the main program

# ==========================================
# macro definitions (push/pop) at the top
# ------------------------------------------


# ==========================================
# interrupt service routine (ISR)
# ------------------------------------------
.org 0x0020	 # ISR code lies at this address
ISR:

# ==========================================
# main program (after the ISR)               
# ------------------------------------------
.org 0x0100	 # code lies at this address

Start:
	call init # initialization

here:	br here   # the entire main program!!
 
# ==========================================

init:
	


# ==========================================
# subroutines  (after main code)                  
# ------------------------------------------

outchr:


outspc:


delayN:


clrscr:




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
