/* --- symbole.c --- */
#include "symbole.h"

/* Initialisation de la tête de liste */
Symbole *table_symboles = NULL;
Fonction *table_fonctions = NULL;

/* Recherche un symbole par son nom */
Symbole *rechercher_symbole(char *nom) {
  Symbole *courant = table_symboles;
  while (courant != NULL) {
    if (strcmp(courant->nom, nom) == 0) {
      return courant;
    }
    courant = courant->suivant;
  }
  return NULL;
}

/* Ajoute un nouveau symbole à la table */
void ajouter_symbole(char *nom, TypeVar type, bool est_constante, double valeur,
                     char *valeur_chaine) {
  if (rechercher_symbole(nom) != NULL) {
    fprintf(
        stderr,
        "Erreur semantique (Ligne %d) : La variable '%s' est deja declaree.\n",
        yylineno, nom);
    erreurs_totales++;
    return;
  }

  Symbole *nouveau = (Symbole *)malloc(sizeof(Symbole));
  if (nouveau == NULL)
    exit(1);

  nouveau->nom = strdup(nom);
  nouveau->type = type;
  nouveau->est_constante = est_constante;
  nouveau->valeur = valeur;

  /* Si c'est une chaine, on copie le texte, sinon NULL */
  if (valeur_chaine != NULL) {
    nouveau->valeur_chaine = strdup(valeur_chaine);
  } else {
    nouveau->valeur_chaine = NULL;
  }

  nouveau->suivant = table_symboles;
  table_symboles = nouveau;
  printf("[Info] Variable '%s' ajoutee a la table des symboles.\n", nom);
}

Fonction *rechercher_fonction(char *nom) {
  Fonction *courant = table_fonctions;
  while (courant != NULL) {
    if (strcmp(courant->nom, nom) == 0) {
      return courant;
    }
    courant = courant->suivant;
  }
  return NULL;
}

void ajouter_fonction(char *nom, struct Noeud *corps) {
  if (rechercher_fonction(nom) != NULL) {
    fprintf(
        stderr,
        "Erreur semantique (Ligne %d) : La fonction '%s' est deja declaree.\n",
        yylineno, nom);
    erreurs_totales++;
    return;
  }

  Fonction *nouvelle = (Fonction *)malloc(sizeof(Fonction));
  if (nouvelle == NULL) {
    fprintf(stderr, "Erreur fatale : Plus de memoire disponible.\n");
    exit(1);
  }

  nouvelle->nom = strdup(nom);
  nouvelle->corps = corps;

  nouvelle->suivant = table_fonctions;
  table_fonctions = nouvelle;

  printf("[Info] Fonction '%s' compilee et ajoutee a la memoire.\n", nom);
}
