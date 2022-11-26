%{

#include <stdio.h>
#include <ctype.h>
#include <stdlib.h>
#include <string.h>
#include "compilador.h"

pilha_t pil_tipo, pil_rot;
char idr[TAM_ID];
int num_rot = 0;
int pass_ref;

void insere_nova_var();
void insere_novo_param();
void insere_novo_proc();
void read_var();
void op_unaria(tipos tipo);
void op_binaria(tipos tipo);
void verifica_tipo(tipos *t, int num_op);

%}

%token PROGRAM ABRE_PARENTESES FECHA_PARENTESES
%token VIRGULA PONTO_E_VIRGULA DOIS_PONTOS PONTO
%token T_BEGIN T_END VAR IDENT ATRIBUICAO

%token LABEL TYPE ARRAY OF PROCEDURE FUNCTION
%token GOTO IF THEN ELSE WHILE DO
%token IGUAL DIFERENTE MENOR MENOR_IGUAL MAIOR_IGUAL MAIOR
%token MAIS MENOS VEZES DIVIDIDO
%token NOT AND OR ABRE_COLCHETES FECHA_COLCHETES
%token NUMERO

%token INTEGER BOOLEAN

%token READ WRITE

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

programa :  { geraCodigo (NULL, "INPP"); }
            PROGRAM IDENT ABRE_PARENTESES lista_idents FECHA_PARENTESES PONTO_E_VIRGULA
            bloco PONTO
            { geraCodigo (NULL, "PARA"); }
;

bloco :  parte_declara_vars
         parte_declara_subrotinas
         comando_composto
         {
            if(!ts_vazia(&ts)) {
               int conta_simb = 0;
               for(int i = ts.topo; i >= 0; i--) {
                  if(ts.tabela[i].nivel_lexico <= nivel_lexico && 
                     ts.tabela[i].categoria == procedimento)
                     break;
                  conta_simb++;
               }

               if(conta_simb > 0) {
                  retira_ts(&ts, conta_simb);

                  char dmem[TAM_ID];
                  sprintf(dmem, "DMEM %i", conta_simb);
                  geraCodigo(NULL, dmem);

                  // printf("desalocado\n");
               }
            }
            // imprime_ts(&ts);
         }
;

parte_declara_vars   :  { num_vars = 0; } 
                        VAR declara_vars 
                        {
                           char amem_k[TAM_ID];
                           sprintf(amem_k, "AMEM %i", num_vars);
                           geraCodigo(NULL, amem_k);

                           // printf("alocado\n");
                           // imprime_ts(&ts);
                        } |
; 

declara_vars   :  declara_vars declara_var 
                  | declara_var
;

declara_var :  { num_vars_por_tipo = 0; }
               lista_id_var DOIS_PONTOS tipo
               {
                  int i = ts.topo, j = num_vars_por_tipo;
                  while(i >= 0 && j > 0)
                  {
                     var_simples_t *atrib = ts.tabela[i].atrib_vars;
                     atrib->tipo = tipo_corrente;
                     i--; j--;
                  }
               }
               PONTO_E_VIRGULA
;

tipo  :  INTEGER { tipo_corrente = inteiro; } 
         | BOOLEAN { tipo_corrente = booleano; }
;

lista_id_var   :  lista_id_var VIRGULA IDENT { insere_nova_var(); } 
                  | IDENT { insere_nova_var(); }
;

lista_idents   :  lista_idents VIRGULA IDENT 
                  | IDENT
;

parte_declara_subrotinas   :  {
                                 char dsvs[TAM_ID];
                                 sprintf(dsvs, "DSVS R%02i", num_rot);                                 
                                 geraCodigo(NULL, dsvs);
                                 empilha(&pil_rot, num_rot);
                                 num_rot++;
                              }
                              declara_subrotinas
                              {
                                 char rot[TAM_ID];
                                 sprintf(rot, "R%02i", topo_pil(&pil_rot));
                                 desempilha(&pil_rot, 1);
                                 geraCodigo(rot, "NADA");
                              }
                              |
;

declara_subrotinas   :  declara_subrotinas declara_procedimento PONTO_E_VIRGULA
                        | declara_subrotinas declara_funcao PONTO_E_VIRGULA
                        | declara_procedimento PONTO_E_VIRGULA
                        | declara_funcao PONTO_E_VIRGULA
