%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

/* --- SYMBOL TABLE STRUCTURE --- */
typedef enum {
    VAR_ENTIER,
    VAR_REEL
} TypeVar;

typedef struct Symbole {
    char *nom;
    TypeVar type;
    bool est_constante;
    double valeur;
    struct Symbole *suivant;
} Symbole;

/* --- TYPES DE NOEUDS POUR L'AST --- */
typedef enum {
    NODE_NOMBRE,
    NODE_IDENTIFIANT,
    NODE_OPERATION,   
    NODE_AFFECTATION, 
    NODE_AFFICHER,    
    NODE_SI,          
    NODE_SEQUENCE,     
    NODE_TANT_QUE     
} TypeNoeud;

/* --- STRUCTURE D'UN NOEUD DE L'ARBRE --- */
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

/* --- VARIABLES GLOBALES --- */
Noeud *racine_programme = NULL;
extern int yylineno;          
int erreurs_totales = 0;  
Symbole *table_symboles = NULL;
double executer_ast(Noeud *n);

/* --- PROTOTYPES DES FONCTIONS --- */
int yylex(void);
int yyerror(const char *s);
void ajouter_symbole(char *nom, TypeVar type, bool est_constante, double valeur);
Symbole* rechercher_symbole(char *nom);

/* Prototypes pour les constructeurs d'AST (Pour eviter les erreurs de conversion int/pointeur) */
Noeud* creer_noeud_nombre(double valeur);
Noeud* creer_noeud_identifiant(char *nom);
Noeud* creer_noeud_operation(int operateur, Noeud *gauche, Noeud *droite);
Noeud* creer_noeud_affectation(char *nom, Noeud *expression);
Noeud* creer_noeud_afficher(Noeud *expression);
Noeud* creer_noeud_sequence(Noeud *instruction1, Noeud *instruction2);
Noeud* creer_noeud_si(Noeud *condition, Noeud *branche_si, Noeud *branche_sinon);
Noeud* creer_noeud_tant_que(Noeud *condition, Noeud *corps);

%}

/* --- BISON TOKENS & TYPES --- */
%union {
    int entier;
    double reel;
    char caractere;
    char *chaine;
    struct Noeud *noeud; 
}

%token TYPE_ENTIER TYPE_REEL TYPE_CARACTERE CONSTANTE VIDE AFFICHER
%token SI SINON TANT_QUE RETOURNE
%token EGAL DIFF INFEG SUPEG ET OU

%token <entier> NOMBRE
%token <reel> REEL
%token <caractere> CARACTERE_VAL
%token <chaine> IDENTIFIANT

/* Start rule */
/* --- PRECEDENCE DES OPERATEURS --- */
%left OU
%left ET
%left EGAL DIFF
%left '<' '>' INFEG SUPEG
%left '+' '-'
%left '*' '/'
%left '(' ')'

%type <noeud> expression instruction affectation affichage declaration liste_instructions bloc_instructions instruction_si instruction_boucle programme
%start programme

%%
/* --- REGLES DE GRAMMAIRE --- */

programme:
    liste_instructions { 
        racine_programme = $1; 
        printf("\nAnalyse terminee avec succes. Arbre syntaxique genere.\n"); 
    }
    | /* vide */ { racine_programme = NULL; }
    ;

liste_instructions:
    instruction { $$ = $1; }
    | liste_instructions instruction { $$ = creer_noeud_sequence($1, $2); }
    ;

instruction:
    declaration { $$ = $1; }
    | affectation { $$ = $1; }
    | affichage { $$ = $1; }
    | instruction_si { $$ = $1; }
    | instruction_boucle { $$ = $1; }
    ;

/* --- BLOC D'INSTRUCTIONS (Pour le contenu des Si/Sinon) --- */
bloc_instructions:
    '{' liste_instructions '}' { $$ = $2; }
    | '{' '}' { $$ = NULL; } /* Bloc vide */
    ;

/* --- LOGIQUE SI / SINON SI / SINON --- */
instruction_si:
    SI '(' expression ')' bloc_instructions {
        $$ = creer_noeud_si($3, $5, NULL);
    }
    | SI '(' expression ')' bloc_instructions SINON bloc_instructions {
        $$ = creer_noeud_si($3, $5, $7);
    }
    | SI '(' expression ')' bloc_instructions SINON instruction_si {
        
        $$ = creer_noeud_si($3, $5, $7);
    }
    ;

