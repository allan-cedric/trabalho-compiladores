#include "compilador.h"

int nivel_lexico;

int num_vars, num_vars_por_tipo;
tab_simb_t ts;
tipos tipo_corrente;
int l_elem;

void inicializa_ts(tab_simb_t *ts) {

    ts->topo = -1;
}

int ts_vazia(tab_simb_t *ts) {

    return ts->topo == -1;
}

int tamanho_ts(tab_simb_t *ts) {

    return ts->topo + 1;
}

void insere_ts(tab_simb_t *ts, simb_t *simb) {

    if(tamanho_ts(ts) < TAM_TAB_SIMB) {
        ts->topo++;
        strncpy(ts->tabela[ts->topo].id, simb->id, strlen(simb->id) + 1);
        ts->tabela[ts->topo].categoria = simb->categoria;
        ts->tabela[ts->topo].nivel_lexico = simb->nivel_lexico;
        ts->tabela[ts->topo].atrib_vars = simb->atrib_vars;
    }
}

int busca_ts(tab_simb_t *ts, const unsigned char *id) {

    for(int i = ts->topo; i >= 0; i--) {
        if(strcmp(ts->tabela[i].id, id) == 0)
            return i;
    }
    return -1;
}

void retira_ts(tab_simb_t *ts, int n) {

    while(!ts_vazia(ts) && n > 0) {
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

void imprime_ts(tab_simb_t *ts) {

    for(int i = 0; i <= ts->topo; i++) {
        if(i == ts->topo) {
            printf("\033[0;33m");
            printf(">>> ");
            printf("\033[0m");
        }else
            printf("    ");

        printf("%-16s cat:%-8i nivel:%-8i ", 
        ts->tabela[i].id, (int)ts->tabela[i].categoria, ts->tabela[i].nivel_lexico);
        
        if(ts->tabela[i].categoria == simples) {
            var_simples_t *atrib = ts->tabela[i].atrib_vars;
            printf("tipo:%-8i desloc:%i\n", atrib->tipo, atrib->deslocamento);
        }else if(ts->tabela[i].categoria == param_formal) {
            param_formal_t *atrib = ts->tabela[i].atrib_vars;
            printf("tipo:%-8i desloc:%-11i pass:%i\n", atrib->tipo, atrib->deslocamento, atrib->passagem);
        }
        else if(ts->tabela[i].categoria == procedimento) {
            procedimento_t *atrib = ts->tabela[i].atrib_vars;
            printf("rot:%-9s num.params:%-8i[ ", atrib->rot_interno, atrib->n_params);
            for(int j = 0; j < atrib->n_params; j++)
                printf("{tipo:%i, pass:%i} ", atrib->params[j].tipo, atrib->params[j].passagem);
            printf("]\n");
        }
        else if(ts->tabela[i].categoria == funcao) {
            funcao_t *atrib = ts->tabela[i].atrib_vars;
            printf("rot:%-9s num.params:%-8i[ ", atrib->rot_interno, atrib->n_params);
            for(int j = 0; j < atrib->n_params; j++)
                printf("{tipo:%i, pass:%i} ", atrib->params[j].tipo, atrib->params[j].passagem);
            printf("]\n");
        }
    }
}