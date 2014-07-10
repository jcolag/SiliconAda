/* Symtab.h:  The header file for symbol table definitions */

/* Timing definitions for the parser */
#define	NULLTIME	1
#define	ASGNTIME	4
#define	TESTTIME	3
#define	ADDTIME		5
#define	SENDTIME	2
#define	LOGTIME		3
#define MULTIME		8
#define	EXPTIME		20

/* Stuff for symbol table management */
int yyerror (char *);

struct  tableent
        {
         char   name[32];
         int    type;
        };

extern  struct tableent symtable[];
extern  int    numsyms;

int lookup (char *);
int syminsert (char *);