;

declara_procedimento :  PROCEDURE IDENT
                        {
                           insere_novo_proc();

                           char enpr[TAM_ID];
                           sprintf(enpr, "ENPR %i", ts.tabela[ts.topo].nivel_lexico);
                           procedimento_t *atrib = ts.tabela[ts.topo].atrib_vars;
                           geraCodigo(atrib->rot_interno, enpr);
                        }
                        param_formais PONTO_E_VIRGULA bloco
                        {
                           int i;
                           for(i = ts.topo; i >= 0; i--) {
                              if(ts.tabela[i].categoria == procedimento &&
                                 ts.tabela[i].nivel_lexico == nivel_lexico)
                                 break;
                           }

                           char rtpr[TAM_ID];
                           procedimento_t *atrib = ts.tabela[i].atrib_vars;
                           sprintf(rtpr, "RTPR %i,%i", nivel_lexico, atrib->n_params);
                           geraCodigo(NULL, rtpr);
                           desempilha(&pil_rot, 1);
                           nivel_lexico--;
                        }
;

declara_funcao :
;

param_formais  :  ABRE_PARENTESES secao_param FECHA_PARENTESES
                  |
;

secao_param :  secao_param PONTO_E_VIRGULA secao_param_formais
               | secao_param_formais
;

secao_param_formais  :  var_opcional lista_id_param DOIS_PONTOS tipo
;

var_opcional   :  VAR { pass_ref = 1; }
                  | { pass_ref = 0; }
;

lista_id_param   :   lista_id_param VIRGULA IDENT { insere_novo_param(); } 
                     | IDENT { insere_novo_param(); }
;

comando_composto  :  T_BEGIN comandos T_END 
                     | T_BEGIN T_END
;

comandos :  comandos comando PONTO_E_VIRGULA 
            | comando PONTO_E_VIRGULA
;

comando  :  comando_sem_rotulo
;

comando_sem_rotulo   :  misc 
                        | comando_repetitivo 
                        | leitura 
                        | impressao 
                        | comando_composto 
                        | comando_condicional
;

misc  :  IDENT { strncpy(idr, token, strlen(token) + 1); } 
         fatora
;

fatora   :  ATRIBUICAO
            {
               l_elem = busca_ts(&ts, idr);

               if(l_elem == -1)
                  imprimeErro("variavel nao declarada");
               
               if(ts.tabela[l_elem].categoria != simples)
                  imprimeErro("variavel nao eh simples");

               var_simples_t *atrib = ts.tabela[l_elem].atrib_vars;
               empilha(&pil_tipo, atrib->tipo);
            }
            atribuicao
            | chamada_procedimento
            {
               int indice = busca_ts(&ts, idr);

               if(indice == -1)
                  imprimeErro("procedimento nao declarado");

               if(ts.tabela[indice].categoria != procedimento)
                  imprimeErro("categoria incompativel");

               char chpr[TAM_ID * 2];
               procedimento_t *atrib = ts.tabela[indice].atrib_vars;
               sprintf(chpr, "CHPR %s,%i", atrib->rot_interno, nivel_lexico);
               geraCodigo(NULL, chpr);
            }
;

leitura  :  READ ABRE_PARENTESES le_var FECHA_PARENTESES
;

le_var   :  le_var VIRGULA IDENT { read_var(); } 
            | IDENT { read_var(); }
;

impressao   :  WRITE ABRE_PARENTESES impr_var_ou_num FECHA_PARENTESES
;

impr_var_ou_num   :  impr_var_ou_num VIRGULA variavel { geraCodigo(NULL, "IMPR"); } 
                     | impr_var_ou_num VIRGULA numero { geraCodigo(NULL, "IMPR"); }
                     | variavel { geraCodigo(NULL, "IMPR"); }
                     | numero { geraCodigo(NULL, "IMPR"); }
;

