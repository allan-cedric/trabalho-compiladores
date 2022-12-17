/*
  compiladorF.c: Implementacao das funcoes e procedimentos auxiliares do compilador

  Autor: Allan Cedric G. B. Alves da Silva
  Ultima modificacao: 17/12/2022 
*/

#include "compilador.h"

simbolos simbolo, relacao;
char token[TAM_TOKEN], idr[TAM_ID];
int nl = 1, nivel_lexico,
    num_vars, num_vars_por_tipo,
    num_params, num_params_por_tipo,
    l_elem, indice_proc, num_rot, num_expr,
    pass_ref;
tab_simb_t ts;
tipos tipo_corrente;
pilha_t pil_tipo, pil_rot, pil_proc, pil_expr;

FILE* fp=NULL;
void geraCodigo (char* rot, char* comando) {

  if (fp == NULL) {
    fp = fopen ("MEPA", "w");
  }

  if ( rot == NULL ) {
    fprintf(fp, "     %s\n", comando); fflush(fp);
  } else {
    fprintf(fp, "%s: %s \n", rot, comando); fflush(fp);
  }
}

int imprimeErro ( char* erro ) {

  retira_ts(&ts, ts.topo + 1);
  fprintf (stderr, "Erro na linha %d - %s\n", nl, erro);
  exit(-1);
}

void desaloca_bloco() {

   if(!ts_vazia(&ts)) {
      int conta_simb = 0, conta_local = 0;
      for(int i = ts.topo; i >= 0; i--) {
         if(ts.tabela[i].nivel_lexico <= nivel_lexico && 
            ts.tabela[i].categoria != simples)
            break;
         if(ts.tabela[i].categoria == simples)
            conta_local++;
         conta_simb++;
      }

      if(conta_simb > 0) {
         retira_ts(&ts, conta_simb);

         if(conta_local > 0) {
            char dmem[TAM_ID];
            sprintf(dmem, "DMEM %i", conta_local);
            geraCodigo(NULL, dmem);
         }

         #ifdef DEPURACAO
            printf("\e[1;1H\e[2J");
            printf("\033[0;31m");
            printf("desalocado:\n");
            printf("\033[0m");
            imprime_ts(&ts);
            getchar();
         #endif
      }
   }
}

void aloca_vars() {

   char amem_k[TAM_ID];
   sprintf(amem_k, "AMEM %i", num_vars);
   geraCodigo(NULL, amem_k);
}

void carrega_tipo_vars() {

   int i = ts.topo, j = num_vars_por_tipo;
   while(i >= 0 && j > 0)
   {
      var_simples_t *atrib = ts.tabela[i].atrib_vars;
      atrib->tipo = tipo_corrente;
      i--; j--;
   }
}

void insere_nova_var() {

   simb_t novo_simb;
   strncpy(novo_simb.id, token, TAM_ID);
   novo_simb.categoria = simples;
   novo_simb.nivel_lexico = nivel_lexico;
   
   novo_simb.atrib_vars = (var_simples_t *)malloc(sizeof(var_simples_t));
   if(!novo_simb.atrib_vars)
      imprimeErro("erro de alocacao de memoria");

   var_simples_t *atrib = novo_simb.atrib_vars;
   atrib->deslocamento = num_vars;

   insere_ts(&ts, &novo_simb);

   num_vars++; num_vars_por_tipo++;

   #ifdef DEPURACAO
      printf("\e[1;1H\e[2J");
      printf("\033[0;32m");
      printf("alocado:\n");
      printf("\033[0m");
      imprime_ts(&ts);
      getchar();
   #endif
}

void desvia_subrotina() {

   char dsvs[TAM_ID];
   sprintf(dsvs, "DSVS R%02i", num_rot);                                 
   geraCodigo(NULL, dsvs);
   empilha(&pil_rot, num_rot);
   num_rot++;
}


void alvo_desvia_subrotina() {

   char rot[TAM_ID];
   sprintf(rot, "R%02i", topo_pil(&pil_rot));
   geraCodigo(rot, "NADA");
   desempilha(&pil_rot, 1);
}

