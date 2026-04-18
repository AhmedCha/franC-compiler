# --- Variables ---
CC = gcc
CFLAGS = -Wall -g
BISON = bison
FLEX = flex

EXEC = franc

# When adding new files just add the .o here
OBJS = franc.tab.o ast.o symbole.o

# --- Main rules ---
all: $(EXEC)

$(EXEC): $(OBJS)
	$(CC) $(CFLAGS) -o $(EXEC) $(OBJS)

# --- Generation rules ---

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

franc.tab.o: franc.tab.c lex.yy.c ast.h symbole.h
	$(CC) $(CFLAGS) -c franc.tab.c

# Execute Bison 
franc.tab.c franc.tab.h: franc.y
	$(BISON) -d franc.y

# Executer Flex 
lex.yy.c: franc.l franc.tab.h
	$(FLEX) franc.l

# --- Cleaning rules ---
clean:
	rm -f *.o franc.tab.c franc.tab.h lex.yy.c $(EXEC)
