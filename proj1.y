%token COMMENT IF ELSE WHILE INT FLOAT ID ICONST FCONST
%token LPAREN RPAREN LBRACE RBRACE ASSIGN SEMICOLON COMMA LBRACKET RBRACKET
%left NE LE GE LT GT EQ AND OR
%left PLUS MINUS
%left MULT DIV
%right UMINUS NOT UPLUS

%{
 /* put your c declarations here */
#define YYDEBUG 1
%}

%%
start:stmt
	|stmt start
	|LBRACE start RBRACE
	|LBRACE start RBRACE start
	;
stmt:ifstmt
	|vardecl
	|whilestmt
	|exprstmt
	|COMMENT
	;
ifstmt:IF LPAREN boolean RPAREN start ELSE start
	| IF LPAREN boolean RPAREN start
	;
vardecl:INT var SEMICOLON
	|FLOAT var SEMICOLON
	;
var:	idstmt
	|idstmt COMMA var
	;
whilestmt:WHILE LPAREN boolean RPAREN start
	;
exprstmt:idstmt ASSIGN expr SEMICOLON
	;
boolean:NOT boolean
	|LPAREN boolean RPAREN
	|boolean NE boolean
	|boolean LT boolean
	|boolean LE boolean
	|boolean GT boolean
	|boolean GE boolean
	|boolean AND boolean
	|boolean OR boolean
	|boolean EQ boolean
	|expr
	;
expr:expr PLUS expr
	|expr MINUS expr
	|expr MULT expr
	|expr DIV expr
	|LPAREN expr RPAREN
	|MINUS expr %prec UMINUS
	|PLUS expr %prec UPLUS
	|ICONST
	|FCONST
	|idstmt
	;
idstmt:ID
	| ID array
	;
array:LBRACKET ICONST RBRACKET
	|LBRACKET ID RBRACKET
	|LBRACKET ICONST RBRACKET array
	|LBRACKET ID RBRACKET array
%%
    #include "./lex.yy.c"

