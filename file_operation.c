#include <stdio.h>
#include <string.h>
#include <stdlib.h>

typedef char int8;
typedef int int32;
typedef unsigned char uint8;

void main ()
{
    int8 tmpStr[10][256] = {0},tmpchar,tmpcmd[1024],readlen = 0x20;
	uint8 databuffer[256] = {0};
    int8 *tmpPtr[3] = {NULL};
    uint8 i = 0,j = 0;
	uint8 isNumber = 0;
	int offset_h = 0x2b,offset_l = 0x00;

    FILE *fp = fopen("./ec_fake_ipmi.txt","r");
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
    }///* code for test
    else {printf("open /tmp/ec_fake_ipmi.txt fail");}
    //*/
    
    ///* code for test
    for(i = 0; i < 4; i ++)
    {
        printf("%s\n",tmpStr[i]);
    }
    //*/
	if(0 == strncmp((tmpStr[0]+strlen("ec_fake_ipmi=")),"TRUE",4))
	{
		//getuser,getpassword,getcmcip
		tmpPtr[0] = tmpStr[1]+strlen("cmc_ip=");
		tmpPtr[1] = tmpStr[2]+strlen("user=");
		tmpPtr[2] = tmpStr[3]+strlen("password=");
		printf("ip:%s,usr:%s,password:%s\n",tmpPtr[0],tmpPtr[1],tmpPtr[2]);

	/*build cmd:ipmitool -H %ip% -U admin -P admin raw 0x06 0x52 0x0B 0xA0 0x00 0x2B 0x00
          0x31 0x31 ...see <<Write-Read Midplane EEPROM.docx>> for detail       */
		snprintf(tmpcmd,strlen("ipmitool -H ")+1,"ipmitool -H ");
		snprintf(tmpcmd+strlen(tmpcmd),strlen(tmpPtr[0])+1,tmpPtr[0]);
		snprintf(tmpcmd+strlen(tmpcmd),strlen(" -U ")+1," -U ");
		snprintf(tmpcmd+strlen(tmpcmd),strlen(tmpPtr[1])+1,tmpPtr[1]);
		snprintf(tmpcmd+strlen(tmpcmd),strlen(" -P ")+1," -P ");
		snprintf(tmpcmd+strlen(tmpcmd),strlen(tmpPtr[2])+1,tmpPtr[2]);
		snprintf(tmpcmd+strlen(tmpcmd),strlen(" raw 0x06 0x52 0x0B 0xA0 ")+1," raw 0x06 0x52 0x0B 0xA0 ");

		printf("len1 is %d\n",strlen(tmpcmd));
 
        /*why 6+1: strlen("0xMM")==6,add '\0' at string tail,so 6+1*/
		snprintf(tmpcmd+strlen(tmpcmd),6+1," 0x%02x ",readlen);
        snprintf(tmpcmd+strlen(tmpcmd),6+1," 0x%02x ",offset_h);
        snprintf(tmpcmd+strlen(tmpcmd),6+1," 0x%02x ",offset_l);

		printf("len2 is %d\n",strlen(tmpcmd));
		
        ///*code for test
        printf("tmpcmd is:\n%s\n",tmpcmd);
        //*/		
	}

	system("cat ./ReadorWriteResult > ./ReadorWriteResult_cpy");
    
	fp = fopen("./ReadorWriteResult_cpy","r");
    if(NULL != fp)
	{
        i = 0;
		while(EOF != (tmpchar = fgetc(fp)))
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
		fclose(fp);
	}
	else{printf("open readresult fail\n");}

	///*code for test
	printf("\ndatabuffer is:\n");
    for(i = 0; i < 32; i++)
	{
		printf("0x%x ",databuffer[i]);
		if(i % 16 == 15)
			printf("\n");
	}
	//*/
}
