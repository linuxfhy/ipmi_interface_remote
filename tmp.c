#include <stdio.h>
#include <string.h>
void main () {
	int a,b;
	sscanf("103","%1x%02x",&a,&b);
	printf("a=%x, b=%x", a, b);
}
