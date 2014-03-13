#include <stdio.h>

extern int yylineno;
extern char* yytext;
extern FILE* yyin;
extern int yydebug;

extern void exit(int);

extern void yyparse();
extern void yyerror(const char* msg)
{
  char *p;
  fprintf(stderr, "Line %d : %s : %s \n",yylineno,msg, yytext);
  exit(1);
}
extern void initialize();
extern void printAST();

int main(int argc, char** argv)
{
  if (argc != 1) {
     fprintf(stderr, "Usage : %s  < inputfile\n", argv[0]);
     exit(1);
  }
  initialize();
  yyin = stdin;
  yydebug=0;
  yyparse();
  printf("Successful Parse\n\n");
  printAST();
  return 0;
}

