/*
  compilador.y: Regras gramaticais do compilador

  Autor: Allan Cedric G. B. Alves da Silva
  Ultima modificacao: 17/12/2022 
*/

%{

#include "compilador.h"

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

// 1. regra programa
programa :  { geraCodigo (NULL, "INPP"); }
            PROGRAM IDENT ABRE_PARENTESES lista_idents FECHA_PARENTESES PONTO_E_VIRGULA
            bloco PONTO
            { geraCodigo (NULL, "PARA"); }
;

lista_idents   :  lista_idents VIRGULA IDENT 
                  | IDENT
;

// 2. regra bloco
bloco :  parte_declara_vars
         parte_declara_subrotinas
         comando_composto { desaloca_bloco(); }
;

// 6. regra tipo
tipo  :  INTEGER { tipo_corrente = inteiro; } 
         | BOOLEAN { tipo_corrente = booleano; }
;

// 8. regra parte de declaracoes de variaveis
parte_declara_vars   :  { num_vars = 0; } 
                        VAR declara_vars 
                        { aloca_vars(); } 
                        |
; 

// 9. regra declaracao de variaveis
declara_vars   :  declara_vars declara_var 
                  | declara_var
;

declara_var :  { num_vars_por_tipo = 0; }
               lista_id_var DOIS_PONTOS tipo
               { atualiza_tipo_vars(); }
               PONTO_E_VIRGULA
;

// 10. regra lista de identificadores
lista_id_var   :  lista_id_var VIRGULA IDENT { insere_nova_var(); } 
                  | IDENT { insere_nova_var(); }
;

// 11. regra parte de declaracoes de sub-rotinas
parte_declara_subrotinas   :  { desvia_subrotina(); }
                              declara_subrotinas
                              { alvo_desvia_subrotina(); }
                              |
;

declara_subrotinas   :  declara_subrotinas declara_procedimento PONTO_E_VIRGULA
                        | declara_subrotinas declara_funcao PONTO_E_VIRGULA
                        | declara_procedimento PONTO_E_VIRGULA
                        | declara_funcao PONTO_E_VIRGULA
;

// 12. regra declaracao de procedimento
declara_procedimento :  PROCEDURE IDENT
                        { insere_novo_proc(); }
                        param_formais PONTO_E_VIRGULA bloco
                        { finaliza_declara_proc(); }
;

// 14. regra parametros formais
param_formais  :  { num_params = 0; }
                  ABRE_PARENTESES secao_param FECHA_PARENTESES
                  { finaliza_declara_params(); }
                  |
;

// 15. regra secao de parametros formais
secao_param :  secao_param PONTO_E_VIRGULA secao_param_formais
               | secao_param_formais
;

secao_param_formais  :  { num_params_por_tipo = 0; }
                        var_opcional lista_id_param_formal DOIS_PONTOS tipo
                        { atualiza_tipo_params(); }
;

var_opcional   :  VAR { pass_ref = 1; }
                  | { pass_ref = 0; }
;

lista_id_param_formal   :  lista_id_param_formal VIRGULA IDENT { insere_novo_param(); } 
                           | IDENT { insere_novo_param(); }
;

declara_funcao :  FUNCTION IDENT
                  {
                     insere_nova_func();

                     char enpr[TAM_ID];
                     sprintf(enpr, "ENPR %i", ts.tabela[ts.topo].nivel_lexico);
                     funcao_t *atrib = ts.tabela[ts.topo].atrib_vars;
                     geraCodigo(atrib->rot_interno, enpr);
                  }
                  param_formais DOIS_PONTOS tipo
                  { 
                     funcao_t *atrib = ts.tabela[indice_proc].atrib_vars;
                     atrib->retorno = tipo_corrente;
                  }
                  PONTO_E_VIRGULA bloco
                  {
                     int i;
                     for(i = ts.topo; i >= 0; i--) {
                        if(ts.tabela[i].categoria == funcao &&
                           ts.tabela[i].nivel_lexico == nivel_lexico)
                           break;
                     }

                     char rtpr[TAM_ID];
                     funcao_t *atrib = ts.tabela[i].atrib_vars;
                     sprintf(rtpr, "RTPR %i,%i", nivel_lexico, atrib->n_params);
                     geraCodigo(NULL, rtpr);
                     desempilha(&pil_rot, 1);
                     retira_ts(&ts, atrib->n_params);
                     nivel_lexico--;

                     #ifdef DEPURACAO
                        printf("\e[1;1H\e[2J");
                        printf("\033[0;31m");
                        printf("desalocado:\n");
                        printf("\033[0m");
                        imprime_ts(&ts);
                        getchar();
                     #endif
                  }
;

comando_composto  :  T_BEGIN comandos T_END 
                     | T_BEGIN T_END
;

comandos :  comandos PONTO_E_VIRGULA comando 
            | comando
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

               if(ts.tabela[l_elem].categoria == simples) {
                  var_simples_t *atrib = ts.tabela[l_elem].atrib_vars;
                  empilha(&pil_tipo, atrib->tipo);
               } else if(ts.tabela[l_elem].categoria == param_formal) {
                  param_formal_t *atrib = ts.tabela[l_elem].atrib_vars;
                  empilha(&pil_tipo, atrib->tipo);
               } else if(ts.tabela[l_elem].categoria == funcao){

                  if(ts.tabela[l_elem].nivel_lexico != nivel_lexico)
                     imprimeErro("variavel de acesso restrito");
                  
                  int i;
                  for(i = ts.topo; i >= 0; i--) {
                     if(ts.tabela[i].categoria == funcao &&
                        ts.tabela[i].nivel_lexico == nivel_lexico)
                        break;
                  }

                  if(i == -1 || strcmp(ts.tabela[i].id, idr))
                     imprimeErro("variavel de acesso restrito");

                  funcao_t *atrib = ts.tabela[l_elem].atrib_vars;
                  empilha(&pil_tipo, atrib->retorno);
               } else
                  imprimeErro("categoria incompativel");
            }
            atribuicao
            |
            {
               indice_proc = busca_ts(&ts, idr);

               if(indice_proc == -1)
                  imprimeErro("procedimento nao declarado");

               if(ts.tabela[indice_proc].categoria != procedimento)
                  imprimeErro("categoria incompativel");
               
               empilha(&pil_proc, indice_proc);
            } 
            chamada_procedimento
            {
               indice_proc = topo_pil(&pil_proc);
               procedimento_t *atrib = ts.tabela[indice_proc].atrib_vars;

               if(num_expr != atrib->n_params)
                  imprimeErro("qtd. errada de parametros");

               char chpr[TAM_ID * 2];
               sprintf(chpr, "CHPR %s,%i", atrib->rot_interno, nivel_lexico);
               geraCodigo(NULL, chpr);

               desempilha(&pil_proc, 1);
            }
