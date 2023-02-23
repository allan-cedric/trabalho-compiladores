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
    l_elem, indice_proc, num_rot,
    pass_ref;
tab_simb_t ts;
tipos tipo_corrente;
pilha_t pil_tipo, pil_rot, pil_proc, pil_expr, pil_num_params;

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

void atualiza_tipo_vars() {

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

void insere_novo_proc() {

   simb_t novo_simb;
   strncpy(novo_simb.id, token,  TAM_ID);
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

   char enpr[TAM_ID];
   sprintf(enpr, "ENPR %i", nivel_lexico);
   geraCodigo(atrib->rot_interno, enpr);

   #ifdef DEPURACAO
      printf("\e[1;1H\e[2J");
      printf("\033[0;32m");
      printf("alocado:\n");
      printf("\033[0m");
      imprime_ts(&ts);
      getchar();
   #endif
}

void finaliza_declara_proc() {

   int i;
   for(i = ts.topo; i >= 0; i--) {
      if(ts.tabela[i].categoria == procedimento &&
         ts.tabela[i].nivel_lexico == nivel_lexico)
         break;
   }

   char rtpr[TAM_ID];
   procedimento_t *atrib = ts.tabela[i].atrib_vars;
   sprintf(rtpr, "RTPR %i, %i", nivel_lexico, atrib->n_params);
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

void insere_novo_param() {

   simb_t novo_simb;
   strncpy(novo_simb.id, token, TAM_ID);
   novo_simb.categoria = param_formal;
   novo_simb.nivel_lexico = nivel_lexico;
   
   novo_simb.atrib_vars = (param_formal_t *)malloc(sizeof(param_formal_t));
   if(!novo_simb.atrib_vars)
      imprimeErro("erro de alocacao de memoria");

   param_formal_t *atrib = novo_simb.atrib_vars;
   atrib->passagem = (pass_ref == 1 ? referencia : valor);

   insere_ts(&ts, &novo_simb);

   num_params++; num_params_por_tipo++;
}

void finaliza_declara_params() {

   procedimento_t *atrib = ts.tabela[indice_proc].atrib_vars;
   atrib->n_params = num_params;
   atrib->params = (param_formal_t *)malloc(atrib->n_params * sizeof(param_formal_t));
   if(!atrib->params)
      imprimeErro("erro de alocacao de memoria");

   int i = ts.topo, j = num_params;
   while(i >= 0 && j > 0)
   {
      param_formal_t *a = ts.tabela[i].atrib_vars;
      a->deslocamento = (j - num_params) - 4;

      atrib->params[j - 1].tipo = a->tipo;
      atrib->params[j - 1].deslocamento = a->deslocamento;
      atrib->params[j - 1].passagem = a->passagem;

      i--; j--;
   }

   #ifdef DEPURACAO
      printf("\e[1;1H\e[2J");
      printf("\033[0;32m");
      printf("alocado:\n");
      printf("\033[0m");
      imprime_ts(&ts);
      getchar();
   #endif
}

void atualiza_tipo_params() {

   int i = ts.topo, j = num_params_por_tipo;
   while(i >= 0 && j > 0)
   {
      param_formal_t *atrib = ts.tabela[i].atrib_vars;
      atrib->tipo = tipo_corrente;
      i--; j--;
   }
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

   char enpr[TAM_ID];
   sprintf(enpr, "ENPR %i", nivel_lexico);
   geraCodigo(atrib->rot_interno, enpr);

   #ifdef DEPURACAO
      printf("\e[1;1H\e[2J");
      printf("\033[0;32m");
      printf("alocado:\n");
      printf("\033[0m");
      imprime_ts(&ts);
      getchar();
   #endif
}

void insere_retorno_func()
{
   funcao_t *atrib = ts.tabela[indice_proc].atrib_vars;
   atrib->retorno = tipo_corrente;
}

void finaliza_declara_func()
{
   int i;
   for(i = ts.topo; i >= 0; i--) {
      if(ts.tabela[i].categoria == funcao &&
         ts.tabela[i].nivel_lexico == nivel_lexico)
         break;
   }

   char rtpr[TAM_ID];
   funcao_t *atrib = ts.tabela[i].atrib_vars;
   sprintf(rtpr, "RTPR %i, %i", nivel_lexico, atrib->n_params);
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

void tipo_lado_esq_atrib()
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

void armazena_lado_esq()
{
   tipos t;
   verifica_tipo(&t, 2);

   char armz[TAM_ID];
   if(ts.tabela[l_elem].categoria == simples) {
      var_simples_t *atrib = ts.tabela[l_elem].atrib_vars;
      sprintf(armz, "ARMZ %i, %i", ts.tabela[l_elem].nivel_lexico, atrib->deslocamento);
   }else if(ts.tabela[l_elem].categoria == param_formal) {
      param_formal_t *atrib = ts.tabela[l_elem].atrib_vars;
      if(atrib->passagem == valor)
         sprintf(armz, "ARMZ %i, %i", ts.tabela[l_elem].nivel_lexico, atrib->deslocamento);
      else
         sprintf(armz, "ARMI %i, %i", ts.tabela[l_elem].nivel_lexico, atrib->deslocamento);
   }else if(ts.tabela[l_elem].categoria == funcao) {
      funcao_t *atrib = ts.tabela[l_elem].atrib_vars;
      sprintf(armz, "ARMZ %i, %i", ts.tabela[l_elem].nivel_lexico, -(atrib->n_params + 4));
   }else
      imprimeErro("categoria incompativel");

   geraCodigo(NULL, armz);
   l_elem = -1;
}

void inicializa_cham_proc()
{
   indice_proc = busca_ts(&ts, idr);

   if(indice_proc == -1)
      imprimeErro("procedimento nao declarado");

   if(ts.tabela[indice_proc].categoria != procedimento)
      imprimeErro("categoria incompativel");
   
   empilha(&pil_proc, indice_proc);
   empilha(&pil_num_params, 0);
}

void finaliza_cham_proc()
{
   indice_proc = topo_pil(&pil_proc);
   procedimento_t *atrib = ts.tabela[indice_proc].atrib_vars;

   if(topo_pil(&pil_num_params) != atrib->n_params)
      imprimeErro("qtd. errada de parametros");
   desempilha(&pil_num_params, 1);

   char chpr[TAM_ID * 2];
   sprintf(chpr, "CHPR %s, %i", atrib->rot_interno, nivel_lexico);
   geraCodigo(NULL, chpr);

   desempilha(&pil_proc, 1);
}

void reserva_rotulos_ifelse()
{
   char dsvf[TAM_ID];
   sprintf(dsvf, "DSVF R%02i", num_rot);
   empilha(&pil_rot, num_rot);
   empilha(&pil_rot, num_rot + 1);
   geraCodigo(NULL, dsvf);
   num_rot += 2;
}

void transicao_ifelse()
{
   char dsvs[TAM_ID];
   sprintf(dsvs, "DSVS R%02i", topo_pil(&pil_rot));
   geraCodigo(NULL, dsvs);
   
   char rot[TAM_ID];
   sprintf(rot, "R%02i", topo_pil(&pil_rot) - 1);
   geraCodigo(rot, "NADA");
}

void finaliza_ifelse()
{
   char rot[TAM_ID];
   sprintf(rot, "R%02i", topo_pil(&pil_rot));
   geraCodigo(rot, "NADA");

   desempilha(&pil_rot, 2);
}

void reserva_rotulos_while()
{
   char rot[TAM_ID];
   sprintf(rot, "R%02i", num_rot);
   empilha(&pil_rot, num_rot);
   empilha(&pil_rot, num_rot + 1);
   geraCodigo(rot, "NADA");
   num_rot += 2;
}

void desvio_falso_while()
{
   char dsvf[TAM_ID];
   sprintf(dsvf, "DSVF R%02i", topo_pil(&pil_rot));
   geraCodigo(NULL, dsvf);
}

void finaliza_while()
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

void verifica_expressao()
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

   int num_params = topo_pil(&pil_num_params);
   if(params[num_params].passagem == referencia && 
      topo_pil(&pil_expr) != 0)
      imprimeErro("parametro real deve ser uma variavel simples");

   if(tipo_expr != params[num_params].tipo)
      imprimeErro("tipos incompativeis - lista_expressoes");

   desempilha(&pil_expr, 1);
   desempilha(&pil_num_params, 1);
   empilha(&pil_num_params, num_params + 1); 
}

void finaliza_relacao()
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
}

void carrega_variavel()
{
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
         sprintf(crvl, "CRVL %i, %i", ts.tabela[indice].nivel_lexico, atrib->deslocamento);
      else {
         procedimento_t *atrib_proc = ts.tabela[indice_proc].atrib_vars;

         int num_params = topo_pil(&pil_num_params);
         if(atrib_proc->params[num_params].passagem == valor)
            sprintf(crvl, "CRVL %i, %i", ts.tabela[indice].nivel_lexico, atrib->deslocamento);
         else
            sprintf(crvl, "CREN %i, %i", ts.tabela[indice].nivel_lexico, atrib->deslocamento);
      }
   } else if(ts.tabela[indice].categoria == param_formal) {
      param_formal_t *atrib = ts.tabela[indice].atrib_vars;
      tipo = atrib->tipo;
      indice_proc = topo_pil(&pil_proc);

      if(indice_proc == -1) {
         if(atrib->passagem == valor)  
            sprintf(crvl, "CRVL %i, %i", ts.tabela[indice].nivel_lexico, atrib->deslocamento);
         else
            sprintf(crvl, "CRVI %i, %i", ts.tabela[indice].nivel_lexico, atrib->deslocamento);
      }
      else {
         procedimento_t *atrib_proc = ts.tabela[indice_proc].atrib_vars;

         int num_params = topo_pil(&pil_num_params);
         if(atrib_proc->params[num_params].passagem == atrib->passagem)
            sprintf(crvl, "CRVL %i, %i", ts.tabela[indice].nivel_lexico, atrib->deslocamento);
         else if(atrib_proc->params[num_params].passagem == referencia)
            sprintf(crvl, "CREN %i, %i", ts.tabela[indice].nivel_lexico, atrib->deslocamento);
         else
            sprintf(crvl, "CRVI %i, %i", ts.tabela[indice].nivel_lexico, atrib->deslocamento);
      }
   } else if(ts.tabela[indice].categoria == funcao) {
      funcao_t *atrib = ts.tabela[indice].atrib_vars;
      tipo = atrib->retorno;
      sprintf(crvl, "CHPR %s, %i", atrib->rot_interno, ts.tabela[indice].nivel_lexico);
      geraCodigo(NULL, "AMEM 1");
   } else
      imprimeErro("categoria incompativel");

   empilha(&pil_tipo, tipo);
   geraCodigo(NULL, crvl);
}

void inicializa_cham_func()
{
   indice_proc = busca_ts(&ts, idr);

   if(indice_proc == -1)
      imprimeErro("funcao nao declarada");

   if(ts.tabela[indice_proc].categoria != funcao)
      imprimeErro("categoria incompativel");
   
   empilha(&pil_proc, indice_proc);
   empilha(&pil_num_params, 0);

   geraCodigo(NULL, "AMEM 1");
}

void finaliza_cham_func()
{
   indice_proc = topo_pil(&pil_proc);
   funcao_t *atrib = ts.tabela[indice_proc].atrib_vars;

   if(topo_pil(&pil_num_params) != atrib->n_params)
      imprimeErro("qtd. errada de parametros");
   desempilha(&pil_num_params, 1);

   char chpr[TAM_ID * 2];
   sprintf(chpr, "CHPR %s, %i", atrib->rot_interno, nivel_lexico);
   geraCodigo(NULL, chpr);

   empilha(&pil_tipo, atrib->retorno);

   desempilha(&pil_proc, 1);
}

void carrega_const()
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
   sprintf(armz, "ARMZ %i, %i", ts.tabela[indice].nivel_lexico, deslocamento);

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