comando_repetitivo   :  WHILE
                        {
                           char rot[TAM_ID];
                           sprintf(rot, "R%02i", num_rot);
                           empilha(&pil_rot, num_rot);
                           empilha(&pil_rot, num_rot + 1);
                           geraCodigo(rot, "NADA");
                           num_rot += 2;
                        }
                        expressao
                        {
                           char dsvf[TAM_ID];
                           sprintf(dsvf, "DSVF R%02i", topo_pil(&pil_rot));
                           geraCodigo(NULL, dsvf);
                        } 
                        DO comando_sem_rotulo
                        {
                           int rot_saida = topo_pil(&pil_rot); desempilha(&pil_rot, 1);
                           int rot_entrada = topo_pil(&pil_rot); desempilha(&pil_rot, 1);

                           char dsvs[TAM_ID];
                           sprintf(dsvs, "DSVS R%02i", rot_entrada);
                           geraCodigo(NULL, dsvs);

                           char rot[TAM_ID];
                           sprintf(rot, "R%02i", rot_saida);
                           geraCodigo(rot, "NADA");
                        }
;

comando_condicional  :  IF expressao
                        {
                           char dsvf[TAM_ID];
                           sprintf(dsvf, "DSVF R%02i", num_rot);
                           empilha(&pil_rot, num_rot);
                           empilha(&pil_rot, num_rot + 1);
                           geraCodigo(NULL, dsvf);
                           num_rot += 2;
                        }
                        THEN comando_sem_rotulo 
                        {
                           char dsvs[TAM_ID];
                           sprintf(dsvs, "DSVS R%02i", topo_pil(&pil_rot));
                           geraCodigo(NULL, dsvs);
                        }
                        else
                        {
                           char rot[TAM_ID];
                           sprintf(rot, "R%02i", topo_pil(&pil_rot));
                           geraCodigo(rot, "NADA");

                           desempilha(&pil_rot, 2);
                        }
;

else  :  ELSE
         {
            char rot[TAM_ID];
            sprintf(rot, "R%02i", topo_pil(&pil_rot) - 1);
            geraCodigo(rot, "NADA");
         }
         comando_sem_rotulo
         | %prec LOWER_THAN_ELSE
;

chamada_procedimento :  lista_expressoes
                        |
;

lista_expressoes  :  ABRE_PARENTESES lista_expressao FECHA_PARENTESES
;

lista_expressao   :  lista_expressao VIRGULA expressao
                     | expressao
;

atribuicao  :  expressao
               {
                  tipos t;
                  verifica_tipo(&t, 2);

                  var_simples_t *atrib = ts.tabela[l_elem].atrib_vars;
                  char armz[TAM_ID];
                  sprintf(armz, "ARMZ %i,%i", ts.tabela[l_elem].nivel_lexico, atrib->deslocamento);
                  geraCodigo(NULL, armz);

                  l_elem = -1;
               }
;

expressao   : expressao_simples expr_opcional
;

