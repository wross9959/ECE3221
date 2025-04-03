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

short buffer;                                           // Buffer for key value         


// Get the key - subroutine
int getkey()
{
    buffer = 0;                                         // Clear buffer

    // Wait for falling edge
    while (*PSP & 0x02) {}                              // Loop until a key is pressed
    while (!(*PSP & 0x02)) {}                           // Loop until key is released


    // Filter through character value 9 bits
    for (int i = 0; i < 10; i++)
    {
        while (*PSP & 0x02){}                           // Wait for key to be pressed

        int lsb = *PSP & 01;                            // Get the least significant bit
        lsb = lsb << i;                                 // Shift it to the left
        buffer = buffer + lsb;                          // Add it to the buffer

        while (!(*PSP & 0x02)){}                       // Wait for key to be released
    }

    buffer = buffer & 0x0FF;                            // Mask the buffer to 8 bits
    return buffer;                                      // Return key
}


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
main()
{
    int count;                                          // define a counter
    int display;                                        // holder for the monitor display
    volatile int ledval = 256;                          // Leds start in middle
    volatile int current = 0;                           // Holders for Led displays
    volatile int flags = 0;
    *LED = ledval;                                      // Place LED light in the middle
    *HEXCTRL = 0x01FF;                                  // enable eight hex digits
    count = 0;                                          // initial count value


    while (1)                                           // infinite loop    
    { 
        //*HEXDISP = count++;                           // send count to the hex display
        buffer = getkey();                              // buffer = key to display
        current = buffer;                               // Holder for flag value

        display = display << 8;                         // Shift display over
        display = display + buffer;                     // Add new char to display

        *HEXDISP = display;                             // Send display to hex

        if (flags != 0xF0)                              // Detect shift value and disregard release
        {
            if (buffer == 0x12)                         // If shift right
            {
                ledval = ledval << 1;                   // Shift right
                *LED = ledval;                          // Send to LED
            }
            if (buffer == 0x59)                         // if shift left
            {
                ledval = ledval >> 1;                   // Shift left
                *LED = ledval;                          // Send to LED
            }
            if (ledval == 32768 | ledval == 1)          // set back to middle if overshoot
            {
                ledval = 256;                           // Reset to middle    
                *LED = ledval;                          // Send to LED   
            }
        }
        outhex(buffer);                                 // Send hex value to display
        outchar(' ');                                   // Send space to display
        flags = current;                                // Set flags to current value  
    }
} 