/* --- LOGIQUE DE BOUCLE --- */
instruction_boucle:
    TANT_QUE '(' expression ')' bloc_instructions {
        $$ = creer_noeud_tant_que($3, $5);
    }
    ;

/* --- DECLARATIONS --- */
declaration:
    TYPE_ENTIER IDENTIFIANT ';' {
        /* Enregistre la variable, mais ne crée pas de noeud d'action à exécuter */
        ajouter_symbole($2, VAR_ENTIER, false, 0);
        $$ = NULL; 
    }
    | TYPE_ENTIER IDENTIFIANT '=' expression ';' {
        ajouter_symbole($2, VAR_ENTIER, false, 0);
        /* L'affectation se fera à l'exécution de l'arbre */
        $$ = creer_noeud_affectation($2, $4);
    }
    | CONSTANTE TYPE_ENTIER IDENTIFIANT '=' expression ';' {
        ajouter_symbole($3, VAR_ENTIER, true, 0);
        $$ = creer_noeud_affectation($3, $5);
    }
    | TYPE_REEL IDENTIFIANT ';' {
        ajouter_symbole($2, VAR_REEL, false, 0.0);
        $$ = NULL; 
    }
    | TYPE_REEL IDENTIFIANT '=' expression ';' {
        ajouter_symbole($2, VAR_REEL, false, 0.0);
        $$ = creer_noeud_affectation($2, $4);
    }

    | CONSTANTE TYPE_REEL IDENTIFIANT '=' expression ';' {
        ajouter_symbole($3, VAR_REEL, true, 0.0);
        $$ = creer_noeud_affectation($3, $5);
    }
    ;

/* --- AFFECTATIONS --- */
affectation:
    IDENTIFIANT '=' expression ';' {
        Symbole *sym = rechercher_symbole($1);
        if (sym == NULL) {
            fprintf(stderr, "Erreur semantique (Ligne %d) : La variable '%s' n'est pas declaree.\n", yylineno, $1);
            erreurs_totales++;
            $$ = NULL;
        } else if (sym->est_constante) {
            fprintf(stderr, "Erreur semantique (Ligne %d) : Impossible de modifier la constante '%s'.\n", yylineno, $1);
            erreurs_totales++;
            $$ = NULL;
        } else {
            $$ = creer_noeud_affectation($1, $3);
        }
    }
    ;

/* --- AFFICHAGE --- */
affichage:
    AFFICHER '(' expression ')' ';' {
        $$ = creer_noeud_afficher($3); 
    }
    ;

/* --- EXPRESSIONS MATHEMATIQUES ET LOGIQUES --- */
expression:
    NOMBRE { $$ = creer_noeud_nombre($1); }
    | REEL { $$ = creer_noeud_nombre($1); }
    | IDENTIFIANT {
        Symbole *sym = rechercher_symbole($1);
        if (sym == NULL) {
            fprintf(stderr, "Erreur semantique (Ligne %d) : Variable '%s' non declaree.\n", yylineno, $1);
            erreurs_totales++;
            $$ = creer_noeud_nombre(0); /* Sécurité anti-crash */
        } else {
            $$ = creer_noeud_identifiant($1);
        }
    }
    /* Mathématiques */
    | expression '+' expression { $$ = creer_noeud_operation('+', $1, $3); }
    | expression '-' expression { $$ = creer_noeud_operation('-', $1, $3); }
    | expression '*' expression { $$ = creer_noeud_operation('*', $1, $3); }
    | expression '/' expression { $$ = creer_noeud_operation('/', $1, $3); }
    /* Logique (Comparaisons pour les Si/Sinon) */
    | expression EGAL expression { $$ = creer_noeud_operation(EGAL, $1, $3); }
    | expression DIFF expression { $$ = creer_noeud_operation(DIFF, $1, $3); }
    | expression INFEG expression { $$ = creer_noeud_operation(INFEG, $1, $3); }
    | expression SUPEG expression { $$ = creer_noeud_operation(SUPEG, $1, $3); }
    | expression '<' expression { $$ = creer_noeud_operation('<', $1, $3); }
    | expression '>' expression { $$ = creer_noeud_operation('>', $1, $3); }
    | '(' expression ')' { $$ = $2; }
    ;
