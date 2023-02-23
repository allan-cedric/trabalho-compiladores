/*
  compilador.l: Definicao de um subconjunto da linguagem pascal

  Autor: Allan Cedric G. B. Alves da Silva
  Ultima modificacao: 17/12/2022 
*/

%{

#include "compilador.h"
#include "compilador.tab.h"

#define IMPRIME(STR) {};
//#define IMPRIME(STR) printf("%s    # %s \n", STR, token);

void armz_token(simbolos simb, const char *str);

%}

pulo_linha [\n]

descarte [\t ]+

ident [a-zA-Z_][a-zA-Z0-9_]*

numero [0-9]+

comentario "(*".*"*)"

comentario_linha "//".*

%%

{pulo_linha} {nl++;}

{descarte}

{comentario}

{comentario_linha}

{numero} {
  armz_token(simb_numero, " numero ");
  return NUMERO;
}

(?i:program) {
  armz_token(simb_program, " program ");
  return PROGRAM;
}

var {
  armz_token(simb_var, " var ");
  return VAR;
}

begin {
  armz_token(simb_begin, " begin ");
  return T_BEGIN;
}

end {
  armz_token(simb_end, " end ");
  return T_END;
}

:= {
  armz_token(simb_atribuicao, " atribuicao ");
  return ATRIBUICAO;
}

\; {
  armz_token(simb_ponto_e_virgula, " pt_virgula ");
  return PONTO_E_VIRGULA;
}

\: {
  armz_token(simb_dois_pontos, " dois pontos ");
  return DOIS_PONTOS;
}

\, {
  armz_token(simb_virgula, " virgula ");
  return VIRGULA;
}


\. {
  armz_token(simb_ponto, " ponto ");
  return PONTO;
}

\( {
  armz_token(simb_abre_parenteses, " abre_parenteses ");
  return ABRE_PARENTESES;
}

\) {
  armz_token(simb_fecha_parenteses, " fecha_parenteses ");
  return FECHA_PARENTESES;
}

label {
  armz_token(simb_label, " label ");
  return LABEL;
}

type {
  armz_token(simb_type, " type ");
  return TYPE;
}

array {
  armz_token(simb_array, " array ");
  return ARRAY;
}

of {
  armz_token(simb_of, " of ");
  return OF;
}

procedure {
  armz_token(simb_procedure, " procedure ");
  return PROCEDURE;
}

function {
  armz_token(simb_function, " function ");
  return FUNCTION;
}

forward {
  armz_token(simb_forward, " forward ");
  return FORWARD;
}

goto {
  armz_token(simb_goto, " goto ");
  return GOTO;
}

if {
  armz_token(simb_if, " if ");
  return IF;
}

then {
  armz_token(simb_then, " then ");
  return THEN;
}

else {
  armz_token(simb_else, " else ");
  return ELSE;
}

while {
  armz_token(simb_while, " while ");
  return WHILE;
}

do {
  armz_token(simb_do, " do ");
  return DO;
}

\= {
  armz_token(simb_igual, " igual ");
  return IGUAL;
}

\<\> {
  armz_token(simb_diferente, " diferente ");
  return DIFERENTE;
}

\< {
  armz_token(simb_menor, " menor ");
  return MENOR;
}

\<\= {
  armz_token(simb_menor_igual, " menor igual ");
  return MENOR_IGUAL;
}

\>\= {
  armz_token(simb_maior_igual, " maior igual ");
  return MAIOR_IGUAL;
}

\> {
  armz_token(simb_maior, " maior ");
  return MAIOR;
}

\+ {
  armz_token(simb_mais, " mais ");
  return MAIS;
}

\- {
  armz_token(simb_menos, " menos ");
  return MENOS;
}

\* {
  armz_token(simb_vezes, " vezes ");
  return VEZES;
}

div {
  armz_token(simb_dividido, " dividido ");
  return DIVIDIDO;
}

not {
  armz_token(simb_not, " not ");
  return NOT;
}

and {
  armz_token(simb_and, " and ");
  return AND;
}

or {
  armz_token(simb_or, " or ");
  return OR;
}

\[ {
  armz_token(simb_abre_colchetes, " abre_colchetes ");
  return ABRE_COLCHETES;
}

\] {
  armz_token(simb_fecha_colchetes, " fecha_colchetes ");
  return FECHA_COLCHETES;
}

integer {
  armz_token(simb_integer, " integer ");
  return INTEGER;
}

boolean {
  armz_token(simb_boolean, " boolean ");
  return BOOLEAN;
}

read {
  armz_token(simb_read, " read ");
  return READ;
}

write {
  armz_token(simb_write, " write ");
  return WRITE;
}

writeln {
  armz_token(simb_write, " write ");
  return WRITE;
}

{ident} {
  armz_token(simb_identificador, " ident ");
  return IDENT;
}

%%

void armz_token(simbolos simb, const char *str) {

  simbolo = simb;
  strncpy (token, yytext, TAM_TOKEN);
  IMPRIME(str);
}
