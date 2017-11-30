#include <stdio.h>
#include <stdlib.h>
#include <string.h>
 #include <semaphore.h>

#include "pthread.h"
#include "semaphore.h"
#include "unistd.h"

#define BUFF_SIZE 10*1024

#define SRC_STRING "KEY11\nKEY21\nKEY31\nKEY41\nKEY51\nKEY61\nKEY71\nKEY81\nKEY91\n"

#define SRC1   "1\n"
#define SRC2   "2000\n"
#define SRC3   "3000000\n"
#define SRC4   "4000000000\n"
#define MAX_KEY_LEN 10

sem_t sem;
sem_t sem_check;

typedef struct thread_info_st
{
    char * param;
    int index;
}THREAD_INFO_T;

const char* get_value_by_index(int num)
{
    const char* value;
    switch(num)
    {
        case 1:
            value = SRC1;
            break;
        case 2:
            value = SRC2;
            break;
        case 3:
            value = SRC3;
            break;
        default:
            value = SRC4;
            break;
    }
    
    return value;
}

void memmove_test(void* arg, int num, char* str_key, char* str_next_key)
{
    const char* value;
    int change = num == 1 ? -9 : 3;
    char* src = NULL;
    char* dest = NULL;
    
    value = get_value_by_index(num);
    printf("debug %s", value);
    dest = strstr(arg, str_next_key) +change;
    src = strstr(arg, str_next_key);
    memmove(dest, src, strlen(src));
    dest = dest + strlen(src);
    memset(dest,0,  1024);
    dest = strstr(arg, str_key) + strlen(str_key);
    strncpy(dest, value, strlen(value));
    return;
}

void check_memmove(char* str, int num, const char* str_key)
{
    const char* value;
    char* src = NULL;
    value = get_value_by_index(num);
    src = strstr(str, str_key) + strlen(str_key);
    
    if (strncmp(src, value, strlen(value)) != 0 )
    {
        printf("conflict occured \n");
        printf("expect key :%s, vlaue:%s", str_key, value);
        printf("********************\n%s*****************\n", str);
        exit(0);
    }
}
void* mem_test(void* arg)
{
    THREAD_INFO_T* thread_info = (THREAD_INFO_T*) arg;
    int i = 1;
    int index = 0;
    char str_key[MAX_KEY_LEN];
    char str_next_key[MAX_KEY_LEN];

    if (thread_info == NULL)
    {
        perror("child thread:get thread info failed\n");
    }
    
    memset(str_key, 0, MAX_KEY_LEN);
    memset(str_next_key, 0, MAX_KEY_LEN);
    
    snprintf(str_key, MAX_KEY_LEN, "KEY%d", thread_info->index);
    snprintf(str_next_key, MAX_KEY_LEN, "KEY%d", thread_info->index + 1);
    while (1)
    {
        if(sem_wait(&sem) == 0) 
        {
            i++;
            i = i % 4;
            printf("mem test %d\n", i);
            memmove_test(thread_info->param, i, str_key, str_next_key);
            printf("********************\n%s*****************\n", thread_info->param);
            
            usleep(500);
            check_memmove(thread_info->param,i, str_key);
        }
    }
    return NULL;
}

int main(int argc, char *argv[])
{
    char* str_test = NULL;
    pthread_t pid;
    int num = 0;
    int i = 0;
    THREAD_INFO_T * thread_info = NULL;
    
    if (argc < 2)
    {
        perror("no param\n");
        return -1;
    }
    sem_init(&sem, 0, 0);
    sscanf(argv[1], "%d", &num);
    
    str_test = malloc(BUFF_SIZE);
    if (str_test == NULL)
    {
        printf("malloc failed\n");
        return -1;
    }
    
    memset(str_test,0, BUFF_SIZE);
    strncpy(str_test, SRC_STRING, strlen(SRC_STRING));
    
    for (i = 0; i < num; i++)
    {
        thread_info = NULL;
        thread_info = malloc(sizeof (struct thread_info_st));
        if (thread_info == NULL)
        {
            perror("malloc thread info failed\n");
            return -1;
        }
        
        thread_info->param = str_test;
        thread_info->index = i + 1;
        pthread_create(&pid, NULL, mem_test, thread_info);
    }
    
    while(1)
    {
        for (i = 0; i < num; i++)
        {
            sem_post(&sem);
        }
        sleep(1);
    }
}
