/* -------------------------------------------------------------------
 *            Arquivo: compilador.h
 * -------------------------------------------------------------------
 *              Autor: Bruno Muller Junior
 *               Data: 08/2007
 *      Atualizado em: [09/08/2020, 19h:01m]
 *
 * -------------------------------------------------------------------
 *
 * Tipos, protótipos e variáveis globais do compilador (via extern)
 *
 * ------------------------------------------------------------------- */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define TAM_TOKEN 16

typedef enum simbolos {
  simb_program, simb_var, simb_begin, simb_end,
  simb_identificador, simb_numero,
  simb_ponto, simb_virgula, simb_ponto_e_virgula, simb_dois_pontos,
  simb_atribuicao, simb_abre_parenteses, simb_fecha_parenteses,

  simb_rotulo, simb_tipo, simb_vetor, simb_de, simb_procedimento,
  simb_funcao, simb_pular, simb_se, simb_entao, simb_senao,
  simb_enquanto, simb_faca, simb_igual, simb_diferente, simb_menor, simb_menor_igual, 
  simb_maior_igual, simb_maior, simb_mais, simb_menos, simb_vezes,
  simb_dividido, simb_nao, simb_e, simb_ou, simb_abre_colchetes, simb_fecha_colchetes,

  simb_inteiro, simb_booleano,

  simb_le, simb_escreve
} simbolos;

#define TAM_ID 1025
#define TAM_TAB_SIMB 4096

typedef enum categoria_t {
  simples,
  param_formal,
  procedimento
} categoria_t;

typedef enum tipo_t {
  inteiro,
  booleano
} tipo_t;

typedef enum passagem_t {
  valor,
  referencia
} passagem_t;

typedef struct simples_t {
  tipo_t tipo;
  int deslocamento;
} simples_t;

typedef struct param_formal_t {
  tipo_t tipo;
  int deslocamento;
  passagem_t passagem;
} param_formal_t;

typedef struct procedimento_t {
  // rotulo interno ?
  int n_params;
  param_formal_t *params;
} procedimento_t;

typedef struct simb_t {
  unsigned char id[TAM_ID];
  categoria_t categoria;
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


/* -------------------------------------------------------------------
 * variáveis globais
 * ------------------------------------------------------------------- */

extern simbolos simbolo, relacao;
extern char token[TAM_TOKEN];
extern int nivel_lexico;
extern int desloc;
extern int nl;
extern tab_simb_t ts;
extern int num_vars, num_vars_por_tipo;
extern tipo_t tipo_corrente;
extern int l_elem;


/* -------------------------------------------------------------------
 * prototipos globais
 * ------------------------------------------------------------------- */

void geraCodigo (char*, char*);
int yylex();
void yyerror(const char *s);
int imprimeErro (char* erro);

/* -------------------------------------------------------------------
 * prototipos globais p/ manipular a tabela de simbolos
 * ------------------------------------------------------------------- */

void inicializa_ts(tab_simb_t *ts);
void insere_ts(tab_simb_t *ts, simb_t *simb);
int busca_ts(tab_simb_t *ts, const unsigned char *id);
void retira_ts(tab_simb_t *ts, int n);
void imprime_ts(tab_simb_t *ts);

/* -------------------------------------------------------------------
 * prototipos globais p/ manipular uma pilha de indices
 * ------------------------------------------------------------------- */

void inicializa_pil(pilha_t *p);
int pil_vazia(pilha_t *p);
int tamanho_pil(pilha_t *p);
void empilha(pilha_t *p, int t);
void desempilha(pilha_t *p);
int topo_pil(pilha_t *p);