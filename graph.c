#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <malloc.h>
#include "graph.h"
#include "symtab.h"

#define ENDOFLIST(X)    if(X && X->next)do{X=X->next;}while(X && X->next)

var * getvars (var *);

int     stmttime;
stmt    *now, *top = NULL;

void init (void)
{
 char   *header = "Header for VHDL program";

 top = malloc (sizeof (stmt));
 if (top == NULL) fprintf (stderr, "Malloc bombed\n");
 top->next = NULL;              /* Initialize pointers */
 top->next2 = NULL;
 top->spine = NULL;
 top->also = NULL;
 top->type = DECL;
 top->time = 0;                 /* Store the time this statement takes */
 top->text = malloc (strlen (header));
 if (top->text == NULL) fprintf (stderr, "Malloc for text died\n");
 strcpy (top->text, header);    /* Store the actual statement text */
 top->uses = NULL;      /* Which variables are needed, supplied by parser */
 top->changes = NULL;   /* Which variables are altered, as "uses" */
 top->prev = NULL;

 now = top;
}

int insert (char *statement, stmt *src)
{       /* Take a statement, and store it in the graph */
 stmt   *temp = src;

 if (now->text == NULL)
        {
         now->text = malloc (strlen (statement));
         if (now->text == NULL) fprintf (stderr, "Malloc died, no insert\n");
         strcpy (now->text, statement);/* Store the actual statement text */
        }
 temp->type = LOOP;     /* The only option not handled in the parser */

 temp = malloc (sizeof (stmt));
 if (temp == NULL) fprintf (stderr, "Can\'t insert, malloc died\n");
 if (src->next) src->next2 = temp;  /* This makes it an "else" or loop-bottom */
 else   src->next = temp;       /* Else it's the top */

 temp->next = NULL;             /* Initialize pointers */
 temp->next2 = NULL;
 temp->spine = NULL;
 temp->also = NULL;
 temp->time = stmttime;         /* Store the time this statement takes */
 temp->uses = NULL;     /* Which variables are needed, supplied by parser */
 temp->changes = NULL;  /* Which variables are altered, as "uses" */
 temp->prev = src;
 temp->text = NULL;
 now = temp;
 
 return 0;
}

int bubble (stmt *src)
{       /* Take a statement and move it as high in the control graph */
        /* as is possible without causing calculation causality problems */
 int    count = 0, ok = 1;      /* How far we moved, whether a move is good */
 stmt   *temp, *addon, *shadow;
                                /* Loop counting pointers */
 var    *i, *j;                 /* Other loop counting pointers */

 if (src == NULL) return 0;
 while (ok && src->prev != top)
        {
         temp = src->prev;      /* Don't need to check "also"'s because */
         if (temp == NULL)
                {
                 ++ count;
                 break;
                }
         shadow = temp->next;   /* They've already "bubbled" passed src */
         for (i = temp->changes; i; i = i->next)           /* Check all the */
                 for (j = src->uses; j; j = j->next) /* variable lists */
                        {
                         if (i->symptr == j->symptr)    /* against another */
                                ok = 0; /* If statements conflict, don't go */
                        }
         if (ok)
                {       /* Make sure we're not in another "also" list */
                 for (addon = temp->next;  /* The head of our "also" list */
                        addon != NULL; addon = addon->also)
                                {
                                 if (addon == src) /* excise from list */
                                        shadow->also = src->also;
                                 shadow = addon;
                                }
                 for (addon = temp; addon->also; addon = addon->also)
                        ;       /* Get to end of src->prev->also's list */
                 addon->also = src;
                 src->also = NULL;
                 addon = temp->prev;
                 addon->spine = temp;   /* Build the main control line */
                 temp->spine = src->spine;
                 src->prev = addon;
                }
         else
                {
                 temp->spine = src;      /* Otherwise, this is the main line */
                }
         ++count;
        }
 return count;
}

int time (stmt *start)
{       /* Traverse the graph, accumulate times */
 int    temp;

 if (start->next == NULL && start->next2 == NULL)
        return (start->time);
 if (start->next2 == NULL)
        {
         temp = start->time + time (start->next);
         return temp;
        }
 temp = start->time + MAX (time (start->next), time (start->next2));
 return temp;
}

