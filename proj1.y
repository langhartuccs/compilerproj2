%union {
	float fval;
	int ival;
}

%token COMMENT IF ELSE WHILE ID ICONST FCONST INT FLOAT
%token LPAREN RPAREN LBRACE RBRACE ASSIGN SEMICOLON COMMA LBRACKET RBRACKET
%left NE LE GE LT GT EQ AND OR
%left PLUS MINUS
%left MULT DIV
%right UMINUS NOT UPLUS


%{
 /* put your c declarations here */
#define YYDEBUG 1

typedef enum {AST_PROGRAM, AST_WHILE, AST_ASSIGN, AST_TYPEDECL, AST_DECLLIST, AST_IFELSE, AST_LITERAL} ASTNODETYPE;
typedef enum {TYPE_INTEGER, TYPE_FLOAT, TYPE_BOOLEAN} VARTYPE;

typedef struct astnodestruct {
    ASTNODETYPE nodeType;
    VARTYPE varType;
    int maxChildren;
    int numChildren;
    struct astnodestruct** children;
} ASTnode;

typedef struct {
    char* name;
    VARTYPE vartype;
} NameTypePair;

typedef struct {
    int maxsize;
    int currentsize;
    NameTypePair** pairs;
} VARtable;

//varTable.pairs = (NameTypePair**)calloc(sizeof(NameTypePair*)*10, 0);
//varTable.maxsize = 10;



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
var:    idstmt
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

ASTnode registerVar(char*, VARTYPE);
void doublePairsAllocation(VARtable*);
void doubleChildrenAllocation(ASTnode*);

VARtable varTable;

ASTnode registerVar(char* name, VARTYPE vartype){
    if(varTable.currentsize == varTable.maxsize)
        doublePairsAllocation(&varTable);

    NameTypePair* pair = (NameTypePair*)calloc(sizeof(NameTypePair), 0);
    varTable.pairs[varTable.currentsize++] = pair;

    pair->name = name;
    pair->vartype = vartype;

    ASTnode output;
    output.nodeType = AST_LITERAL;
    output.varType = vartype;
    return output;
}

void doublePairsAllocation(VARtable* table){
    table->pairs = realloc(table->pairs, table->maxsize*2);
    if(table->pairs == NULL){
        printf("Pairs reallocation failed!");
        exit(-1);
    }
    table->maxsize *= 2;
}

void doubleChildrenAllocation(ASTnode* node){
    node->children = realloc(node->children, node->maxChildren*2);
    if(node->children == NULL){
        printf("Pairs reallocation failed!");
        exit(-1);
    }
    node->maxChildren *= 2;
}

ASTnode* create_AST_LITERAL(){
	
}

ASTnode* create_AST_IFELSE(){
	
}

ASTnode* create_AST_DECLLIST(){
	
}

ASTnode* create_AST_TYPEDECL(){
	
}

ASTnode* create_AST_ASSIGN(){
	
}

ASTnode* create_AST_WHILE(){
	
}

ASTnode* create_AST_PROGRAM(){
	
}