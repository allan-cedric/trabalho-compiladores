/*
  compilador.y: Regras gramaticais do compilador

  Autor: Allan Cedric G. B. Alves da Silva
  Ultima modificacao: 17/12/2022 
*/

%{

#include "compilador.h"

%}

%token PROGRAM ABRE_PARENTESES FECHA_PARENTESES
%token VIRGULA PONTO_E_VIRGULA DOIS_PONTOS PONTO
%token T_BEGIN T_END VAR IDENT ATRIBUICAO

%token LABEL TYPE ARRAY OF PROCEDURE FUNCTION
%token GOTO IF THEN ELSE WHILE DO
%token IGUAL DIFERENTE MENOR MENOR_IGUAL MAIOR_IGUAL MAIOR
%token MAIS MENOS VEZES DIVIDIDO
%token NOT AND OR ABRE_COLCHETES FECHA_COLCHETES
%token NUMERO

%token INTEGER BOOLEAN

%token READ WRITE

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

// 1. regra programa
programa :  { geraCodigo (NULL, "INPP"); }
            PROGRAM IDENT ABRE_PARENTESES lista_idents FECHA_PARENTESES PONTO_E_VIRGULA
            bloco PONTO
            { geraCodigo (NULL, "PARA"); }
;

lista_idents   :  lista_idents VIRGULA IDENT 
                  | IDENT
;

// 2. regra bloco
bloco :  parte_declara_vars
         { desvia_subrotina(); }
         parte_declara_subrotinas
         { alvo_desvia_subrotina(); }
         comando_composto { desaloca_bloco(); }
;

// 6. regra tipo
tipo  :  INTEGER { tipo_corrente = inteiro; } 
         | BOOLEAN { tipo_corrente = booleano; }
;

// 8. regra parte de declaracoes de variaveis
parte_declara_vars   :  { num_vars = 0; } 
                        VAR declara_vars 
                        { aloca_vars(); } 
                        |
; 

// 9. regra declaracao de variaveis
declara_vars   :  declara_vars declara_var 
                  | declara_var
;

declara_var :  { num_vars_por_tipo = 0; }
               lista_id_var DOIS_PONTOS tipo
               { atualiza_tipo_vars(); }
               PONTO_E_VIRGULA
;

// 10. regra lista de identificadores
lista_id_var   :  lista_id_var VIRGULA IDENT { insere_nova_var(); } 
                  | IDENT { insere_nova_var(); }
;

// 11. regra parte de declaracoes de sub-rotinas
parte_declara_subrotinas   :  declara_subrotinas
                              |
;

declara_subrotinas   :  declara_subrotinas declara_procedimento PONTO_E_VIRGULA
                        | declara_subrotinas declara_funcao PONTO_E_VIRGULA
                        | declara_procedimento PONTO_E_VIRGULA
                        | declara_funcao PONTO_E_VIRGULA
;

// 12. regra declaracao de procedimento
declara_procedimento :  PROCEDURE IDENT
                        { insere_novo_proc(); }
                        param_formais PONTO_E_VIRGULA bloco
                        { finaliza_declara_proc(); }
;

// 13. regra declaracao de funcao
declara_funcao :  FUNCTION IDENT
                  { insere_nova_func(); }
                  param_formais DOIS_PONTOS tipo
                  { insere_retorno_func(); }
                  PONTO_E_VIRGULA bloco
                  { finaliza_declara_func(); }
;

// 14. regra parametros formais
param_formais  :  { num_params = 0; }
                  ABRE_PARENTESES secao_param FECHA_PARENTESES
                  { finaliza_declara_params(); }
                  |
;

// 15. regra secao de parametros formais
secao_param :  secao_param PONTO_E_VIRGULA secao_param_formais
               | secao_param_formais
;

secao_param_formais  :  { num_params_por_tipo = 0; }
                        var_opcional lista_id_param_formal DOIS_PONTOS tipo
                        { atualiza_tipo_params(); }
;

var_opcional   :  VAR { pass_ref = 1; }
                  | { pass_ref = 0; }
;

lista_id_param_formal   :  lista_id_param_formal VIRGULA IDENT { insere_novo_param(); } 
                           | IDENT { insere_novo_param(); }
;

// 16. regra comando composto
comando_composto  :  T_BEGIN comandos T_END 
                     | T_BEGIN T_END
;

comandos :  comandos PONTO_E_VIRGULA comando 
            | comando
;

// 17. regra comando
comando  :  comando_sem_rotulo
;

// 18. regra comando sem rotulo
comando_sem_rotulo   :  misc 
                        | comando_repetitivo 
                        | leitura 
                        | impressao 
                        | comando_composto 
                        | comando_condicional
;

// fatoracao para as regras 19 e 20
misc  :  IDENT { strncpy(idr, token, strlen(token) + 1); } 
         fatora
;

fatora   :  ATRIBUICAO
            { tipo_lado_esq_atrib(); }
            atribuicao
            |
            { inicializa_cham_proc(); } 
            chamada_procedimento
            { finaliza_cham_proc(); }
;

// 19. regra atribuicao
atribuicao  :  expressao
               { armazena_lado_esq(); }
;

// 20. regra chamada de procedimento
chamada_procedimento :  ABRE_PARENTESES lista_expressoes FECHA_PARENTESES
                        |
;

// 22. regra comando condicional
comando_condicional  :  IF expressao
                        {
                           op_unaria(booleano); 
                           reserva_rotulos_ifelse(); 
                        }
                        THEN comando_sem_rotulo 
                        { transicao_ifelse(); }
                        else
                        { finaliza_ifelse(); }