;

leitura  :  READ ABRE_PARENTESES le_var FECHA_PARENTESES
;

le_var   :  le_var VIRGULA IDENT { read_var(); } 
            | IDENT { read_var(); }
;

impressao   :  WRITE ABRE_PARENTESES impr_var_ou_num FECHA_PARENTESES
;

impr_var_ou_num   :  impr_var_ou_num VIRGULA misc2 { geraCodigo(NULL, "IMPR"); } 
                     | impr_var_ou_num VIRGULA numero { geraCodigo(NULL, "IMPR"); }
                     | misc2 { geraCodigo(NULL, "IMPR"); }
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
                           
                           char rot[TAM_ID];
                           sprintf(rot, "R%02i", topo_pil(&pil_rot) - 1);
                           geraCodigo(rot, "NADA");
                        }
                        else
                        {
                           char rot[TAM_ID];
                           sprintf(rot, "R%02i", topo_pil(&pil_rot));
                           geraCodigo(rot, "NADA");

                           desempilha(&pil_rot, 2);
                        }
;

else  :  ELSE comando_sem_rotulo
         | %prec LOWER_THAN_ELSE
;

chamada_procedimento :  { num_expr = 0; }
                        ABRE_PARENTESES lista_expressoes FECHA_PARENTESES
                        | { num_expr = 0; }
;

