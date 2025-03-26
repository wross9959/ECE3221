/*** 
CMPE3221 LAB#5 - C LANGUAGE EXERCISE                       
----------------------------------------------- 
November 2010	NAME: Will Ross #3734692
----------------------------------------------- 
This program is the starting point for LAB#5
It enables the hex display and creates a counter.
-----------------------------------------------
***/


void outchar( char ch );    // send the bytes to the Altera Monitor terminal display window
char bin2hex( char N );     // return the ASCII hex character for the 4 least significant bits of N
void outhex( char N );      // use bin2hex and outchar to display 2 ASCII hex chars = the byte N 

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

void labmachine()
{
  volatile int   *const HEXDISP = (int   *)0x000088A0; // display hex digits 
  volatile short *const HEXCTRL = (short *)0x000088B0; // hex control register  	
  

  *HEXCTRL = 0x01FF;   		// enable eight hex digits

  int count = 0;			// initial count value
  while( 1 ) 
  { 		

    *HEXDISP = count;
    outhex( count );
    outchar( '\n' );
  	count++;	

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
    hex = 'A' + ( N - 10 );
  }

  return hex;
}

void outhex( char N )
{
  outchar( bin2hex((( N >> 4)& 0x0F ))); // send the MSB
  outchar( bin2hex(( N & 0x0F )));  // send the LSB
}
