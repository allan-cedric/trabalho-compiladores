
// Testar se funciona corretamente o empilhamento de par�metros
// passados por valor ou por refer�ncia.


%{
#include <stdio.h>
#include <ctype.h>
#include <stdlib.h>
#include <string.h>
#include "compilador.h"

pilha_t pil_tipo;

void verifica_tipo(tipo_t *t, int num_op);

%}

%token PROGRAM ABRE_PARENTESES FECHA_PARENTESES
%token VIRGULA PONTO_E_VIRGULA DOIS_PONTOS PONTO
%token T_BEGIN T_END VAR IDENT ATRIBUICAO

%token ROTULO TIPO VETOR DE PROCEDIMENTO FUNCAO
%token PULAR SE ENTAO SENAO ENQUANTO FACA
%token IGUAL DIFERENTE MENOR MENOR_IGUAL MAIOR_IGUAL MAIOR
%token MAIS MENOS VEZES DIVIDIDO
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

                        printf("alocado\n");
                        imprime_ts(&ts);
                     } |
; 

declara_vars:  declara_vars declara_var | 
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
               } | 
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

                  insere_ts(&ts, &novo_simb);

                  num_vars++;
                  num_vars_por_tipo++;
               } |
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

                  insere_ts(&ts, &novo_simb);

                  num_vars++;
                  num_vars_por_tipo++;
               }
;

lista_idents:  lista_idents VIRGULA IDENT | 
               IDENT
;

comando_composto: T_BEGIN comandos T_END
                  {
                     int i = ts.topo;
                     int nivel_lexico_corrente = ts.tabela[i].nivel_lexico;
                     int conta_vars = 0;
                     while(i >= 0 && 
                           ts.tabela[i].nivel_lexico == nivel_lexico_corrente) {
                           conta_vars++;
                           i--;
                     }
                     retira_ts(&ts, conta_vars);

                     char dmem[TAM_ID];
                     sprintf(dmem, "DMEM %i", conta_vars);
                     geraCodigo(NULL, dmem);

                     printf("desalocado\n");
                     imprime_ts(&ts);
                  } |
                  T_BEGIN T_END
;

comandos:   comandos comando |
            comando
;

comando: comando_sem_rotulo
;

comando_sem_rotulo:  atribuicao
;

atribuicao: variavel_esq ATRIBUICAO expressao
            {
               tipo_t t;
               verifica_tipo(&t, 2);

               simples_t *atrib = ts.tabela[l_elem].atrib_vars;
               char armz[TAM_ID];
               sprintf(armz, "ARMZ %i,%i", ts.tabela[l_elem].nivel_lexico, atrib->deslocamento);
               geraCodigo(NULL, armz);
            }
            PONTO_E_VIRGULA
;

expressao: expressao_simples expr_opcional
;

expr_opcional: relacao expressao_simples
               {
                  tipo_t t;
                  verifica_tipo(&t, 2);
                  desempilha(&pil_tipo);
                  empilha(&pil_tipo, booleano);

                  if(t != inteiro && t != booleano)
                     imprimeErro("tipos incompativeis");

                  if(relacao == simb_igual)
                     geraCodigo(NULL, "CMIG");
                  else if(relacao == simb_diferente)
                     geraCodigo(NULL, "CMDG");
                  else if(t != booleano) {
                     if(relacao == simb_menor)
                        geraCodigo(NULL, "CMME");
                     else if(relacao == simb_menor_igual)
                        geraCodigo(NULL, "CMEG");
                     else if(relacao == simb_maior)
                        geraCodigo(NULL, "CMMA");
                     else if(relacao == simb_maior_igual)
                        geraCodigo(NULL, "CMAG");
                  }else
                     imprimeErro("tipos incompativeis");
               } |
;

relacao: IGUAL 
         {
            relacao = simb_igual;
         } |
         DIFERENTE 
         {
            relacao = simb_diferente;
         } |
         MENOR 
         {
            relacao = simb_menor;
         } |
         MENOR_IGUAL 
         {
            relacao = simb_menor_igual;
         } |
         MAIOR_IGUAL 
         {
            relacao = simb_maior_igual;
         } |
         MAIOR
         {
            relacao = simb_maior;
         } 
;

