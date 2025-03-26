/*** 
CMPE3221 LAB#5 - C LANGUAGE EXERCISE                       
----------------------------------------------- 
November 2010	NAME: Will Ross #3734692
----------------------------------------------- 
This program is the starting point for LAB#5
It enables the hex display and creates a counter.
-----------------------------------------------
***/

// All Lab addresses
#define HEXDISP_ADDRESS ((int*)0x000088A0)
#define HEXCTRL_ADDRESS ((short*)0x000088B0)
#define LED_ADDRESS ((int*)0x00008880)
#define SWITCH_ADDRESS ((int*)0x00008850)
#define BUTTONS_ADDRESS ((int*)0x00008860)
#define PS2DATA_ADDRESS ((int*)0x000088F0)
// ---------------------------------------

// Part A - subroutines
void outchar( char ch );    // send the bytes to the Altera Monitor terminal display window
char bin2hex( char N );     // return the ASCII hex character for the 4 least significant bits of N
void outhex( char N );      // use bin2hex and outchar to display 2 ASCII hex chars = the byte N 


// Part B - subroutines
int read_PS2_Bit(int *PS2DATA); // read PS2 data bit
int read_PS2_Clk(int *PS2DATA); // read PS2 clock bit

// Part c - subroutines
char getKey(); // get key from PS2


// Other subroutines - For the lab machine and online sim, so i can do this almost dynamically without the headache
char hexTo7Seg(); // ONLY for online tests
void labmachine(); // lab machine test
void onlineSim(); // online simulation test



void labmachine()
{

    volatile int   *const HEXDISP = HEXDISP_ADDRESS; // display hex digits
    volatile short *const HEXCTRL = HEXCTRL_ADDRESS; // hex control register	
    volatile int *const PS2 = PS2DATA_ADDRESS; // PS2 data register

    *HEXCTRL = 0x01FF;   		// enable eight hex digits
    char sc;
    while( 1 ) 
    { 		
        sc = getKey();
        *HEXDISP = sc;
        outhex(sc);
        outchar('\n');
    } 
}

void onlineSim() 
{
  volatile char   *const HEXDISP = (char   *)0x10000020;
  int	 count = 0;
  while (1) {
    int displayValue = 0;
    int temp = count;

    for (int i = 0; i < 4; i++) {
        char digit = temp & 0xF;
        displayValue |= (hexTo7Seg(digit) << (8 * i));
        temp >>= 4;
    }

    *HEXDISP = displayValue;

    outhex(count);
    outchar('\n');

    count++;
  }

}


int main ( ) 
{

  onlineSim();
  
  return 0;
} 

// Note: PS2 bit 1 is the data
int read_PS2_Bit(int *PS2DATA) 
{
    return (*PS2DATA >> 1) & 0x01;
}

// Note: PS2 bit 0 is the clk
int read_PS2_Clk(int *PS2DATA)
{
    return (*PS2DATA >> 0) & 0x01;
}


char hexTo7Seg(char hex) {
  char segTable[16] = {
    0x3F, 
    0x06,
    0x5B, 
    0x4F, 
    0x66, 
    0x6D, 
    0x7D, 
    0x07, 
    0x7F, 
    0x6F, 
    0x77, 
    0x7C, 
    0x39, 
    0x5E, 
    0x79, 
    0x71  
  };

  return segTable[hex & 0x0F];
}

void outchar( char ch ) 
{
  volatile char *const UART = (char *)0x00008800; 
  volatile char *const UART_STATUS = (char *)0x00008804;

  while ( (*UART_STATUS & 0x40) == 0 ) 
  {  
    *UART = ch; 
  } 
}

char bin2hex( char N ) 
{
  char hex;

  if ( N < 10 ) 
  {
    hex = N + '0';
  } 
  else 
  {
    hex = N - 10 + 'A';
  }

  return hex;
}

void outhex( char N )
{
  char high, low;

  high = (N >> 4) & 0x0F; // get the 4 MSB
  low = N & 0x0F;

  outchar( bin2hex( high ) ); // send the MSB
  outchar( bin2hex( low ) );  // send the LSB

}

char getKey()
{
    volatile char *const PS2 = PS2DATA_ADDRESS;

    int buffer = 0, count = 0, prev_clk  = 1, receiving = 0;

    while ( 1 )
    {
        int clk = (*PS2 & 0x01);
        int data = (*PS2 >> 1) >> 0x01;

        // this checks if the clk cycle is on a falling edge
        if ( prev_clk == 1 && clk == 0 )
        {
            if ( !receiving ) 
            {
                // if we are just starting
                if ( data == 0 )
                {
                    receiving = 1;
                    count = 0;
                    buffer = 0;
                }
            }
            else
            {
                // if we have less than 8 bits
                if ( count < 8)
                {
                    buffer |= (data << count);

                }
                // increment the count
                count++;

                // if we have the 10 bits (8 data, 1 parity, and 1 stop bit)
                // note it could be 11 but above when we find the start bit i dont increement until the first bit of the 8 bit of data
                if ( count == 10 )
                {
                    return (char)(buffer & 0xFF); // this will return the 8 bit data segment 
                }
            }
        }
        // update the prev_clk cycle and move to the next
        prev_clk = clk;
    }
}