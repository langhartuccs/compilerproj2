input=right1.inp
debug=-dp

run: proj1
	 ./proj1 < $(input)

proj1: driver.c proj1.y proj1.l 
	flex proj1.l
	bison proj1.y
	gcc -o proj1 -I. driver.c proj1.tab.c

clean: 
	rm proj1 lex.yy.c proj1.tab.c *.o
