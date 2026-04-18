/* --- symbole.c --- */
#include "symbole.h"

/* Initialisation de la tête de liste */
Symbole *table_symboles = NULL;

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
void ajouter_symbole(char *nom, TypeVar type, bool est_constante,
                     double valeur) {
  if (rechercher_symbole(nom) != NULL) {
    fprintf(
        stderr,
        "Erreur semantique (Ligne %d) : La variable '%s' est deja declaree.\n",
        yylineno, nom);
    erreurs_totales++;
    return;
  }

  Symbole *nouveau = (Symbole *)malloc(sizeof(Symbole));
  if (nouveau == NULL) {
    fprintf(stderr, "Erreur fatale : Plus de memoire disponible.\n");
    exit(1);
  }

  nouveau->nom = strdup(nom);
  nouveau->type = type;
  nouveau->est_constante = est_constante;
  nouveau->valeur = valeur;

  /* Insérer en tête de la liste chaînée */
  nouveau->suivant = table_symboles;
  table_symboles = nouveau;

  printf("[Info] Variable '%s' ajoutee a la table des symboles.\n", nom);
}