%%

/* --- C CODE: FUNCTIONS & MAIN --- */

/* Include Flex output */
#include "lex.yy.c"

int yyerror(const char *s) {
    fprintf(stderr, "Erreur syntaxique (Ligne %d) : %s\n", yylineno, s);
    return 0;
}

/* --- MAIN FUNCTION (From earlier) --- */
extern FILE *yyin;

int main(int argc, char **argv) {
    if (argc > 1) {
        FILE *fichier = fopen(argv[1], "r");
        if (!fichier) {
            printf("Erreur : Impossible d'ouvrir %s\n", argv[1]);
            return 1;
        }
        yyin = fichier;
        printf("\n===============================================\n");
        printf("--- Compilation du fichier : %s ---\n", argv[1]);
        printf("===============================================\n\n");
    } else {
        printf("--- Mode Interactif franC ---\n");
        printf("Tapez votre code (Ctrl+D / Ctrl+Z pour terminer) :\n");
        yyin = stdin;
    }

    int resultat = yyparse();

    /* Check both Bison's result and our custom error counter */
    if (resultat == 0 && erreurs_totales == 0) {
        printf("\n[Succes] Compilation terminee sans erreur.\n");
        printf("==============================\n");
        printf("--- Lancement du programme ---\n");
        printf("==============================\n");
        
        executer_ast(racine_programme); /* <-- L'EXECUTION COMMENCE ICI */
        
    } else {
        printf("\n[Echec] La compilation a echoue (%d erreur(s) trouvee(s)).\n", erreurs_totales);
    }

    if (argc > 1 && yyin) fclose(yyin);
    return 0;
}

/* --- FONCTIONS DE LA TABLE DES SYMBOLES --- */

/* * Recherche un symbole par son nom.
 * Retourne un pointeur vers le symbole s'il existe, ou NULL sinon.
 */
Symbole* rechercher_symbole(char *nom) {
    Symbole *courant = table_symboles;
    
    while (courant != NULL) {
        if (strcmp(courant->nom, nom) == 0) {
            return courant; /* Trouvé ! */
        }
        courant = courant->suivant;
    }
    
    return NULL; /* Non trouvé */
}

/* * Ajoute un nouveau symbole à la table.
 * Vérifie d'abord si la variable n'a pas déjà été déclarée.
 */
void ajouter_symbole(char *nom, TypeVar type, bool est_constante, double valeur) {
    if (rechercher_symbole(nom) != NULL) {
        fprintf(stderr, "Erreur semantique (Ligne %d) : La variable '%s' est deja declaree.\n", yylineno, nom);
        erreurs_totales++;
        return;
    }
    
    /* Étape 2 : Allouer de la mémoire pour le nouveau symbole */
    Symbole *nouveau = (Symbole *)malloc(sizeof(Symbole));
    if (nouveau == NULL) {
        fprintf(stderr, "Erreur fatale : Plus de memoire disponible.\n");
        exit(1);
    }
    
    /* Étape 3 : Remplir les données */
    nouveau->nom = strdup(nom); /* Copie la chaîne de caractères */
    nouveau->type = type;
    nouveau->est_constante = est_constante;
    nouveau->valeur = valeur;
    
    /* Étape 4 : Insérer en tête de la liste chaînée */
    nouveau->suivant = table_symboles;
    table_symboles = nouveau;
    
    printf("[Info] Variable '%s' ajoutee a la table des symboles.\n", nom);
}

/* --- FONCTIONS DE CREATION DE L'AST --- */

Noeud* creer_noeud_nombre(double valeur) {
    Noeud *n = (Noeud*)malloc(sizeof(Noeud));
    n->type = NODE_NOMBRE;
    n->valeur = valeur;
    n->gauche = n->droite = n->condition = n->branche_si = n->branche_sinon = NULL;
    return n;
}

Noeud* creer_noeud_identifiant(char *nom) {
    Noeud *n = (Noeud*)malloc(sizeof(Noeud));
    n->type = NODE_IDENTIFIANT;
    n->nom = strdup(nom);
    n->gauche = n->droite = n->condition = n->branche_si = n->branche_sinon = NULL;
    return n;
}

