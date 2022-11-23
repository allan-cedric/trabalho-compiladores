
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

#include <stdio.h>
#include <string.h>

#include "compilador.h"
#include "compilador.tab.h"

#define IMPRIME(STR) {};
//#define IMPRIME(STR) printf("%s    # %s \n", STR, token);

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
  trata_token(simb_label, " label ");
  return LABEL;
}

type {
  trata_token(simb_type, " type ");
  return TYPE;
}

array {
  trata_token(simb_array, " array ");
  return ARRAY;
}

of {
  trata_token(simb_of, " of ");
  return OF;
}

procedure {
  trata_token(simb_procedure, " procedure ");
  return PROCEDURE;
}

function {
  trata_token(simb_function, " function ");
  return FUNCTION;
}

goto {
  trata_token(simb_goto, " goto ");
  return GOTO;
}

if {
  trata_token(simb_if, " if ");
  return IF;
}

then {
  trata_token(simb_then, " then ");
  return THEN;
}

else {
  trata_token(simb_else, " else ");
  return ELSE;
}

while {
  trata_token(simb_while, " while ");
  return WHILE;
}

do {
  trata_token(simb_do, " do ");
  return DO;
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
  trata_token(simb_mais, " mais ");
  return MAIS;
}

\- {
  trata_token(simb_menos, " menos ");
  return MENOS;
}

\* {
  trata_token(simb_vezes, " vezes ");
  return VEZES;
}

div {
  trata_token(simb_dividido, " dividido ");
  return DIVIDIDO;
}

not {
  trata_token(simb_not, " not ");
  return NOT;
}

and {
  trata_token(simb_and, " and ");
  return AND;
}

or {
  trata_token(simb_or, " or ");
  return OR;
}

\[ {
  trata_token(simb_abre_colchetes, " abre_colchetes ");
  return ABRE_COLCHETES;
}

\] {
  trata_token(simb_fecha_colchetes, " fecha_colchetes ");
  return FECHA_COLCHETES;
}

integer {
  trata_token(simb_integer, " integer ");
  return INTEGER;
}

boolean {
  trata_token(simb_boolean, " boolean ");
  return BOOLEAN;
}

read {
  trata_token(simb_read, " read ");
  return READ;
}

write {
  trata_token(simb_write, " write ");
  return WRITE;
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
