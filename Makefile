 # -------------------------------------------------------------------
 #            Arquivo: Makefile
 # -------------------------------------------------------------------
 #              Autor: Bruno Müller Junior
 #               Data: 08/2007
 #      Atualizado em: [09/08/2020, 19h:01m]
 #
 # -------------------------------------------------------------------

CC=gcc
$DEPURA=1

compilador: lex.yy.c compilador.tab.c compiladorF.o tab_simb.o pilha.o compilador.h
	gcc lex.yy.c compilador.tab.c compiladorF.o tab_simb.o pilha.o -o compilador -ll -ly -lc

lex.yy.c: compilador.l compilador.h
	flex compilador.l

compilador.tab.c: compilador.y compilador.h
	bison compilador.y -d -v

compiladorF.o : compilador.h compiladorF.c

tab_simb.o : compilador.h tab_simb.c

pilha.o : compilador.h pilha.c

clean :
	rm -f compilador.tab.* lex.yy.c *.o compilador compilador.output MEPA