expr_opcional  :  relacao expressao_simples
                  {
                     tipos t;
                     verifica_tipo(&t, 2);
                     desempilha(&pil_tipo, 1);
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

relacao  :  IGUAL { relacao = simb_igual; } 
            | DIFERENTE { relacao = simb_diferente; } 
            | MENOR { relacao = simb_menor; } 
            | MENOR_IGUAL { relacao = simb_menor_igual; } 
            | MAIOR_IGUAL { relacao = simb_maior_igual; } 
            | MAIOR { relacao = simb_maior; } 
;

expressao_simples :  termo 
                     | MAIS termo { op_unaria(inteiro); }
                     | MENOS termo
                     {
                        op_unaria(inteiro);
                        geraCodigo(NULL, "IVNR");
                     } 
                     | expressao_simples MAIS termo
                     {
                        op_binaria(inteiro);
                        geraCodigo(NULL, "SOMA");
                     } 
                     | expressao_simples MENOS termo 
                     {
                        op_binaria(inteiro);
                        geraCodigo(NULL, "SUBT");
                     } 
                     | expressao_simples OR termo
                     {
                        op_binaria(booleano);
                        geraCodigo(NULL, "DISJ");
                     } 
;

termo :  fator 
         | termo VEZES fator 
         {
            op_binaria(inteiro);
            geraCodigo(NULL, "MULT");
         } 
         | termo DIVIDIDO fator 
         {
            op_binaria(inteiro);
            geraCodigo(NULL, "DIVI");
         } 
         | termo AND fator
         {
            op_binaria(booleano);
            geraCodigo(NULL, "CONJ");
         } 
;

fator :  variavel 
         | numero 
         | ABRE_PARENTESES expressao FECHA_PARENTESES 
         | NOT fator
         {
            op_unaria(booleano);
            geraCodigo(NULL, "NEGA");
         } 
;

variavel :  IDENT
            {
               int indice = busca_ts(&ts, token);

               if(indice == -1)
                  imprimeErro("variavel nao declarada");
               
               if(ts.tabela[indice].categoria != simples)
                  imprimeErro("variavel nao eh simples");

               var_simples_t *atrib = ts.tabela[indice].atrib_vars;
               empilha(&pil_tipo, atrib->tipo);

               char crvl[TAM_ID];
               sprintf(crvl, "CRVL %i,%i", ts.tabela[indice].nivel_lexico, atrib->deslocamento);
               geraCodigo(NULL, crvl);
            }
;

numero   :  NUMERO
            {
               int eh_booleano = 0;
               if(l_elem != -1) {
                  var_simples_t *atrib = ts.tabela[l_elem].atrib_vars;
                  if(atrib->tipo == booleano) {
                     if(!strcmp(token, "0") || !strcmp(token, "1"))
                        eh_booleano = 1;
                  }
               }

               if(eh_booleano)
                  empilha(&pil_tipo, booleano);
               else
                  empilha(&pil_tipo, inteiro);

               char crct[TAM_ID];
               sprintf(crct, "CRCT %s", token);
               geraCodigo(NULL, crct);
            }
;

%%

void insere_nova_var() {

   simb_t novo_simb;
   strncpy(novo_simb.id, token, strlen(token) + 1);
   novo_simb.categoria = simples;
   novo_simb.nivel_lexico = nivel_lexico;
   
   novo_simb.atrib_vars = (var_simples_t *)malloc(sizeof(var_simples_t));
   if(!novo_simb.atrib_vars) {
      fprintf(stderr, "erro de alocacao de memoria!\n");
      exit(-1);
   }

   var_simples_t *atrib = novo_simb.atrib_vars;
   atrib->deslocamento = num_vars;

   insere_ts(&ts, &novo_simb);

   num_vars++; num_vars_por_tipo++;
}

void insere_novo_param() {

}

void insere_novo_proc() {

   simb_t novo_simb;
   strncpy(novo_simb.id, token, strlen(token) + 1);
   novo_simb.categoria = procedimento;
   novo_simb.nivel_lexico = ++nivel_lexico;
   
   novo_simb.atrib_vars = (procedimento_t *)malloc(sizeof(procedimento_t));
   if(!novo_simb.atrib_vars) {
      fprintf(stderr, "erro de alocacao de memoria!\n");
      exit(-1);
   }

   procedimento_t *atrib = novo_simb.atrib_vars;
   sprintf(atrib->rot_interno, "R%02i", num_rot);
   atrib->n_params = 0;
   atrib->params = NULL;

   insere_ts(&ts, &novo_simb);

   empilha(&pil_rot, num_rot);
   num_rot++;
}

void read_var() {

   geraCodigo(NULL, "LEIT");

   int indice = busca_ts(&ts, token);

   if(indice == -1)
      imprimeErro("variavel nao declarada");

   if(ts.tabela[indice].categoria != simples)
      imprimeErro("categoria incompativel");

   var_simples_t *atrib = ts.tabela[indice].atrib_vars;

   char armz[TAM_ID];
   sprintf(armz, "ARMZ %i,%i", ts.tabela[indice].nivel_lexico, atrib->deslocamento);

   geraCodigo(NULL, armz);
}

void op_unaria(tipos tipo) {

   tipos t;
   verifica_tipo(&t, 1);

   if(t != tipo)
      imprimeErro("tipos incompativeis");
}

void op_binaria(tipos tipo) {

   tipos t;
   verifica_tipo(&t, 2);

   if(t != tipo)
      imprimeErro("tipos incompativeis");
}

void verifica_tipo(tipos *t, int num_op) {

   if(num_op == 2) {
      tipos tipo_op1 = topo_pil(&pil_tipo); desempilha(&pil_tipo, 1);
      tipos tipo_op2 = topo_pil(&pil_tipo);

      if(tipo_op1 != tipo_op2)
         imprimeErro("tipos incompativeis");

      *t = tipo_op1;
   }else if(num_op == 1) {
      tipos tipo_op1 = topo_pil(&pil_tipo);

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
   nivel_lexico = 0;
   l_elem = -1;

   inicializa_pil(&pil_tipo);
   inicializa_pil(&pil_rot);

   yyin=fp;
   yyparse();

   return 0;
}
