#include <stdio.h>
#include <string.h>
#include <stdlib.h>

typedef char int8;
typedef int int32;
typedef unsigned char uint8;
typedef unsigned long long uint64;
void main ()
{
    int8 tmpStr[10][256] = {0},tmpchar,tmpcmd[1024],readlen = 16;
	uint8 databuffer[256] = {0x99},tmpbuffer[256]={0};
    int8 *tmpPtr[3] = {NULL};
    uint8 i = 0,j = 0;
	uint8 isNumber = 0;
	int offset_h = 0x2b,offset_l = 0x00;
	uint64 wwnn = 0;
	int32 popen_rc,pclose_rc;

    FILE *fp = fopen("./ec_fake_ipmi.txt","r");
    if(NULL != fp) {
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
    else {
		printf("open /tmp/ec_fake_ipmi.txt fail");
	}
    //*/
    
    ///* code for test
    for(i = 0; i < 4; i ++) {
        printf("%s\n",&tmpStr[i][0]);
    }
    //*/
	if(0 == strncmp((&tmpStr[0][0]+strlen((char*)"ec_fake_ipmi=")),"TRUE",4)) {
		//getuser,getpassword,getcmcip
		tmpPtr[0] = &tmpStr[1][0]+strlen("cmc_ip=");
		tmpPtr[1] = &tmpStr[2][0]+strlen("user=");
		tmpPtr[2] = &tmpStr[3][0]+strlen("password=");
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
 
        /*why 6+1: strlen(" 0xMM ")==6,add '\0' at string tail,so 6+1*/
		snprintf(tmpcmd+strlen(tmpcmd),6+1," 0x%02x ",readlen);
        snprintf(tmpcmd+strlen(tmpcmd),6+1," 0x%02x ",offset_h);
        snprintf(tmpcmd+strlen(tmpcmd),6+1," 0x%02x ",offset_l);

		printf("len2 is %d\n",strlen(tmpcmd));
		
        ///*code for test
        printf("tmpcmd is:\n%s\n",tmpcmd);
        //*/		
	}

	system("cat ./ReadorWriteResult >ReadorWriteResult_cpy");
    
	//fp = fopen("./ReadorWriteResult_cpy","r");
	//fp = popen("cccat ReadorWriteResult_cpy","r");
	fp = popen("timeout -k1 5 ping 1.1.1.1", "r");//测试不同失败类型的返回码;
	/*
	 ping www.baidu.com:0x8d00
	 timeout -k1 0.1 ping www.baidu.com : 0x7c00
	 timeout -k1 5 ping 1.1.1.1: 0x7c00,1.1.1.1地址不存在，且 
	 */
#if 1
	if(NULL != fp)
	{
        i = 0;
		while((EOF != (tmpchar = fgetc(fp))) && (i < readlen))
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
		pclose_rc = pclose(fp);
	 	popen_rc = (int32)WEXITSTATUS(pclose_rc);
		//popen_rc = (int32)WEXITSTATUS(-1);
		printf("pclose_rc is %d,0x%x,popen_rc is %d,0x%x\n",pclose_rc,pclose_rc, popen_rc, popen_rc);
	}
	else{printf("open readresult fail\n");}

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


#endif

#if 0
	if(NULL != fp){
		while((EOF != (tmpchar = fgetc(fp))) && (i < 2*2*readlen))
		{
			if(tmpchar >= 'a' && tmpchar <= 'f')
			{
				tmpchar = tmpchar - 'a' + 'A';
			}
			
			if((tmpchar >= 'A' && tmpchar <= 'F') || (tmpchar >= '0' && tmpchar <= '9'))
			{
				databuffer[i++] = tmpchar;
			}

		}
		databuffer[i] = '\0';
		fclose(fp);
	
		
	}
	else {
		printf("open readresult fail\n");
	}
	
#endif

	/*code for test
    if((EOF == tmpchar)&&(isNumber ==1))
	{
	    i ++;
	}
	if(i< readlen)
	{
		printf("get too few data\n");
	}
    printf("\n");
	//*/
}
