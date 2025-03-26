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
  int count = 0;			// initial count value
  int last_clk_cyle = 1;

  int current_clk_cyle;

  while( 1 ) 
  { 		
    current_clk_cyle = read_PS2_Clk(PS2);

    // if its on the falling edge
    if ( last_clk_cyle == 1 && current_clk_cyle == 0 ) 
    {
        count++;
        *HEXDISP = count;
    }
    //update the current clock cycle to be the prev 
    last_clk_cyle = current_clk_cyle;
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

