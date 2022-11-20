#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "compilador.h"

int nivel_lexico;
int desloc;
int num_vars, num_vars_por_tipo;
tab_simb_t ts;
tipo_t tipo_corrente;

void inicializa(tab_simb_t *ts) {

    ts->topo = -1;
}

void insere(tab_simb_t *ts, simb_t *simb) {

    if(ts->topo + 1 < TAM_TAB_SIMB) {
        ts->topo++;
        strncpy(ts->tabela[ts->topo].id, simb->id, strlen(simb->id) + 1);
        ts->tabela[ts->topo].categoria = simb->categoria;
        ts->tabela[ts->topo].nivel_lexico = simb->nivel_lexico;
        ts->tabela[ts->topo].atrib_vars = simb->atrib_vars;
    }
}

int busca(tab_simb_t *ts, const unsigned char *id) {

    for(int i = ts->topo; i >= 0; i--) {
        if(strcmp(ts->tabela[i].id, id) == 0)
            return i;
    }
    return -1;
}

void retira(tab_simb_t *ts, int n) {

    while(ts->topo >= 0 && n > 0) {
        if(ts->tabela[ts->topo].categoria == procedimento) {
            procedimento_t *atrib = ts->tabela[ts->topo].atrib_vars;
            free(atrib->params);
            atrib->params = NULL;
        }
        free(ts->tabela[ts->topo].atrib_vars);
        ts->tabela[ts->topo].atrib_vars = NULL;
        ts->topo--;
        n--;
    }
}

void imprime(tab_simb_t *ts) {

    for(int i = 0; i <= ts->topo; i++) {
        printf("id: %s | cat: %i | nivel_l: %i | ", 
        ts->tabela[i].id, (int)ts->tabela[i].categoria, ts->tabela[i].nivel_lexico);

        simples_t *atrib = ts->tabela[i].atrib_vars;
        printf("tipo: %i | desloc: %i\n", atrib->tipo, atrib->deslocamento);
    }
}