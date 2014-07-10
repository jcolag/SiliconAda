%{
/* Lexical Analyzer for the Ada => VHDL compiler */
/* Written for "Flex", the "Fast Lexical Analyzer */
/* Generator */
#include <stdio.h>
#include <malloc.h>
#include <stdlib.h>
#include "y.tab.h"
#include "symtab.h"
#include "graph.h"

#define yy_strcpy       strcpy
#define yy_flex_realloc realloc
#define yy_flex_alloc   malloc
#define yy_flex_free    free

extern int yylineno, cvar, stmtct;
extern char textbuf[];
extern void exit();
extern float numval;

static int last_token;

char   strlit[128];
%}

ALPHA   [a-zA-Z]
DIGIT   [0-9]
XDIGIT  [a-fA-F0-9]
EXPON   [Ee][+-]?{DIGIT}(_?{DIGIT})*

%%

"&"     { last_token = '&'; return '&'; }
"("     { last_token = '('; return '('; }
")"     { last_token = ')'; return ')'; }
"*"     { last_token = '*'; return '*'; }
"+"     { last_token = '+'; return '+'; }
","     { last_token = ','; return ','; }
"-"     { last_token = '-'; return '-'; }
"."     { last_token = '.'; return '.'; }
"/"     { last_token = '/'; return '/'; }
":"     { last_token = ':'; return ':'; }
";"     { last_token = ';'; return ';'; }
"<"     { last_token = '<'; return '<'; }
"="     { last_token = '='; return '='; }
">"     { last_token = '>'; return '>'; }
"!"     |                                    /* alternate character */
"|"     { last_token = '|'; return '|'; }

"**"    { last_token = EXP_; return EXP_; }
".."    { last_token = DBLDOT_; return DBLDOT_; }
"/="    { last_token = NOTEQL_; return NOTEQL_; }
":="    { last_token = ASSIGN_; return ASSIGN_; }
"<<"    { last_token = L_LBL_; return L_LBL_; }
"<="    { last_token = LTEQ_; return LTEQ_; }
"<>"    { last_token = BOX_; return BOX_; }
"=>"    { last_token = ARROW_; return ARROW_; }
">="    { last_token = GTEQL_; return GTEQL_; }
">>"    { last_token = R_LBL_; return R_LBL_; }

"'"     {
  /* is it an attribute tic? */
  switch ( last_token ) {
    case ')' :
    case ALL_ :
    case identifier :
    case string_literal :
    case character_literal :
      last_token = '\'';
      return '\'';
    default :
      ;
  }

  /* must be a character literal */
  {
    int c = input();

    if ( c != '\n' ) {
      c = input();

      if ( c == '\'' ) {
	last_token = character_literal;
	return character_literal;
      } else {
	fprintf( stderr,
		 "malformed character literal on line %d\n",
		 ( c != '\n' ) ? yylineno : --yylineno );

	exit( 1 );
      }
    } else {
      fprintf( stderr, "malformed character literal on line %d\n", --yylineno );

      exit( 1 );
    }
  }
}

{ALPHA}(_?({ALPHA}|{DIGIT}))*       {
  extern char yytext[], lastvar[];
  extern int reserved_word();

  strcpy (lastvar, yytext);
  last_token = reserved_word( yytext );
  if (last_token == identifier)
	{       /* want to get a symboltable number and insert into a list */
	 cvar = lookup (lastvar);
	 usevar (cvar);
	}
  return last_token;
}

{DIGIT}(_?{DIGIT})*([.]{DIGIT}(_?{DIGIT})*)?({EXPON})?              |
{DIGIT}(_?{DIGIT})*:{XDIGIT}(_?{XDIGIT})*([.]{XDIGIT}(_?{XDIGIT})*)?:({EXPON})? |     /* alternate character */
{DIGIT}(_?{DIGIT})*#{XDIGIT}(_?{XDIGIT})*([.]{XDIGIT}(_?{XDIGIT})*)?#({EXPON})? {
  numval = atof (yytext);
  last_token = numeric_literal;
  return numeric_literal;
}

\%([^%"]|\%\%)*\%       |     /* alternate character */
\"([^"]|\"\")*\"        {
  strcpy (strlit, yytext);
  last_token = string_literal;
  return string_literal;
}

"--".*          ;
[ \f\n\r\t\v]   ;

.       {
  fprintf( stderr, "illegal character on line %d\n", yylineno );

  exit( 1 );
}
%%
int yywrap()
{
 return 1;
}

