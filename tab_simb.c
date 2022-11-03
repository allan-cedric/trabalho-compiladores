#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "compilador.h"

void inicializa_tab_simb(tab_simb_t *ts) {

    ts->topo = -1;
}

void insere_simb(tab_simb_t *ts, const unsigned char *id, categoria_t cat, int nivel_lexico, void *atrib_vars) {

    simb_t *novo_simb = (simb_t *)malloc(sizeof(simb_t));
    if(!novo_simb) {
        fprintf(stderr, "erro de alocacao de memoria!\n");
        exit(1);
    }

    strncpy(novo_simb->id, id, strlen(novo_simb->id));
    novo_simb->categoria = cat;
    novo_simb->nivel_lexico = nivel_lexico;
    novo_simb->atrib_vars = atrib_vars;

    if(ts->topo + 1 < TAM_TAB_SIMB)
        ts->tabela[++ts->topo] = novo_simb;
}

int busca_simb(tab_simb_t *ts, const unsigned char *id) {

    for(int i = ts->topo; i >= 0; i--) {
        if(strcmp(ts->tabela[i]->id, id) == 0)
            return i;
    }
    return -1;
}

void retira_simb(tab_simb_t *ts, int n) {

    while(ts->topo >= 0 && n > 0) {
        if(ts->tabela[ts->topo]->categoria == procedimento) {
            procedimento_t *atrib = ts->tabela[ts->topo]->atrib_vars;
            free(atrib->params);
            atrib->params = NULL;
        }
        free(ts->tabela[ts->topo]->atrib_vars);
        ts->tabela[ts->topo]->atrib_vars = NULL;
        free(ts->tabela[ts->topo]);
        ts->tabela[ts->topo] = NULL;
        ts->topo--;
        n--;
    }
}