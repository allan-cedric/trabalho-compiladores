#include "compilador.h"

void inicializa_pil(pilha_t *p) {

    p->topo = -1;
}

int pil_vazia(pilha_t *p) {

    return p->topo == -1;
}

int tamanho_pil(pilha_t *p) {

    return p->topo + 1;
}

void empilha(pilha_t *p, int i) {
    
    if(tamanho_pil(p) >= TAM_MAX_PILHA)
        return;

    p->pilha[++p->topo] = i;
}

void desempilha(pilha_t *p, int n) {
    
    if(pil_vazia(p) || n < 0 || n > tamanho_pil(p))
        return;

    p->topo -= n;
}

int topo_pil(pilha_t *p) {

    return p->pilha[p->topo];
}