void insere_novo_param() {

   simb_t novo_simb;
   strncpy(novo_simb.id, token, strlen(token) + 1);
   novo_simb.categoria = param_formal;
   novo_simb.nivel_lexico = nivel_lexico;
   
   novo_simb.atrib_vars = (param_formal_t *)malloc(sizeof(param_formal_t));
   if(!novo_simb.atrib_vars)
      imprimeErro("erro de alocacao de memoria");

   param_formal_t *atrib = novo_simb.atrib_vars;
   if(pass_ref)
      atrib->passagem = referencia;
   else
      atrib->passagem = valor;


   insere_ts(&ts, &novo_simb);

   num_params++; num_params_por_tipo++;
}

void insere_novo_proc() {

   simb_t novo_simb;
   strncpy(novo_simb.id, token, strlen(token) + 1);
   novo_simb.categoria = procedimento;
   novo_simb.nivel_lexico = ++nivel_lexico;
   
   novo_simb.atrib_vars = (procedimento_t *)malloc(sizeof(procedimento_t));
   if(!novo_simb.atrib_vars)
      imprimeErro("erro de alocacao de memoria");

   procedimento_t *atrib = novo_simb.atrib_vars;
   sprintf(atrib->rot_interno, "R%02i", num_rot);
   atrib->n_params = 0;
   atrib->params = NULL;

   insere_ts(&ts, &novo_simb);
   indice_proc = ts.topo;

   empilha(&pil_rot, num_rot);
   num_rot++;

   #ifdef DEPURACAO
      printf("\e[1;1H\e[2J");
      printf("\033[0;32m");
      printf("alocado:\n");
      printf("\033[0m");
      imprime_ts(&ts);
      getchar();
   #endif
}

void insere_nova_func() {

   simb_t novo_simb;
   strncpy(novo_simb.id, token, strlen(token) + 1);
   novo_simb.categoria = funcao;
   novo_simb.nivel_lexico = ++nivel_lexico;
   
   novo_simb.atrib_vars = (funcao_t *)malloc(sizeof(funcao_t));
   if(!novo_simb.atrib_vars)
      imprimeErro("erro de alocacao de memoria");

   funcao_t *atrib = novo_simb.atrib_vars;
   sprintf(atrib->rot_interno, "R%02i", num_rot);
   atrib->n_params = 0;
   atrib->params = NULL;

   insere_ts(&ts, &novo_simb);
   indice_proc = ts.topo;

   empilha(&pil_rot, num_rot);
   num_rot++;

   #ifdef DEPURACAO
      printf("\e[1;1H\e[2J");
      printf("\033[0;32m");
      printf("alocado:\n");
      printf("\033[0m");
      imprime_ts(&ts);
      getchar();
   #endif
}

void read_var() {

   geraCodigo(NULL, "LEIT");

   int indice = busca_ts(&ts, token);

   if(indice == -1)
      imprimeErro("variavel nao declarada");
    
   int deslocamento;
   if(ts.tabela[indice].categoria == simples) {
      var_simples_t *atrib = ts.tabela[indice].atrib_vars;
      deslocamento = atrib->deslocamento;
   } else if(ts.tabela[indice].categoria == param_formal) {
      param_formal_t *atrib = ts.tabela[indice].atrib_vars;
      deslocamento = atrib->deslocamento;
   } else
      imprimeErro("categoria incompativel");

   char armz[TAM_ID];
   sprintf(armz, "ARMZ %i,%i", ts.tabela[indice].nivel_lexico, deslocamento);

   geraCodigo(NULL, armz);
}

void op_unaria(tipos tipo) {

   tipos t;
   verifica_tipo(&t, 1);

   if(t != tipo)
      imprimeErro("tipos incompativeis - op_unaria");
}

void op_binaria(tipos tipo) {

   tipos t;
   verifica_tipo(&t, 2);

   if(t != tipo)
      imprimeErro("tipos incompativeis - op_binaria");
}

void verifica_tipo(tipos *t, int num_op) {

   if(num_op == 2) {
      tipos tipo_op1 = topo_pil(&pil_tipo); desempilha(&pil_tipo, 1);
      tipos tipo_op2 = topo_pil(&pil_tipo);

      if(tipo_op1 != tipo_op2)
         imprimeErro("tipos incompativeis - verifica_tipo");

      *t = tipo_op1;
   }else if(num_op == 1) {
      tipos tipo_op1 = topo_pil(&pil_tipo);

      *t = tipo_op1;
   }
}
