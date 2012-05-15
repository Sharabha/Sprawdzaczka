// kompilujemy gcc -o dummy1 dummy1.c

#include<stdio.h>

int main(void)
{
  printf("Hello world\n");
  
  printf("I want live.\n");
  FILE * fopen_1 = fopen("/etc/rc.conf", "r");

  printf("I want to be killed.\n");
  FILE * fopen_2 = fopen("/etc/rc.conf", "w");  

  return 0;
} 

