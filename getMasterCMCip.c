#include <stdio.h>
#include <string.h>
#include <stdlib.h>

typedef char int8;
typedef int int32;
typedef unsigned char uint8;
typedef unsigned long long uint64;
/***********************************************************************
 *******length: length to get
 *******actlen: length actual got
 ************************************************************************/
int getHexFromFile (FILE *fp, int8 length, uint8 * buffer, uint8 *actlen) {
	
	int i = 0, isNumber = 0;
	char *databuffer = buffer, tmpchar;

	while((EOF != (tmpchar = fgetc(fp))) && (i < length))
	{
		if(tmpchar >= 'a' && tmpchar <= 'f')
		{
			tmpchar = tmpchar - 'a' + 'A';
		}
		
		if((tmpchar >= 'A' && tmpchar <= 'F') || (tmpchar >= '0' && tmpchar <= '9'))
		{
			isNumber = 1;
			if(tmpchar >= 'A' && tmpchar <= 'F')
			{
				databuffer[i] = databuffer[i]*16 + tmpchar - 'A' + 10;
			}
			else
			{
				databuffer[i] = databuffer[i]*16 + tmpchar - '0';
			}
		}
		else
		{
			if(isNumber == 1)
			{
				i ++;
			}
			isNumber = 0;
		}
	}
    
	/*i record the count of numbers have got,
	  if got EOF and last charactor is number, the last number has not been recorded*/
	if ( (1 == isNumber) && (EOF == tmpchar) )
	{
		i ++;
	}

	*actlen = i ;

	if (*actlen < length)
	{
		return 0;
	}
	else
	{
		return 1;
	}
}

void main ()
{
    int8 tmpStr[10][256] = {0},tmpchar,readlen = 8;
	uint8 databuffer[256] = {0x99},tmpbuffer[256]={0};
    int8 *tmpPtr[3] = {NULL};
    uint8 i = 0,j = 0;
	uint8 isNumber = 0;
	int offset_h = 0x2b,offset_l = 0x00;
	uint64 wwnn = 0;
    int8 tmpcmd[] = "cat ReadorWriteResult_cpy";
	FILE *fp ;
	fp = popen(tmpcmd,"r");
	if (fp != NULL)
	{
		if (1 == getHexFromFile (fp, readlen, databuffer, &i))
		{
			if(readlen != i )
			{
				printf("can't get enough data,need(%d),got(%d)\n", readlen, i);
			}
		}
		else
		{
			printf("get data from fstream fail\n");
		}
	}
	else
	{
		printf("popen fail\n");
	}
	//*/
	printf("databuffer is:\n");
    for(i = 0; i < readlen; i++)
	{
		printf("0x%02x ",databuffer[i]);
		if(i % 16 == 15)
			printf("\n");
	}

	for(i = 0; i < readlen; i++)
	{
		snprintf((char *)(tmpbuffer+strlen(tmpbuffer)),4+1,"%03d.",databuffer[i]);
	}

	tmpbuffer[strlen(tmpbuffer) - 1] = '\0';
	
	///*code for test
	printf("\ntmpbuffer is:IP\n%s\n",tmpbuffer);
	//*/
	strncpy(databuffer,tmpbuffer,strlen(tmpbuffer)+1);
	printf("databuffer is :\n%s\n",databuffer);
}
