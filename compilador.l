
/* -------------------------------------------------------------------
 *            Arquivo: compilador.l
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

%{


#include<stdio.h>
#include<string.h>

#include "compilador.h"
#include "compilador.tab.h"

//#define IMPRIME(STR) {};
#define IMPRIME(STR) printf("%s    # %s \n", STR, token);

int nl = 1;

void trata_token(simbolos simb, const char *str);

%}

pulo_linha [\n]

descarte [\t ]+

ident [a-zA-Z][a-zA-Z0-9]*

numero [0-9]+

comentario "(*".*"*)"

%%

{pulo_linha} {nl++;}

{descarte}

{comentario}

{numero} {
  trata_token(simb_numero, " numero ");
  return NUMERO;
}

program {
  trata_token(simb_program, " program ");
  return PROGRAM;
}

var {
  trata_token(simb_var, " var ");
  return VAR;
}

begin {
  trata_token(simb_begin, " begin ");
  return T_BEGIN;
}

end {
  trata_token(simb_end, " end ");
  return T_END;
}

:= {
  trata_token(simb_atribuicao, " atribuicao ");
  return ATRIBUICAO;
}

\; {
  trata_token(simb_ponto_e_virgula, " pt_virgula ");
  return PONTO_E_VIRGULA;
}

\: {
  trata_token(simb_dois_pontos, " dois pontos ");
  return DOIS_PONTOS;
}

\, {
  trata_token(simb_virgula, " virgula ");
  return VIRGULA;
}


\. {
  trata_token(simb_ponto, " ponto ");
  return PONTO;
}

\( {
  trata_token(simb_abre_parenteses, " abre_parenteses ");
  return ABRE_PARENTESES;
}

\) {
  trata_token(simb_fecha_parenteses, " fecha_parenteses ");
  return FECHA_PARENTESES;
}

label {
  trata_token(simb_rotulo, " rotulo ");
  return ROTULO;
}

type {
  trata_token(simb_tipo, " tipo ");
  return TIPO;
}

array {
  trata_token(simb_vetor, " vetor ");
  return VETOR;
}

of {
  trata_token(simb_de, " de ");
  return DE;
}

procedure {
  trata_token(simb_procedimento, " procedimento ");
  return PROCEDIMENTO;
}

function {
  trata_token(simb_funcao, " funcao ");
  return FUNCAO;
}

goto {
  trata_token(simb_pular, " pular ");
  return PULAR;
}

if {
  trata_token(simb_se, " se ");
  return SE;
}

then {
  trata_token(simb_entao, " entao ");
  return ENTAO;
}

else {
  trata_token(simb_senao, " senao ");
  return SENAO;
}

while {
  trata_token(simb_enquanto, " enquanto ");
  return ENQUANTO;
}

do {
  trata_token(simb_faca, " faca ");
  return FACA;
}

\= {
  trata_token(simb_igual, " igual ");
  return IGUAL;
}

\<\> {
  trata_token(simb_diferente, " diferente ");
  return DIFERENTE;
}

\< {
  trata_token(simb_menor, " menor ");
  return MENOR;
}

\<\= {
  trata_token(simb_menor_igual, " menor igual ");
  return MENOR_IGUAL;
}

\>\= {
  trata_token(simb_maior_igual, " maior igual ");
  return MAIOR_IGUAL;
}

\> {
  trata_token(simb_maior, " maior ");
  return MAIOR;
}

\+ {
  trata_token(simb_adicao, " adicao ");
  return ADICAO;
}

\- {
  trata_token(simb_subtracao, " subtracao ");
  return SUBTRACAO;
}

\* {
  trata_token(simb_multiplicacao, " multiplicacao ");
  return MULTIPLICACAO;
}

div {
  trata_token(simb_divisao, " divisao ");
  return DIVISAO;
}

not {
  trata_token(simb_nao, " nao ");
  return NAO;
}

and {
  trata_token(simb_e, " e ");
  return E;
}

or {
  trata_token(simb_ou, " ou ");
  return OU;
}

\[ {
  trata_token(simb_abre_colchetes, " abre_colchetes ");
  return ABRE_COLCHETES;
}

\] {
  trata_token(simb_fecha_colchetes, " fecha_colchetes ");
  return FECHA_COLCHETES;
}

{ident} {
  trata_token(simb_identificador, " ident ");
  return IDENT;
}

%%

void trata_token(simbolos simb, const char *str) {

  simbolo = simb;
  strncpy (token, yytext, TAM_TOKEN);
  IMPRIME(str);
}
