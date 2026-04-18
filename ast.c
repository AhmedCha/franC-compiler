/* --- ast.c --- */
#include "ast.h"
#include "franc.tab.h" /* Obligatoire pour obtenir les tokens de Bison (EGAL, DIFF, etc.) */

/* --- CONSTRUCTEURS --- */

Noeud *creer_noeud_nombre(double valeur) {
  Noeud *n = (Noeud *)malloc(sizeof(Noeud));
  n->type = NODE_NOMBRE;
  n->valeur = valeur;
  n->gauche = n->droite = n->condition = n->branche_si = n->branche_sinon =
      NULL;
  return n;
}

Noeud *creer_noeud_identifiant(char *nom) {
  Noeud *n = (Noeud *)malloc(sizeof(Noeud));
  n->type = NODE_IDENTIFIANT;
  n->nom = strdup(nom);
  n->gauche = n->droite = n->condition = n->branche_si = n->branche_sinon =
      NULL;
  return n;
}

Noeud *creer_noeud_operation(int operateur, Noeud *gauche, Noeud *droite) {
  Noeud *n = (Noeud *)malloc(sizeof(Noeud));
  n->type = NODE_OPERATION;
  n->valeur = (double)operateur;
  n->gauche = gauche;
  n->droite = droite;
  n->condition = n->branche_si = n->branche_sinon = NULL;
  return n;
}

Noeud *creer_noeud_affectation(char *nom, Noeud *expression) {
  Noeud *n = (Noeud *)malloc(sizeof(Noeud));
  n->type = NODE_AFFECTATION;
  n->nom = strdup(nom);
  n->droite = expression;
  n->gauche = n->condition = n->branche_si = n->branche_sinon = NULL;
  return n;
}

Noeud *creer_noeud_afficher(Noeud *expression) {
  Noeud *n = (Noeud *)malloc(sizeof(Noeud));
  n->type = NODE_AFFICHER;
  n->gauche = expression;
  n->droite = n->condition = n->branche_si = n->branche_sinon = NULL;
  return n;
}

Noeud *creer_noeud_sequence(Noeud *instruction1, Noeud *instruction2) {
  Noeud *n = (Noeud *)malloc(sizeof(Noeud));
  n->type = NODE_SEQUENCE;
  n->gauche = instruction1;
  n->droite = instruction2;
  n->condition = n->branche_si = n->branche_sinon = NULL;
  return n;
}

Noeud *creer_noeud_si(Noeud *condition, Noeud *branche_si,
                      Noeud *branche_sinon) {
  Noeud *n = (Noeud *)malloc(sizeof(Noeud));
  n->type = NODE_SI;
  n->condition = condition;
  n->branche_si = branche_si;
  n->branche_sinon = branche_sinon;
  n->gauche = n->droite = NULL;
  return n;
}

Noeud *creer_noeud_tant_que(Noeud *condition, Noeud *corps) {
  Noeud *n = (Noeud *)malloc(sizeof(Noeud));
  n->type = NODE_TANT_QUE;
  n->condition = condition;
  n->branche_si = corps;
  n->branche_sinon = n->gauche = n->droite = NULL;
  return n;
}

/* --- MOTEUR D'EXECUTION --- */

double executer_ast(Noeud *n) {
  if (n == NULL)
    return 0.0;

  switch (n->type) {
  case NODE_NOMBRE:
    return n->valeur;

  case NODE_IDENTIFIANT: {
    Symbole *sym = rechercher_symbole(n->nom);
    if (sym != NULL)
      return sym->valeur;
    return 0.0;
  }

  case NODE_OPERATION: {
    double val_gauche = executer_ast(n->gauche);
    double val_droite = executer_ast(n->droite);

    switch ((int)n->valeur) {
    case '+':
      return val_gauche + val_droite;
    case '-':
      return val_gauche - val_droite;
    case '*':
      return val_gauche * val_droite;
    case '/':
      if (val_droite == 0.0) {
        fprintf(stderr, "Erreur fatale d'execution : Division par zero !\n");
        exit(1);
      }
      return val_gauche / val_droite;
    case '<':
      return val_gauche < val_droite;
    case '>':
      return val_gauche > val_droite;
    case EGAL:
      return val_gauche == val_droite;
    case DIFF:
      return val_gauche != val_droite;
    case INFEG:
      return val_gauche <= val_droite;
    case SUPEG:
      return val_gauche >= val_droite;
    }
    break;
  }

  case NODE_AFFECTATION: {
    double resultat = executer_ast(n->droite);
    Symbole *sym = rechercher_symbole(n->nom);
    if (sym != NULL) {
      sym->valeur = resultat;
    }
    return resultat;
  }

  case NODE_AFFICHER: {
    double resultat = executer_ast(n->gauche);
    printf(">>> %g\n", resultat);
    return 0.0;
  }

  case NODE_SEQUENCE: {
    executer_ast(n->gauche);
    executer_ast(n->droite);
    return 0.0;
  }

  case NODE_SI: {
    double condition = executer_ast(n->condition);
    if (condition != 0.0) {
      executer_ast(n->branche_si);
    } else if (n->branche_sinon != NULL) {
      executer_ast(n->branche_sinon);
    }
    return 0.0;
  }

  case NODE_TANT_QUE: {
    while (executer_ast(n->condition) != 0.0) {
      executer_ast(n->branche_si);
    }
    return 0.0;
  }
  }
  return 0.0;
}
