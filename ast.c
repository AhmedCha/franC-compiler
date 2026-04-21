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

Noeud *creer_noeud_caractere(char c) {
  Noeud *n = (Noeud *)malloc(sizeof(Noeud));
  n->type = NODE_CARACTERE;
  n->valeur = (double)c; /* Stocké comme code ASCII */
  n->gauche = n->droite = n->condition = n->branche_si = n->branche_sinon =
      NULL;
  return n;
}

Noeud *creer_noeud_chaine(char *texte) {
  Noeud *n = (Noeud *)malloc(sizeof(Noeud));
  n->type = NODE_CHAINE;
  n->chaine_val = strdup(texte);
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

Noeud *creer_noeud_appel(char *nom) {
  Noeud *n = (Noeud *)malloc(sizeof(Noeud));
  n->type = NODE_APPEL;
  n->nom = strdup(nom);
  n->gauche = n->droite = n->condition = n->branche_si = n->branche_sinon =
      NULL;
  return n;
}

Noeud *creer_noeud_retourne(Noeud *expression) {
  Noeud *n = (Noeud *)malloc(sizeof(Noeud));
  n->type = NODE_RETOURNE;
  n->gauche = expression; /* La valeur à renvoyer */
  n->droite = n->condition = n->branche_si = n->branche_sinon = NULL;
  return n;
}

/* --- MOTEUR D'EXECUTION --- */
bool retour_declenche = false;
double valeur_retour = 0.0;

double executer_ast(Noeud *n) {
  if (n == NULL)
    return 0.0;

  switch (n->type) {
  case NODE_NOMBRE:
    return n->valeur;

  case NODE_CARACTERE:
    return n->valeur;

  case NODE_CHAINE:
    return 0.0;

  case NODE_IDENTIFIANT: {
    Symbole *sym = rechercher_symbole(n->nom);
    if (sym != NULL)
      return sym->valeur;
    return 0.0;
  }

  case NODE_OPERATION: {
    double val_gauche = executer_ast(n->gauche);

    if ((int)n->valeur == ET) {
      if (val_gauche == 0.0)
        return 0.0;
      return (executer_ast(n->droite) != 0.0) ? 1.0 : 0.0;
    }
    if ((int)n->valeur == OU) {
      if (val_gauche != 0.0)
        return 1.0;
      return (executer_ast(n->droite) != 0.0) ? 1.0 : 0.0;
    }

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
    Symbole *sym = rechercher_symbole(n->nom);
    if (sym != NULL) {
      /* Si c'est une affectation de chaine */
      if (sym->type == VAR_CHAINE && n->droite->type == NODE_CHAINE) {
        if (sym->valeur_chaine)
          free(sym->valeur_chaine);
        sym->valeur_chaine = strdup(n->droite->chaine_val);
        return 0.0;
      }
      /* Sinon (nombres, caractères) */
      double resultat = executer_ast(n->droite);
      sym->valeur = resultat;
      return resultat;
    }
    return 0.0;
  }

  case NODE_AFFICHER: {
    /* L'intelligence de l'affichage ! */
    if (n->gauche->type == NODE_CHAINE) {
      printf(">>> %s\n", n->gauche->chaine_val);
      return 0.0;
    }
    if (n->gauche->type == NODE_CARACTERE) {
      printf(">>> %c\n", (char)n->gauche->valeur);
      return 0.0;
    }
    if (n->gauche->type == NODE_IDENTIFIANT) {
      Symbole *sym = rechercher_symbole(n->gauche->nom);
      if (sym != NULL) {
        if (sym->type == VAR_CARACTERE) {
          printf(">>> %c\n", (char)sym->valeur);
          return 0.0;
        }
        if (sym->type == VAR_CHAINE) {
          printf(">>> %s\n", sym->valeur_chaine);
          return 0.0;
        }
      }
    }
    double resultat = executer_ast(n->gauche);
    printf(">>> %g\n", resultat);
    return 0.0;
  }

  case NODE_SEQUENCE: {
    executer_ast(n->gauche);
    /* Ne pas exécuter la suite si un "retourne" a été lu ! */
    if (!retour_declenche) {
      executer_ast(n->droite);
    }
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

  case NODE_APPEL: {
    Fonction *fonc = rechercher_fonction(n->nom);
    if (fonc == NULL) {
      fprintf(stderr, "Erreur d'execution : La fonction '%s' n'existe pas.\n",
              n->nom);
      exit(1);
    }

    /* Sauvegarde l'état du retour au cas où une fonction en appelle une autre
     * (récursion) */
    bool backup_retour = retour_declenche;
    retour_declenche = false;

    /* Exécute le corps de la fonction ! */
    executer_ast(fonc->corps);

    /* Capture la valeur de retour, puis réinitialise les flags */
    double resultat = valeur_retour;
    retour_declenche = backup_retour;
    valeur_retour = 0.0;

    return resultat;
  }

  case NODE_RETOURNE: {
    /* On calcule la valeur, on active le flag d'arrêt, et on remonte ! */
    valeur_retour = executer_ast(n->gauche);
    retour_declenche = true;
    return valeur_retour;
  }
  }
  return 0.0;
}
