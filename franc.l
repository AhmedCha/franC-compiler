%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "franc.tab.h" 
%}

/* This option tells Flex we are only reading one file, saving us from writing yywrap() */
%option noyywrap 
%option yylineno
%option nounput
%option noinput

%%
"//".* { /* Ignore single-line comments */ }
[ \t\n\r]+              { /* Ignore whitespace and newlines */ }

    /* --- KEYWORDS --- */
"entier"                { return TYPE_ENTIER; }
"reel"                  { return TYPE_REEL; }
"caractere"             { return TYPE_CARACTERE; }
"constante"             { return CONSTANTE; }
"afficher"              { return AFFICHER; }
"si"                    { return SI; }
"sinon"                 { return SINON; }
"tant_que"              { return TANT_QUE; }
"vide"                  { return VIDE; }
"fonction"              { return FONCTION; }
"retourne"              { return RETOURNE; }

    /* --- MULTI-CHARACTER OPERATORS --- */
"=="                    { return EGAL; }
"!="                    { return DIFF; }
"<="                    { return INFEG; }
">="                    { return SUPEG; }
"&&"|"et"               { return ET; }
"||"|"ou"               { return OU; }

    /* --- IDENTIFIERS (Variable and Function names) --- */
[a-zA-Z_][a-zA-Z0-9_]* { 
                            yylval.chaine = strdup(yytext); 
                            return IDENTIFIANT; 
                        }

    /* --- INTEGERS  --- */
[0-9]+                  { 
                            yylval.entier = atoi(yytext); 
                            return NOMBRE; 
                        }

    /* --- FLOATS  --- */
[0-9]+\.[0-9]+([eE][-+]?[0-9]+)?|[0-9]+[eE][-+]?[0-9]+ {
                            yylval.reel = atof(yytext); /* Convertit la chaîne en 'double' C */
                            return REEL;
                        }

    /* --- CHARACTERS (e.g., 'a', 'Z') --- */
\'[^\']\'               { 
                            yylval.caractere = yytext[1]; 
                            return CARACTERE_VAL; 
                        }

    /* --- SINGLE CHARACTER TOKENS --- */
    
[-+*/=<>!{};(),]        { return yytext[0]; }

    /* --- ERROR HANDLING --- */
.                       { 
                            fprintf(stderr, "Erreur lexicale (Ligne %d) : caractere non reconnu '%s'\n", yylineno, yytext); 
                            erreurs_totales++;
                        }
%%
