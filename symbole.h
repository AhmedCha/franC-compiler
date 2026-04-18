/* --- symbole.h --- */
#ifndef SYMBOLE_H
#define SYMBOLE_H

#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Types de variables supportés */
typedef enum { VAR_ENTIER, VAR_REEL } TypeVar;

/* Structure d'un symbole (variable ou constante) */
typedef struct Symbole {
  char *nom;
  TypeVar type;
  bool est_constante;
  double valeur; /* Utilise double pour supporter les entiers et les réels */
  struct Symbole *suivant;
} Symbole;

/* Variables globales définies ailleurs (dans franc.y/lex) */
extern Symbole *table_symboles;
extern int yylineno;
extern int erreurs_totales;

/* Prototypes des fonctions */
void ajouter_symbole(char *nom, TypeVar type, bool est_constante,
                     double valeur);
Symbole *rechercher_symbole(char *nom);

#endif
