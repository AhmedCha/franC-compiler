%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

/* Inclusion de nos nouveaux modules ! */
#include "ast.h" 

/* --- VARIABLES GLOBALES --- */
Noeud *racine_programme = NULL;
extern int yylineno;          
int erreurs_totales = 0;  

/* --- PROTOTYPES DES FONCTIONS --- */
int yylex(void);
int yyerror(const char *s);
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
        ajouter_symbole($2, VAR_ENTIER, false, 0);
        $$ = NULL; 
    }
    | TYPE_ENTIER IDENTIFIANT '=' expression ';' {
        ajouter_symbole($2, VAR_ENTIER, false, 0);
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

/* --- MAIN FUNCTION --- */
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