Noeud* creer_noeud_operation(int operateur, Noeud *gauche, Noeud *droite) {
    Noeud *n = (Noeud*)malloc(sizeof(Noeud));
    n->type = NODE_OPERATION;
    n->valeur = operateur; /* Stocke le code ASCII de '+', '-', etc. */
    n->gauche = gauche;
    n->droite = droite;
    n->condition = n->branche_si = n->branche_sinon = NULL;
    return n;
}

Noeud* creer_noeud_affectation(char *nom, Noeud *expression) {
    Noeud *n = (Noeud*)malloc(sizeof(Noeud));
    n->type = NODE_AFFECTATION;
    n->nom = strdup(nom);
    n->droite = expression; /* L'expression à évaluer et affecter */
    n->gauche = n->condition = n->branche_si = n->branche_sinon = NULL;
    return n;
}

Noeud* creer_noeud_afficher(Noeud *expression) {
    Noeud *n = (Noeud*)malloc(sizeof(Noeud));
    n->type = NODE_AFFICHER;
    n->gauche = expression; /* L'expression à afficher */
    n->droite = n->condition = n->branche_si = n->branche_sinon = NULL;
    return n;
}

Noeud* creer_noeud_sequence(Noeud *instruction1, Noeud *instruction2) {
    Noeud *n = (Noeud*)malloc(sizeof(Noeud));
    n->type = NODE_SEQUENCE;
    n->gauche = instruction1;
    n->droite = instruction2;
    n->condition = n->branche_si = n->branche_sinon = NULL;
    return n;
}

Noeud* creer_noeud_si(Noeud *condition, Noeud *branche_si, Noeud *branche_sinon) {
    Noeud *n = (Noeud*)malloc(sizeof(Noeud));
    n->type = NODE_SI;
    n->condition = condition;
    n->branche_si = branche_si;
    n->branche_sinon = branche_sinon; /* Peut être NULL s'il n'y a pas de 'sinon' */
    n->gauche = n->droite = NULL;
    return n;
}

Noeud* creer_noeud_tant_que(Noeud *condition, Noeud *corps) {
    Noeud *n = (Noeud*)malloc(sizeof(Noeud));
    n->type = NODE_TANT_QUE;
    n->condition = condition;
    n->branche_si = corps; /* On utilise branche_si pour stocker le corps de la boucle */
    n->branche_sinon = n->gauche = n->droite = NULL;
    return n;
}

/* --- MOTEUR D'EXECUTION DE L'AST --- */
double executer_ast(Noeud *n) {
    if (n == NULL) return 0.0;

    switch (n->type) {
        case NODE_NOMBRE:
            return n->valeur;

        case NODE_IDENTIFIANT: {
            Symbole *sym = rechercher_symbole(n->nom);
            if (sym != NULL) return sym->valeur;
            return 0.0; 
        }

        case NODE_OPERATION: {
            double val_gauche = executer_ast(n->gauche);
            double val_droite = executer_ast(n->droite);
            
            switch ((int)n->valeur) { /* Cast temporaire pour le switch de l'opérateur */
                case '+': return val_gauche + val_droite;
                case '-': return val_gauche - val_droite;
                case '*': return val_gauche * val_droite;
                case '/': 
                    if (val_droite == 0.0) {
                        fprintf(stderr, "Erreur fatale d'execution : Division par zero !\n");
                        exit(1); 
                    }
                    return val_gauche / val_droite;
                case '<': return val_gauche < val_droite;
                case '>': return val_gauche > val_droite;
                case EGAL: return val_gauche == val_droite;
                case DIFF: return val_gauche != val_droite;
                case INFEG: return val_gauche <= val_droite;
                case SUPEG: return val_gauche >= val_droite;
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
            printf(">>> %g\n", resultat); /* %g gère automatiquement les entiers et les réels ! */
            return 0.0;
        }

        /* ... NODE_SEQUENCE, NODE_SI, et NODE_TANT_QUE restent identiques, 
           car C interprète tout double != 0.0 comme "vrai" dans un if/while ... */
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