lista_expressoes  :  lista_expressoes VIRGULA 
                     { empilha(&pil_expr, 0); }
                     expressao 
                     {
                        int tipo_expr = topo_pil(&pil_tipo); 
                        desempilha(&pil_tipo, 1);

                        indice_proc = topo_pil(&pil_proc);

                        param_formal_t *params;
                        if(ts.tabela[indice_proc].categoria == procedimento) {
                           procedimento_t *atrib = ts.tabela[indice_proc].atrib_vars;
                           params = atrib->params;
                        } else {
                           funcao_t *atrib = ts.tabela[indice_proc].atrib_vars;
                           params = atrib->params;
                        }

                        if(params[num_expr].passagem == referencia && 
                           topo_pil(&pil_expr) != 0)
                           imprimeErro("parametro real deve ser uma variavel simples");

                        if(tipo_expr != params[num_expr].tipo)
                           imprimeErro("tipos incompativeis - lista_expressoes");

                        desempilha(&pil_expr, 1);
                        num_expr++;
                     }
                     | { empilha(&pil_expr, 0); } 
                     expressao 
                     { 
                        int tipo_expr = topo_pil(&pil_tipo); 
                        desempilha(&pil_tipo, 1);

                        indice_proc = topo_pil(&pil_proc);

                        param_formal_t *params;
                        if(ts.tabela[indice_proc].categoria == procedimento) {
                           procedimento_t *atrib = ts.tabela[indice_proc].atrib_vars;
                           params = atrib->params;
                        } else {
                           funcao_t *atrib = ts.tabela[indice_proc].atrib_vars;
                           params = atrib->params;
                        }

                        if(params[num_expr].passagem == referencia && 
                           topo_pil(&pil_expr) != 0)
                           imprimeErro("parametro real deve ser uma variavel simples");

                        if(tipo_expr != params[num_expr].tipo)
                           imprimeErro("tipos incompativeis - lista_expressoes");

                        desempilha(&pil_expr, 1);
                        num_expr++;
                     }
;

