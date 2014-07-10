/*
 *    This is the main program for the Ada lex/yacc grammars.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "graph.h"

extern char textbuf[];
extern stmt *top;

int main(void)
{
 int    i = 0;

 extern int yyparse (void);

 init ();
 strcpy (textbuf, "\000");
 
 (void) yyparse ();

 printf ("-- Parse complete...\n");

 i = optimize (top);
 printf ("-- Total of %d graph alterations.\n\n", i);
 dumpVHDL (top);

 return 1;
}

int yyerror (char *s)
{
 extern int yylineno;
 extern char yytext[];

 fprintf(stderr, "Syntax error on line %d, found \"%s\" (\"%s\").\n",
        yylineno, yytext, s);
 exit (1);
 return 0;
}
