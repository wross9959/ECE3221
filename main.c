

volatile int *const HEXDISP = (int *)0x000088A0;     // display hex digits
volatile short *const HEXCTRL = (short *)0x000088B0; // hex control register
volatile int *const PSP = (int *)0x000088F0;         // PS2 Register
short buffer;
volatile int *LED = (int *)0x00008880; // LED display address

int getkey()
{
    buffer = 0;
    // Wait for falling edge
    while (*PSP & 0x02)
    {
    }
    while (!(*PSP & 0x02))
    {
    }
    // Filter through character value 9 bits
    for (int i = 0; i < 10; i++)
    {
        while (*PSP & 0x02)
        {
        }
        int lsb = *PSP & 01;
        lsb = lsb << i;
        buffer = buffer + lsb;
        while (!(*PSP & 0x02))
        {
        }
    }
    buffer = buffer & 0x0FF;
    return buffer; // Return key
}

void outchar(char ch)
{
    volatile unsigned int *screen = (int *)0x00008840;
    *screen = ch;
}

char bin2hex(char N)
{
    char toReturn;
    N = N & 0x0F;
    if (N < 10)
    {
        toReturn = '0' + N;
    }
    else
    {
        toReturn = 'A' + (N - 10);
    }
    return toReturn;
}

void outhex(char N)
{
    outchar(bin2hex(N >> 4));
    outchar(bin2hex(N));
}

main()
{
    int count;                 // define a counter
    int display;               // holder for the monitor display
    volatile int ledval = 256; // Leds start in middle
    volatile int current = 0;  // Holders for Led displays
    volatile int flags = 0;
    *LED = ledval;     // Place LED light in the middle
    *HEXCTRL = 0x01FF; // enable eight hex digits
    count = 0;         // initial count value
    while (1)
    { // create an infinite loop
        //*HEXDISP = count; // send count to the hex display
        buffer = getkey();          // buffer = key to display
        current = buffer;           // Holder for flag value
        display = display << 8;     // Shift display over
        display = display + buffer; // Add new char to display
        *HEXDISP = display;         // Send display to hex
        if (flags != 0xF0)          // Detect shift value and disregard release
        {
            if (buffer == 0x12) // If shift right
            {
                ledval = ledval << 1;
                *LED = ledval;
            }
            if (buffer == 0x59) // if shift left
            {
                ledval = ledval >> 1;
                *LED = ledval;
            }
            if (ledval == 32768 | ledval == 1) // set back to middle if overshoot
            {
                ledval = 256;
                *LED = ledval;
            }
        }
        outhex(buffer);
        outchar(' ');
        flags = current;
    } // end while
} // end main
