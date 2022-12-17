/*
  compilador.h: Header principal para o compilador

  Autor: Allan Cedric G. B. Alves da Silva
  Ultima modificacao: 17/12/2022
*/

#ifndef __COMPILADOR_H__
#define __COMPILADOR_H__

#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define TAM_TOKEN 129

typedef enum simbolos {
  simb_program, simb_var, simb_begin, simb_end,
  simb_identificador, simb_numero,
  simb_ponto, simb_virgula, simb_ponto_e_virgula, simb_dois_pontos,
  simb_atribuicao, simb_abre_parenteses, simb_fecha_parenteses,

  simb_label, simb_type, simb_array, simb_of, simb_procedure,
  simb_function, simb_goto, simb_if, simb_then, simb_else,
  simb_while, simb_do, simb_igual, simb_diferente, simb_menor, simb_menor_igual, 
  simb_maior_igual, simb_maior, simb_mais, simb_menos, simb_vezes,
  simb_dividido, simb_not, simb_and, simb_or, simb_abre_colchetes, simb_fecha_colchetes,

  simb_integer, simb_boolean,

  simb_read, simb_write
} simbolos;

#define TAM_ID 1025
#define TAM_TAB_SIMB 4096

typedef enum categorias {
  simples,
  param_formal,
  procedimento,
  funcao
} categorias;

typedef enum tipos {
  inteiro,
  booleano
} tipos;

typedef enum passagens {
  valor,
  referencia
} passagens;

typedef struct var_simples_t {
  tipos tipo;
  int deslocamento;
} var_simples_t;

typedef struct param_formal_t {
  tipos tipo;
  int deslocamento;
  passagens passagem;
} param_formal_t;

typedef struct procedimento_t {
  unsigned char rot_interno[TAM_ID];
  int n_params;
  param_formal_t *params;
} procedimento_t;

typedef struct funcao_t {
  unsigned char rot_interno[TAM_ID];
  int n_params;
  param_formal_t *params;
  tipos retorno;
} funcao_t;

typedef struct simb_t {
  unsigned char id[TAM_ID];
  categorias categoria;
  int nivel_lexico;
  void *atrib_vars;
} simb_t;

typedef struct tab_simb_t {
  int topo;
  simb_t tabela[TAM_TAB_SIMB];
} tab_simb_t;

#define TAM_MAX_PILHA 4096

typedef struct pilha_t {
  int topo;
  int pilha[TAM_MAX_PILHA];
}pilha_t;

extern simbolos simbolo, relacao;
extern char token[TAM_TOKEN], idr[TAM_ID];
extern int  nl, nivel_lexico,
            num_vars, num_vars_por_tipo,
            num_params, num_params_por_tipo,
            l_elem, indice_proc, num_rot, num_expr,
            pass_ref;
extern tab_simb_t ts;
extern tipos tipo_corrente;
extern pilha_t pil_tipo, pil_rot, pil_proc, pil_expr;

// prototipos auxiliares para o compilador

void geraCodigo (char*, char*);
int yylex();
void yyerror(const char *s);
int imprimeErro (char* erro);

void insere_nova_var();
void insere_novo_param();
void insere_novo_proc();
void insere_nova_func();
void read_var();
void op_unaria(tipos tipo);
void op_binaria(tipos tipo);
void verifica_tipo(tipos *t, int num_op);

// prototipos para manipulacao de uma tabela de simbolos

void inicializa_ts(tab_simb_t *ts);
int ts_vazia(tab_simb_t *ts);
int tamanho_ts(tab_simb_t *ts);
void insere_ts(tab_simb_t *ts, simb_t *simb);
int busca_ts(tab_simb_t *ts, const unsigned char *id);
void retira_ts(tab_simb_t *ts, int n);
void imprime_ts(tab_simb_t *ts);

// prototipos para manipulacao de uma pilha simples de inteiros

void inicializa_pil(pilha_t *p);
int pil_vazia(pilha_t *p);
int tamanho_pil(pilha_t *p);
void empilha(pilha_t *p, int t);
void desempilha(pilha_t *p, int n);
int topo_pil(pilha_t *p);

#endif
