#include <stdio.h>
#include <stdlib.h>
#include <string.h>


void main ()
{
    /*测试在C语言中执行shell命令*/
    char cmd0[]="l",cmd1[]="s",cmd[1000];
    snprintf(cmd,strlen(cmd0)+1,cmd0);
    snprintf(cmd+strlen(cmd),strlen(cmd1)+1,cmd1);
    printf("cmd is:\"%s\"\n",cmd);
    system(cmd);
}
