input=right1.inp
debug=-dp

run: proj1
	 ./proj2 < $(input)

proj1: driver.c proj2.y proj2.l 
	flex proj2.l
	bison proj2.y
	gcc -o proj2 -I. driver.c proj2.tab.c

clean: 
	rm proj1 lex.yy.c proj2.tab.c *.o
