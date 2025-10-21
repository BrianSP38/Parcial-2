CC = gcc
BISON = bison
FLEX = flex

all: db

db.tab.c db.tab.h: db.y
	$(BISON) -d db.y

lex.yy.c: db.l db.tab.h
	$(FLEX) db.l

db: db.tab.c lex.yy.c
	$(CC) -o db db.tab.c lex.yy.c -lfl

clean:
	rm -f db db.tab.c db.tab.h lex.yy.c
