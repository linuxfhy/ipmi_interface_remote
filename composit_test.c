#include <stdio.h>

typedef struct field_attr {
	int field;
	int composite;
	int next_field;
	char value[32];
} field_attr;

field_attr fieldArrary[]={
	{0,	1,	 4,	 "This"		},   //field0
	{1, 0,	 0,	 " example"	},   //field1
	{2, 1,	 1,	 " test"	},   //field2
	{3,	1,	 2,	 " a"		},   //field3
	{4, 1,	 3,	 " is"		},   //field4
};
void main()
{
	int composite = 1;
	int field = 0;
	printf("string is:\n");
	printf("%s",fieldArrary[field].value);
	while(composite == 1)
	{
		field = fieldArrary[field].next_field;
		composite = fieldArrary[field].composite;
		printf("%s",fieldArrary[field].value);
	}
	printf("\n");
}
