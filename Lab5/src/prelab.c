/*** 
ECE3221 LAB#5 - C LANGUAGE EXERCISE                       
----------------------------------------------- 
April 2025	NAME: Will Ross #3734692
----------------------------------------------- 
This program is the starting point for LAB#5
It enables the hex display and creates a counter.
-----------------------------------------------
***/
volatile int *const HEXDISP = (int *)0x000088A0;        // Address for hex display
volatile short *const HEXCTRL = (short *)0x000088B0;    // Address for hex control register
volatile int *const PSP = (int *)0x000088F0;            // Address for keypad
volatile int *LED = (int *)0x00008880;                  // Address for LED


// Output a character to the screen - subroutine
// send the byte ch to the Altera Monitor terminal display window
void outchar(char ch)
{
    volatile unsigned int *screen = (int *)0x00008840;  // Address for screen
    *screen = ch;                                       // Send character to screen
}

// Convert binary to hex - subroutine
// return the ASCII hex character for the 4 least significant bits of N
char bin2hex(char N)
{
    char toReturn;                                      // what to return for hex value
    N = N & 0x0F;                                       // Get the 4 least significant bits
    if (N < 10)                                         // If less than 10
    {
        toReturn = '0' + N;                             // Convert to ASCII
    }
    else if (N < 16)                                    
    {
        toReturn = '0' + N;                             
    }
    else
    {
        toReturn = 'A' + (N - 10);                      
    }
    return toReturn;                                    // Return the hex value
}

// Output a hex value to the screen - subroutine
// use bin2hex and outchar to display 2 ASCII hex chars = the byte N
void outhex(char N)
{
    outchar(bin2hex(N >> 4));                           // Shift right 4 bits, and convert to hex
    outchar(bin2hex(N));                                // Convert to hex
}

// Main method
main( ) 
{
    *HEXCTRL = 0x01FF;   		                            // enable eight hex digits
    int count = 0;			                                // initial count value
  
    while( 1 )                                          // infinite loop    
    { 		

      *HEXDISP = count;                                 // send count to the hex display
      outhex( count );                                  // Send hex value to display
      outchar( '\n' );                                  // Send space to display
    	count++;	                                        // increase count every cycle

    }   
} 
