CC=gcc
LEX=flex -l
YACC=byacc -drtv
CFLAGS= -c --ansi -pedantic-errors -Wall -g
#CFLAGS= -c -mh -v -lv
RM=rm -f

sa:  rw.o symtab.o graph.o lex.yy.o y.tab.o y.code.o main.o
	$(CC) -osa rw.o symtab.o graph.o lex.yy.o y.tab.o y.code.o main.o

main.o:	main.c graph.h y.tab.h
	$(CC) $(CFLAGS) main.c

rw.o:	  rw.c y.tab.h ada.y
	$(CC) $(CFLAGS) rw.c

symtab.o:      symtab.c symtab.h
	$(CC) $(CFLAGS) symtab.c

graph.o:       graph.c graph.h
	$(CC) $(CFLAGS) graph.c

lex.yy.o:       lex.yy.c
	$(CC) $(CFLAGS) lex.yy.c

lex.yy.c:	 ada.l
	$(LEX) ada.l

y.tab.o:       y.tab.c y.tab.h ada.y
	$(CC) $(CFLAGS) y.tab.c

y.code.o:      y.code.c y.tab.h ada.y graph.h
	$(CC) $(CFLAGS) y.code.c

y.code.c:	ada.y
	$(YACC) ada.y

y.tab.c:	 ada.y
	$(YACC) ada.y

y.tab.h:	 ada.y
	$(YACC) ada.y

clean:
	$(RM) y.code.c  y.output  y.tab.c  y.tab.h *.o lex.yy.c

