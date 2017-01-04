#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct TestStruct
{
	int field1;
	int field2;
} TestStruct;

TestStruct data []=
{
	{0x2+0x3,0x6},
	{0x8,9},
};

void main ()
{
    /*测试在C语言中执行shell命令*/
    char cmd0[]="l",cmd1[]="s",cmd[1000];
	char tmparrary[2][3];
    int i = 0;
	char cmdtmp[] = "00000200640105e2";
	snprintf(cmd,strlen(cmd0)+1,cmd0);
    snprintf(cmd+strlen(cmd),strlen(cmd1)+1,cmd1);
    printf("cmd is:\"%s\"\n",cmd);
    system(cmd);

	printf("data[0].field1=%d\n",data[0].field1);
	printf("sizeof tmpassary is %d\n",sizeof(tmparrary));


	for(i = 0; cmdtmp[i] != '\0'; i++)
	{
		printf("0x%02x ",cmdtmp[i]);
	}

	printf("\n");
}
