
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

%}

pulo_linha [\n]

descarte [\t ]+

ident [a-zA-Z][a-zA-Z0-9]*

numero [0-9]+

comentario "(*".*"*)"

%%

{pulo_linha} {nl++;}

{descarte}

{numero} { 
  simbolo = simb_numero;
  strncpy (token, yytext, TAM_TOKEN);
  IMPRIME(" numero  ");
  return NUMERO;
}

{comentario}

program { 
  simbolo  = simb_program;
  strncpy (token, yytext, TAM_TOKEN);
  IMPRIME("program ");
  return PROGRAM;
}

var { 
  simbolo = simb_var;
  strncpy (token, yytext, TAM_TOKEN);
  IMPRIME("var  ");
  return VAR;
}

begin { 
  simbolo = simb_begin;
  strncpy (token, yytext, TAM_TOKEN);
  IMPRIME("begin ");
  return T_BEGIN;
}

end { 
  simbolo = simb_end;
  strncpy (token, yytext, TAM_TOKEN);
  IMPRIME("end  ");
  return T_END;
}

:= { 
  simbolo = simb_atribuicao;
  strncpy (token, yytext, TAM_TOKEN);
  IMPRIME(" atribuicao  ");
  return ATRIBUICAO;
}

\; { 
  simbolo = simb_ponto_e_virgula;
  strncpy (token, yytext, TAM_TOKEN);
  IMPRIME(" pt_virgula  ");
  return PONTO_E_VIRGULA;
}

\: { 
  simbolo = simb_dois_pontos;
  strncpy (token, yytext, TAM_TOKEN);
  IMPRIME(" dois pontos ");
  return DOIS_PONTOS;
}

\, { 
  simbolo = simb_virgula;
  strncpy (token, yytext, TAM_TOKEN);
  IMPRIME(" virgula  ");
  return VIRGULA;
}


\. { 
  simbolo = simb_ponto;
  strncpy (token, yytext, TAM_TOKEN);
  IMPRIME(" ponto  ");
  return PONTO;
}

\( { 
  simbolo = simb_abre_parenteses;
  strncpy (token, yytext, TAM_TOKEN);
  IMPRIME(" abre_parenteses  ");
  return ABRE_PARENTESES;
}

\) { 
  simbolo = simb_fecha_parenteses;
  strncpy (token, yytext, TAM_TOKEN);
  IMPRIME(" fecha_parenteses ");
  return FECHA_PARENTESES;
}

label { 
  simbolo = simb_rotulo;
  strncpy (token, yytext, TAM_TOKEN);
  IMPRIME(" rotulo ");
  return ROTULO;
}

type { 
  simbolo = simb_tipo;
  strncpy (token, yytext, TAM_TOKEN);
  IMPRIME(" tipo ");
  return TIPO;
}

array { 
  simbolo = simb_vetor;
  strncpy (token, yytext, TAM_TOKEN);
  IMPRIME(" vetor ");
  return VETOR;
}

of { 
  simbolo = simb_de;
  strncpy (token, yytext, TAM_TOKEN);
  IMPRIME(" de ");
  return DE;
}

procedure { 
  simbolo = simb_procedimento;
  strncpy (token, yytext, TAM_TOKEN);
  IMPRIME(" procedimento ");
  return PROCEDIMENTO;
}

function { 
  simbolo = simb_funcao;
  strncpy (token, yytext, TAM_TOKEN);
  IMPRIME(" funcao ");
  return FUNCAO;
}

goto { 
  simbolo = simb_pular;
  strncpy (token, yytext, TAM_TOKEN);
  IMPRIME(" pular ");
  return PULAR;
}

if { 
  simbolo = simb_se;
  strncpy (token, yytext, TAM_TOKEN);
  IMPRIME(" se ");
  return SE;
}

then { 
  simbolo = simb_entao;
  strncpy (token, yytext, TAM_TOKEN);
  IMPRIME(" entao ");
  return ENTAO;
}

else { 
  simbolo = simb_senao;
  strncpy (token, yytext, TAM_TOKEN);
  IMPRIME(" senao ");
  return SENAO;
}

while { 
  simbolo = simb_enquanto;
  strncpy (token, yytext, TAM_TOKEN);
  IMPRIME(" enquanto ");
  return ENQUANTO;
}

do { 
  simbolo = simb_faca;
  strncpy (token, yytext, TAM_TOKEN);
  IMPRIME(" faca ");
  return FACA;
}

\+ { 
  simbolo = simb_adicao;
  strncpy (token, yytext, TAM_TOKEN);
  IMPRIME(" adicao ");
  return ADICAO;
}

\- { 
  simbolo = simb_subtracao;
  strncpy (token, yytext, TAM_TOKEN);
  IMPRIME(" subtracao ");
  return SUBTRACAO;
}

\* { 
  simbolo = simb_multiplicacao;
  strncpy (token, yytext, TAM_TOKEN);
  IMPRIME(" multiplicacao ");
  return MULTIPLICACAO;
}

div { 
  simbolo = simb_divisao;
  strncpy (token, yytext, TAM_TOKEN);
  IMPRIME(" divisao ");
  return DIVISAO;
}

not { 
  simbolo = simb_nao;
  strncpy (token, yytext, TAM_TOKEN);
  IMPRIME(" nao ");
  return NAO;
}

and { 
  simbolo = simb_e;
  strncpy (token, yytext, TAM_TOKEN);
  IMPRIME(" e ");
  return E;
}

or { 
  simbolo = simb_ou;
  strncpy (token, yytext, TAM_TOKEN);
  IMPRIME(" ou ");
  return OU;
}

\[ { 
  simbolo = simb_abre_colchetes;
  strncpy (token, yytext, TAM_TOKEN);
  IMPRIME(" abre_colchetes ");
  return ABRE_COLCHETES;
}

\] { 
  simbolo = simb_fecha_colchetes;
  strncpy (token, yytext, TAM_TOKEN);
  IMPRIME(" fecha_colchetes ");
  return FECHA_COLCHETES;
}

{ident} { 
  simbolo = simb_identificador;
  strncpy (token, yytext, TAM_TOKEN);
  IMPRIME(" ident  ");
  return IDENT;
}

%%
