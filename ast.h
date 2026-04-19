/* --- ast.h --- */
#ifndef AST_H
#define AST_H

#include "symbole.h"

/* Types de noeuds pour l'AST */
typedef enum {
  NODE_NOMBRE,
  NODE_IDENTIFIANT,
  NODE_OPERATION,
  NODE_AFFECTATION,
  NODE_AFFICHER,
  NODE_SI,
  NODE_SEQUENCE,
  NODE_TANT_QUE,
  NODE_APPEL,
  NODE_RETOURNE
} TypeNoeud;

/* Structure d'un noeud de l'arbre */
typedef struct Noeud {
  TypeNoeud type;
  double valeur;
  char *nom;

  struct Noeud *gauche;
  struct Noeud *droite;

  struct Noeud *condition;
  struct Noeud *branche_si;
  struct Noeud *branche_sinon;
} Noeud;

/* Prototypes de création */
Noeud *creer_noeud_nombre(double valeur);
Noeud *creer_noeud_identifiant(char *nom);
Noeud *creer_noeud_operation(int operateur, Noeud *gauche, Noeud *droite);
Noeud *creer_noeud_affectation(char *nom, Noeud *expression);
Noeud *creer_noeud_afficher(Noeud *expression);
Noeud *creer_noeud_sequence(Noeud *instruction1, Noeud *instruction2);
Noeud *creer_noeud_si(Noeud *condition, Noeud *branche_si,
                      Noeud *branche_sinon);
Noeud *creer_noeud_tant_que(Noeud *condition, Noeud *corps);
Noeud *creer_noeud_appel(char *nom);
Noeud *creer_noeud_retourne(Noeud *expression);

/* Prototype d'exécution */
double executer_ast(Noeud *n);

#endif
