%pointer

%option noyywrap
%option yylineno

%{
  /* put C declarations here*/
/*  enum {COMMENT,IF,ELSE,WHILE,INT,FLOAT,NE,LE,GE,LT,GT,EQ,ASSIGN,SEMICOLON,LPAREN,RPAREN,LBRACE,RBRACE,LBRACKET,RBRACKET,PLUS,MINUS,MULT,DIV,NOT,COMMA,AND,OR,ID,ICONST,FCONST}; */
%}

%%
"/*"([^*]|"*"*[^/])*"*"*"*/" { return COMMENT; }
"if" { return IF; }
"else" { return ELSE; }
"while" { return WHILE; }
"int" { return INT; }
"float" { return FLOAT; }
"!=" { return NE; }
"<=" { return LE; }
">=" { return GE; }
"<" { return LT; }
">" { return GT; }
"==" { return EQ; }
"=" { return ASSIGN; }
";" { return SEMICOLON; }
"(" { return LPAREN; }
")" { return RPAREN; }
"{" { return LBRACE; }
"}" { return RBRACE; }
"[" { return LBRACKET; }
"]" { return RBRACKET; }
"+" { return PLUS; }
"-" { return MINUS; }
"*" { return MULT; }
"/" { return DIV; }
"!" { return NOT; }
"," { return COMMA; }
"&&" { return AND; }
"||" { return OR; }
[A-Za-z]+[A-Za-z0-9_]* { yylval.sval = strdup(yytext); return ID; }
[0-9]+"."[0-9]* { yylval.fval = strtof(yytext, NULL); return FCONST; }
[0-9]+ { yylval.ival = atoi(yytext); return ICONST; }
[ \t\n\r]+  /*ignores whitespace*/