expressao_simples:   termo |
                     MAIS termo 
                     {
                        tipo_t t;
                        verifica_tipo(&t, 1);

                        if(t != inteiro)
                           imprimeErro("tipos incompativeis");
                     }|
                     MENOS termo
                     {
                        tipo_t t;
                        verifica_tipo(&t, 1);

                        if(t != inteiro)
                           imprimeErro("tipos incompativeis");

                        geraCodigo(NULL, "IVNR");
                     }  
                     |
                     expressao_simples MAIS termo
                     {
                        tipo_t t;
                        verifica_tipo(&t, 2);

                        if(t != inteiro)
                           imprimeErro("tipos incompativeis");

                        geraCodigo(NULL, "SOMA");
                     } |
                     expressao_simples MENOS termo 
                     {
                        tipo_t t;
                        verifica_tipo(&t, 2);

                        if(t != inteiro)
                           imprimeErro("tipos incompativeis");

                        geraCodigo(NULL, "SUBT");
                     } |
                     expressao_simples OU termo
                     {
                        tipo_t t;
                        verifica_tipo(&t, 2);

                        if(t != booleano)
                           imprimeErro("tipos incompativeis");

                        geraCodigo(NULL, "DISJ");
                     } 
;

termo:   fator |
         termo VEZES fator 
         {
            tipo_t t;
            verifica_tipo(&t, 2);

            if(t != inteiro)
               imprimeErro("tipos incompativeis");

            geraCodigo(NULL, "MULT");
         } |
         termo DIVIDIDO fator 
         {
            tipo_t t;
            verifica_tipo(&t, 2);

            if(t != inteiro)
               imprimeErro("tipos incompativeis");

            geraCodigo(NULL, "DIVI");
         } |
         termo E fator
         {
            tipo_t t;
            verifica_tipo(&t, 2);

            if(t != booleano)
               imprimeErro("tipos incompativeis");

            geraCodigo(NULL, "CONJ");
         } 
;

fator:   variavel |
         numero |
         ABRE_PARENTESES expressao FECHA_PARENTESES |
         NAO fator
         {
            tipo_t t;
            verifica_tipo(&t, 1);

            if(t != booleano)
               imprimeErro("tipos incompativeis");

            geraCodigo(NULL, "NEGA");
         } 
;

variavel:   IDENT
            {
               int indice = busca_ts(&ts, token);

               if(indice == -1)
                  imprimeErro("variavel nao declarada");
               
               if(ts.tabela[indice].categoria != simples)
                  imprimeErro("variavel nao eh simples");

               simples_t *atrib = ts.tabela[indice].atrib_vars;
               empilha(&pil_tipo, atrib->tipo);

               char crvl[TAM_ID];
               sprintf(crvl, "CRVL %i,%i", ts.tabela[indice].nivel_lexico, atrib->deslocamento);
               geraCodigo(NULL, crvl);
            }
;

variavel_esq:  IDENT
               {
                  l_elem = busca_ts(&ts, token);

                  if(l_elem == -1)
                     imprimeErro("variavel nao declarada");
                  
                  if(ts.tabela[l_elem].categoria != simples)
                     imprimeErro("variavel nao eh simples");

                  simples_t *atrib = ts.tabela[l_elem].atrib_vars;
                  empilha(&pil_tipo, atrib->tipo);
               }
;

numero:  NUMERO
         {
            empilha(&pil_tipo, inteiro);

            char crct[TAM_ID];
            sprintf(crct, "CRCT %s", token);
            geraCodigo(NULL, crct);
         }
;

%%

void verifica_tipo(tipo_t *t, int num_op) {

   if(num_op == 2) {
      tipo_t tipo_op1 = topo_pil(&pil_tipo); desempilha(&pil_tipo);
      tipo_t tipo_op2 = topo_pil(&pil_tipo);

      if(tipo_op1 != tipo_op2)
         imprimeErro("tipos incompativeis");

      *t = tipo_op1;
   }else if(num_op == 1) {
      tipo_t tipo_op1 = topo_pil(&pil_tipo);

      *t = tipo_op1;
   }
}

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
   inicializa_ts(&ts);
   nivel_lexico = -1;

   inicializa_pil(&pil_tipo);

   yyin=fp;
   yyparse();

   return 0;
}