;

else  :  ELSE comando_sem_rotulo
         | %prec LOWER_THAN_ELSE
;

// 23. regra comando repetitivo
comando_repetitivo   :  WHILE
                        { reserva_rotulos_while(); }
                        expressao
                        {
                           op_unaria(booleano); 
                           desvio_falso_while(); 
                        } 
                        DO comando_sem_rotulo
                        { finaliza_while(); }
;

// 24. regra lista de expressoes
lista_expressoes  :  lista_expressoes VIRGULA 
                     { empilha(&pil_expr, 0); }
                     expressao 
                     { verifica_expressao(); }
                     | { empilha(&pil_expr, 0); } 
                     expressao 
                     { verifica_expressao(); }
;

// 25. regra expressao
expressao   : expressao_simples expr_opcional
;

expr_opcional  :  relacao expressao_simples
                  { finaliza_relacao(); } 
                  |
;

// 26. regra relacao
relacao  :  IGUAL { relacao = simb_igual; } 
            | DIFERENTE { relacao = simb_diferente; } 
            | MENOR { relacao = simb_menor; } 
            | MENOR_IGUAL { relacao = simb_menor_igual; } 
            | MAIOR_IGUAL { relacao = simb_maior_igual; } 
            | MAIOR { relacao = simb_maior; } 
;

// 27. regra expressao simples
expressao_simples :  termo 
                     | MAIS termo 
                     { 
                        pil_expr.pilha[pil_expr.topo] = 1;
                        op_unaria(inteiro); 
                     }
                     | MENOS termo
                     {
                        pil_expr.pilha[pil_expr.topo] = 1;
                        op_unaria(inteiro);
                        geraCodigo(NULL, "IVNR");
                     } 
                     | expressao_simples MAIS termo
                     {
                        pil_expr.pilha[pil_expr.topo] = 1;
                        op_binaria(inteiro);
                        geraCodigo(NULL, "SOMA");
                     } 
                     | expressao_simples MENOS termo 
                     {
                        pil_expr.pilha[pil_expr.topo] = 1;
                        op_binaria(inteiro);
                        geraCodigo(NULL, "SUBT");
                     } 
                     | expressao_simples OR termo
                     {
                        pil_expr.pilha[pil_expr.topo] = 1;
                        op_binaria(booleano);
                        geraCodigo(NULL, "DISJ");
                     } 
;

// 28. regra termo
termo :  fator 
         | termo VEZES fator 
         {
            pil_expr.pilha[pil_expr.topo] = 1;
            op_binaria(inteiro);
            geraCodigo(NULL, "MULT");
         } 
         | termo DIVIDIDO fator 
         {
            pil_expr.pilha[pil_expr.topo] = 1;
            op_binaria(inteiro);
            geraCodigo(NULL, "DIVI");
         } 
         | termo AND fator
         {
            pil_expr.pilha[pil_expr.topo] = 1;
            op_binaria(booleano);
            geraCodigo(NULL, "CONJ");
         } 
;

// 29. regra fator
fator :  misc2 
         | numero { pil_expr.pilha[pil_expr.topo] = 1; } 
         | ABRE_PARENTESES expressao FECHA_PARENTESES 
         | NOT fator
         {
            pil_expr.pilha[pil_expr.topo] = 1;
            op_unaria(booleano);
            geraCodigo(NULL, "NEGA");
         } 
;

// fatoracao para as regras 30 e 31 
misc2 :  IDENT { strncpy(idr, token, strlen(token) + 1); } 
         fatora2
;

fatora2  :  chamada_funcao_com_params
            | variavel
;

// 30. regra variavel *(inclui o caso de funcao sem parametros)
variavel :  { carrega_variavel(); }
;


// 31. regra chamada de funcao
chamada_funcao_com_params :   { inicializa_cham_func(); }  
                              ABRE_PARENTESES lista_expressoes FECHA_PARENTESES
                              { finaliza_cham_func(); }  
;

// 32. regra numero
numero   :  NUMERO { carrega_const(); }
;

// regra leitura
leitura  :  READ ABRE_PARENTESES le_var FECHA_PARENTESES
;

le_var   :  le_var VIRGULA IDENT { read_var(); } 
            | IDENT { read_var(); }
;

// regra impressao
impressao   :  WRITE ABRE_PARENTESES impr_var_ou_num FECHA_PARENTESES
;

impr_var_ou_num   :  impr_var_ou_num VIRGULA misc2 { geraCodigo(NULL, "IMPR"); } 
                     | impr_var_ou_num VIRGULA numero { geraCodigo(NULL, "IMPR"); }
                     | misc2 { geraCodigo(NULL, "IMPR"); }
                     | numero { geraCodigo(NULL, "IMPR"); }
;

%%

int main (int argc, char** argv) {
   FILE* fp;
   extern FILE* yyin;

   if (argc<2 || argc>2) {
         printf("usage compilador <arq>a %d\n", argc);
         return(-1);
      }

   fp=fopen (argv[1], "r");
   if (fp == NULL) {
      printf("usage compilador <arq>b\n");
      return(-1);
   }


/* -------------------------------------------------------------------
 *  Inicia a Tabela de S�mbolos
 * ------------------------------------------------------------------- */
   inicializa_ts(&ts);
   nivel_lexico = 0;
   l_elem = -1;

   inicializa_pil(&pil_tipo);
   inicializa_pil(&pil_rot);
   inicializa_pil(&pil_proc);
   inicializa_pil(&pil_expr);
   inicializa_pil(&pil_num_params);

   yyin=fp;
   yyparse();

   return 0;
}
