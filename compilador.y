
// Testar se funciona corretamente o empilhamento de par�metros
// passados por valor ou por refer�ncia.


%{
#include <stdio.h>
#include <ctype.h>
#include <stdlib.h>
#include <string.h>
#include "compilador.h"

%}

%token PROGRAM ABRE_PARENTESES FECHA_PARENTESES
%token VIRGULA PONTO_E_VIRGULA DOIS_PONTOS PONTO
%token T_BEGIN T_END VAR IDENT ATRIBUICAO

%token ROTULO TIPO VETOR DE PROCEDIMENTO FUNCAO
%token PULAR SE ENTAO SENAO ENQUANTO FACA
%token IGUAL DIFERENTE MENOR MENOR_IGUAL MAIOR_IGUAL MAIOR
%token ADICAO SUBTRACAO MULTIPLICACAO DIVISAO
%token NAO E OU ABRE_COLCHETES FECHA_COLCHETES
%token NUMERO

%token INTEIRO BOOLEANO

%%

programa    :  {
                  geraCodigo (NULL, "INPP");
               }
               PROGRAM IDENT ABRE_PARENTESES lista_idents FECHA_PARENTESES PONTO_E_VIRGULA
               bloco PONTO
               {
                  geraCodigo (NULL, "PARA");
               }
;

bloco       :
               parte_declara_vars
               {
               }

               comando_composto
               ;

parte_declara_vars:  {
                        nivel_lexico++;
                        num_vars = 0;
                     } 
                     VAR declara_vars 
                     {
                        char amem_k[TAM_ID];
                        sprintf(amem_k, "AMEM %i", num_vars);
                        geraCodigo(NULL, amem_k);

                        imprime(&ts);
                     }
                     | 

declara_vars:  declara_vars declara_var
               | 
               declara_var
;

declara_var :  {
                  num_vars_por_tipo = 0;
               }
               lista_id_var DOIS_PONTOS tipo
               {
                  int i = ts.topo, j = num_vars_por_tipo;
                  while(i >= 0 && j > 0)
                  {
                     simples_t *atrib = ts.tabela[i].atrib_vars;
                     atrib->tipo = tipo_corrente;
                     i--;
                     j--;
                  }
               }
               PONTO_E_VIRGULA
;

tipo        :  INTEIRO
               {
                  tipo_corrente = inteiro;
               }
               | 
               BOOLEANO
               {
                  tipo_corrente = booleano;
               }
;

lista_id_var:  lista_id_var VIRGULA IDENT
               { /* insere �ltima vars na tabela de s�mbolos */
                  simb_t novo_simb;
                  strncpy(novo_simb.id, token, strlen(token) + 1);
                  novo_simb.categoria = simples;
                  novo_simb.nivel_lexico = nivel_lexico;
                  
                  novo_simb.atrib_vars = (simples_t *)malloc(sizeof(simples_t));
                  if(!novo_simb.atrib_vars) {
                     fprintf(stderr, "erro de alocacao de memoria!\n");
                     exit(-1);
                  }

                  simples_t *atrib = novo_simb.atrib_vars;
                  atrib->deslocamento = num_vars;

                  insere(&ts, &novo_simb);

                  num_vars++;
                  num_vars_por_tipo++;
               }
               |
               IDENT 
               { /* insere vars na tabela de s�mbolos */
                  simb_t novo_simb;
                  strncpy(novo_simb.id, token, strlen(token) + 1);
                  novo_simb.categoria = simples;
                  novo_simb.nivel_lexico = nivel_lexico;
                  
                  novo_simb.atrib_vars = (simples_t *)malloc(sizeof(simples_t));
                  if(!novo_simb.atrib_vars) {
                     fprintf(stderr, "erro de alocacao de memoria!\n");
                     exit(-1);
                  }

                  simples_t *atrib = novo_simb.atrib_vars;
                  atrib->deslocamento = num_vars;

                  insere(&ts, &novo_simb);

                  num_vars++;
                  num_vars_por_tipo++;
               }
;

lista_idents:  lista_idents VIRGULA IDENT
               | 
               IDENT
;

comando_composto: T_BEGIN comandos T_END

comandos:
;

%%

int main (int argc, char** argv) {
   FILE* fp;
   extern FILE* yyin;

   if (argc<2 || argc>2) {
         printf("usage compilador <arq>a %d\n", argc);
         return(-1);
      }

   fp=fopen (argv[1], "r");
   if (fp == NULL) {
      printf("usage compilador <arq>b\n");
      return(-1);
   }


/* -------------------------------------------------------------------
 *  Inicia a Tabela de S�mbolos
 * ------------------------------------------------------------------- */
   inicializa(&ts);
   nivel_lexico = -1;

   yyin=fp;
   yyparse();

   return 0;
}