stmt * reduce (stmt *start, stmt *finish)
{
 stmt   *node, *fin;

 fin = finish;
 node = start->prev;
 if (start->prev->next == start)
        {
         start->prev->next = NULL;
         start->prev->next = finish->next;
         if (start->prev->next2 == NULL)
                start->prev->next2 = finish->next2;
        }
 else   start->prev->next2 = finish->next;

 insert ("Compound Statement", start->prev);
 node = start->prev->next;
 node->next = fin->next;
 node->next2 = fin->next2;
 if (fin->next)
        fin->next->prev = node;
 if (fin->next2)
        fin->next2->prev = node;
 finish->next = finish->next2 = start->prev = NULL;
 node->time = time (start);
 
 return start;
}

void usevar (int symbol)
{       /* This adds a variable to the list of variables */
        /* which will be referenced and/or altered in this statement */
 var    *i, *temp;

 temp = malloc (sizeof (var));
 if (temp == NULL) fprintf (stderr, "Bad malloc\n");
 temp->symptr = symbol;
 temp->next = NULL;
 i = now->uses;
 ENDOFLIST (i);
 if (i != NULL)
        i->next = temp;
 else   now->uses = temp;
}

void writevar (int symbol)
{       /* This adds a variable to the list of variables */ 
        /* which will be altered in this statement */
 var    *i, *temp;

 temp = malloc (sizeof (var));
 if (temp == NULL) fprintf (stderr, "Bad malloc\n");
 temp->symptr = symbol;
 temp->next = NULL;
 i = now->changes;
 ENDOFLIST (i);
 if (i != NULL)
        i->next = temp;
 else   now->changes = temp;
}

var * totalvar (stmt *start)
{       /* Traverse the graph, accumulate variables used and changed */
 var    *temp, *final;

 if (start->next == NULL && start->next2 == NULL)
        {
         final = getvars (start->uses);
         return final;
        }
 if (start->next2 == NULL)
        {
         temp = final = totalvar (start->next);
         ENDOFLIST (temp);
         temp->next = getvars (start->uses);
         return final;
        }
 temp = final = totalvar (start->next);
 ENDOFLIST (temp);
 temp->next = totalvar (start->next2);
 ENDOFLIST (temp);
 temp->next = getvars (start->uses);
 return final;
}

var * getvars (var *which)
{       /* Copy a linked list of variables */
 var    *temp, *shadow, *trav, *final;
 
 temp = final = malloc (sizeof (var));
 if (temp == NULL) fprintf (stderr, "can\'t getvars, bad malloc\n");
 for (trav = which; trav->next; trav = trav->next)
        /* Left->Right short circuit */
        if (trav)
        {
         memcpy (temp, trav, sizeof (var));
         temp->next = malloc (sizeof (var));
         if (temp->next == NULL) fprintf (stderr, "can\'t make next var\n");
         shadow = temp;
         temp = temp->next;
        }
 free (temp);
 shadow->next = NULL;
 return (final);
}

int optimize (stmt *start)
{       /* Traverse the graph, parallelizing each node */
 int    temp;

 if (start == NULL) return 0;           /* Can't do this with nothing */
 temp = optimize (start->next);         /* Go "left" */
 temp += optimize (start->next2);       /* Go "right" */
 temp += bubble (start);                /* Lift the node */
 
 return temp;                           /* Return the number of changes */
}

void dumpVHDL (stmt *start)
{       /* Traverse the spine, printing each level */
 stmt   *temp, *level, *save[16];
 int    i = 0, lev = 0;

 for (temp = start; temp; temp = temp->spine)
        {                       /* Run down the spine */
         for (level = temp; level; level = level->also)
                {
                 if (level) if (level->type != LOOP && level->text)
                        {
                         if (level != top && level != top->next)
                                {
                                 printf ("process csl%d is\nbegin\n", i);
				 printf ("if csl%d = 1 then\n", i);
                                 printf ("\t%s\n", level->text);
                                 printf ("end;\n\n");
                                }
                         else
                                {
                                 printf ("%s\n\n", level->text);
                                }
                        }
                }
         ++i;   /* Next control signal */
        }
 
 printf ("Begin\n");
 /* Now output the control unit */
 i = 0;
 for (temp = start; temp; temp = temp->spine)
        {                       /* Run down the spine again */
         if (temp->type == LOOP)
		{
		 printf ("%s\n", temp->text);
		 save[lev++] = temp->next2;
		}
	 else	printf ("csl%d <= 0; csl%d <= 1; -- Stage %d\n", i - 1, i, lev);
	 if (save[lev] == temp)
		{
		 printf ("end loop;\n");
		 --lev;
		}
         ++i;   /* Next control signal */
        }
 printf ("end;\n");
}
