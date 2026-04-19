# --- Variables ---
CC = gcc
# Ajout de -I. pour que les fichiers dans build/ trouvent les .h dans le dossier principal
CFLAGS = -Wall -g -I.
BISON = bison
FLEX = flex

EXEC = franc
BUILD_DIR = build

# Les fichiers .o seront tous placés dans le dossier build/
OBJS = $(BUILD_DIR)/franc.tab.o $(BUILD_DIR)/ast.o $(BUILD_DIR)/symbole.o

# --- Règles principales ---
all: $(EXEC)

# Crée le dossier build s'il n'existe pas
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(EXEC): $(OBJS)
	$(CC) $(CFLAGS) -o $(EXEC) $(OBJS)

# --- Règles de génération ---

# Règle générique pour compiler les .c du dossier principal vers build/
$(BUILD_DIR)/%.o: %.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

# franc.tab.o est une exception car ses sources (.c) sont générées dans build/
$(BUILD_DIR)/franc.tab.o: $(BUILD_DIR)/franc.tab.c $(BUILD_DIR)/lex.yy.c ast.h symbole.h | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $(BUILD_DIR)/franc.tab.c -o $@

# Exécuter Bison (génère dans build/)
$(BUILD_DIR)/franc.tab.c $(BUILD_DIR)/franc.tab.h: franc.y | $(BUILD_DIR)
	$(BISON) -d franc.y -o $(BUILD_DIR)/franc.tab.c

# Exécuter Flex (génère dans build/)
$(BUILD_DIR)/lex.yy.c: franc.l $(BUILD_DIR)/franc.tab.h | $(BUILD_DIR)
	$(FLEX) -o $(BUILD_DIR)/lex.yy.c franc.l

# --- Règle de nettoyage ---
clean:
	rm -rf $(BUILD_DIR) $(EXEC)
