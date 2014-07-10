#include <string.h>
#include "symtab.h"

#define NSYMS   512

struct  tableent symtable[NSYMS];
int     numsyms = -1;

int lookup (char *name)
{
 int    i;

 for (i = 0; i <= numsyms; i++)
        if (!strcmp (name, symtable[i].name)) return i;
 return (syminsert (name));
}

int syminsert (char *name)
{
 if (numsyms == NSYMS - 1)
        {
         yyerror ("Out of Symbol Table space!!");
         return -1;
        }
 strcpy (symtable[numsyms].name, name);
 ++numsyms;
 return (numsyms-1);
}
