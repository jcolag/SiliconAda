/* Graph.h:  Header file for the graph data structure as well */
/*	as the transformation algorithm */

#define DECL    1
#define COND    2
#define LOOP    4
#define SIMP    8
#define MAX(a,b)        (((a)>(b))?(a):(b))

/* Variables for each statement need to be listed */
typedef struct  var
        {
         int    symptr;         /* an entry in the symbol table */
         int    sub;            /* if an array/aggregate, subscript/offset */
         struct var     *next;  /* next in list */
        } var;

/* Also, each statement needs to be stored:
        If (cond) then (next1) else (next2);
        Loop (test) (next1 .. next2);
        etc...
*/
typedef struct  stmt
        {
         char   *text;          /* Actual Ada statement */
         int    type;           /* Type of statement */
         int    time;           /* in "cp", for entire statement */
         var    *uses;          /* Variables needed for calculation */
         var    *changes;       /* Variables changed in calculation */
         struct stmt    *prev;  /* The previous statement */
         struct stmt    *next, *next2;
                                /* "next" is the next step executed:
                                for a true conditional (next2 if false)
                                to begin a loop (next2 is end of loop) */
         struct stmt    *spine; /* For the optimization phase, "next cp" */
         struct stmt    *also;  /* As spine, but "same cp" */
        } stmt;

int insert (char *, stmt *);
                                /* Takes parsed statement and adds to graph */
int bubble (stmt *);            /* Optimizes time on graph */
int time (stmt *);              /* Calculates amount of time needed */
stmt * reduce (stmt *, stmt *);   /* Modifies block of statments to act
                                                as a single statement
                                                (copies original) */
var * getuses (char *);
var * getchgs (char *);

void usevar (int);
void writevar (int);

int optimize (stmt *);
void dumpVHDL (stmt *);
void init (void);
