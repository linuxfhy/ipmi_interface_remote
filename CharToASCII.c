#include <stdio.h>
#include <string.h>
#include <stdlib.h>
void main ()
{
	char tmpStr[50][256],tmpchar;
	int i = 0, j = 0,line = 0;
	FILE *fp = fopen("./src","r");
	if(NULL != fp)
	{
		while(EOF != (tmpchar = fgetc(fp)))
		{
			if('\n' == tmpchar)
			{
				tmpStr[i][j] = '\0';
				j = 0;
				i ++;
			}
			else 
			{
				tmpStr[i][j++] = tmpchar;
			}
		}
		fclose(fp);
		line = i + 1;
	}
	else
	{
		printf("open ./src fail\n");
	}


	fp = fopen("./result","w");
	if(NULL != fp)
	{
		for(i = 0; i < line; i ++)
		{
			fprintf(fp,"%s\n",tmpStr[i]);
			for(j = 0; j < strlen(tmpStr[i]); j++)
				fprintf(fp,"0x%02x ",tmpStr[i][j]);
			fprintf(fp,"\n");
		}
		fclose(fp);
	}
}