atribuicao  :  expressao
               {
                  tipos t;
                  verifica_tipo(&t, 2);

                  char armz[TAM_ID];
                  if(ts.tabela[l_elem].categoria == simples) {
                     var_simples_t *atrib = ts.tabela[l_elem].atrib_vars;
                     sprintf(armz, "ARMZ %i,%i", ts.tabela[l_elem].nivel_lexico, atrib->deslocamento);
                  }else if(ts.tabela[l_elem].categoria == param_formal) {
                     param_formal_t *atrib = ts.tabela[l_elem].atrib_vars;
                     if(atrib->passagem == valor)
                        sprintf(armz, "ARMZ %i,%i", ts.tabela[l_elem].nivel_lexico, atrib->deslocamento);
                     else
                        sprintf(armz, "ARMI %i,%i", ts.tabela[l_elem].nivel_lexico, atrib->deslocamento);
                  }else if(ts.tabela[l_elem].categoria == funcao) {
                     funcao_t *atrib = ts.tabela[l_elem].atrib_vars;
                     sprintf(armz, "ARMZ %i,%i", ts.tabela[l_elem].nivel_lexico, -(atrib->n_params + 4));
                  }else
                     imprimeErro("categoria incompativel");

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
                        imprimeErro("tipos incompativeis - expr_opcional");

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
                        imprimeErro("tipos incompativeis - expr_opcional");

                     pil_expr.pilha[pil_expr.topo] = 1;
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
                     | MAIS termo 
                     { 
                        pil_expr.pilha[pil_expr.topo] = 1;
                        op_unaria(inteiro); 
                     }
                     | MENOS termo
                     {
                        pil_expr.pilha[pil_expr.topo] = 1;
                        op_unaria(inteiro);
                        geraCodigo(NULL, "IVNR");
                     } 
                     | expressao_simples MAIS termo
                     {
                        pil_expr.pilha[pil_expr.topo] = 1;
                        op_binaria(inteiro);
                        geraCodigo(NULL, "SOMA");
                     } 
                     | expressao_simples MENOS termo 
                     {
                        pil_expr.pilha[pil_expr.topo] = 1;
                        op_binaria(inteiro);
                        geraCodigo(NULL, "SUBT");
                     } 
                     | expressao_simples OR termo
                     {
                        pil_expr.pilha[pil_expr.topo] = 1;
                        op_binaria(booleano);
                        geraCodigo(NULL, "DISJ");
                     } 
;

termo :  fator 
         | termo VEZES fator 
         {
            pil_expr.pilha[pil_expr.topo] = 1;
            op_binaria(inteiro);
            geraCodigo(NULL, "MULT");
         } 
         | termo DIVIDIDO fator 
         {
            pil_expr.pilha[pil_expr.topo] = 1;
            op_binaria(inteiro);
            geraCodigo(NULL, "DIVI");
         } 
         | termo AND fator
         {
            pil_expr.pilha[pil_expr.topo] = 1;
            op_binaria(booleano);
            geraCodigo(NULL, "CONJ");
         } 
;

fator :  misc2 
         | numero { pil_expr.pilha[pil_expr.topo] = 1; } 
         | ABRE_PARENTESES expressao FECHA_PARENTESES 
         | NOT fator
         {
            pil_expr.pilha[pil_expr.topo] = 1;
            op_unaria(booleano);
            geraCodigo(NULL, "NEGA");
         } 
;

misc2 :  IDENT { strncpy(idr, token, strlen(token) + 1); } 
         fatora2
;

fatora2  :  chamada_funcao_com_params
            | variavel
;

chamada_funcao_com_params :   {
                                 num_expr = 0;
                                 indice_proc = busca_ts(&ts, idr);

                                 if(indice_proc == -1)
                                    imprimeErro("funcao nao declarada");

                                 if(ts.tabela[indice_proc].categoria != funcao)
                                    imprimeErro("categoria incompativel");
                                 
                                 empilha(&pil_proc, indice_proc);

                                 geraCodigo(NULL, "AMEM 1");
                              }  
                              ABRE_PARENTESES lista_expressoes FECHA_PARENTESES
                              {
                                 indice_proc = topo_pil(&pil_proc);
                                 funcao_t *atrib = ts.tabela[indice_proc].atrib_vars;

                                 if(num_expr != atrib->n_params)
                                    imprimeErro("qtd. errada de parametros");

                                 char chpr[TAM_ID * 2];
                                 sprintf(chpr, "CHPR %s,%i", atrib->rot_interno, nivel_lexico);
                                 geraCodigo(NULL, chpr);

                                 empilha(&pil_tipo, atrib->retorno);

                                 desempilha(&pil_proc, 1);
                              }  
;

variavel :  {
               int indice = busca_ts(&ts, idr);

               if(indice == -1)
                  imprimeErro("funcao ou variavel nao declarada");

               char crvl[TAM_ID * 2];
               int tipo;
               
               if(ts.tabela[indice].categoria == simples) {
                  var_simples_t *atrib = ts.tabela[indice].atrib_vars;
                  tipo = atrib->tipo;
                  indice_proc = topo_pil(&pil_proc);

                  if(indice_proc == -1)
                     sprintf(crvl, "CRVL %i,%i", ts.tabela[indice].nivel_lexico, atrib->deslocamento);
                  else {
                     procedimento_t *atrib_proc = ts.tabela[indice_proc].atrib_vars;

                     if(atrib_proc->params[num_expr].passagem == valor)
                        sprintf(crvl, "CRVL %i,%i", ts.tabela[indice].nivel_lexico, atrib->deslocamento);
                     else
                        sprintf(crvl, "CREN %i,%i", ts.tabela[indice].nivel_lexico, atrib->deslocamento);
                  }
               } else if(ts.tabela[indice].categoria == param_formal) {
                  param_formal_t *atrib = ts.tabela[indice].atrib_vars;
                  tipo = atrib->tipo;
                  indice_proc = topo_pil(&pil_proc);

                  if(indice_proc == -1) {
                     if(atrib->passagem == valor)  
                        sprintf(crvl, "CRVL %i,%i", ts.tabela[indice].nivel_lexico, atrib->deslocamento);
                     else
                        sprintf(crvl, "CRVI %i,%i", ts.tabela[indice].nivel_lexico, atrib->deslocamento);
                  }
                  else {
                     procedimento_t *atrib_proc = ts.tabela[indice_proc].atrib_vars;

                     if(atrib_proc->params[num_expr].passagem == atrib->passagem)
                        sprintf(crvl, "CRVL %i,%i", ts.tabela[indice].nivel_lexico, atrib->deslocamento);
                     else if(atrib_proc->params[num_expr].passagem == referencia)
                        sprintf(crvl, "CREN %i,%i", ts.tabela[indice].nivel_lexico, atrib->deslocamento);
                     else
                        sprintf(crvl, "CRVI %i,%i", ts.tabela[indice].nivel_lexico, atrib->deslocamento);
                  }
               } else if(ts.tabela[indice].categoria == funcao) {
                  funcao_t *atrib = ts.tabela[indice].atrib_vars;
                  tipo = atrib->retorno;
                  sprintf(crvl, "CHPR %s,%i", atrib->rot_interno, ts.tabela[indice].nivel_lexico);
                  geraCodigo(NULL, "AMEM 1");
               } else
                  imprimeErro("categoria incompativel");

               empilha(&pil_tipo, tipo);
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
   inicializa_pil(&pil_proc);
   inicializa_pil(&pil_expr);

   yyin=fp;
   yyparse();

   return 0;
}
