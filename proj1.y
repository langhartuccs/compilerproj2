

%token  COMMENT IF ELSE WHILE INT FLOAT
%token <sval> ID
%token <ival> ICONST
%token <fval> FCONST
%token  LPAREN RPAREN LBRACE RBRACE ASSIGN SEMICOLON COMMA LBRACKET RBRACKET
%left  NE LE GE LT GT EQ AND OR
%left  PLUS MINUS
%left  MULT DIV
%right  UMINUS NOT UPLUS

%type <astNode> expr idstmt array vardecl var

%{
 /* put your c declarations here */
#define YYDEBUG 1

typedef enum {AST_PROGRAM, AST_WHILE, AST_ASSIGN, AST_TYPEDECL, AST_DECLLIST, AST_IFELSE, AST_LITERAL, AST_PLUS, AST_MINUS, AST_MULT, AST_DIV, AST_VAR_REF, AST_ARRAY_REF, AST_VAR_DECL, AST_VAR_LIST} ASTNODETYPE;
typedef enum {TYPE_INTEGER, TYPE_FLOAT, TYPE_BOOLEAN} VARTYPE;

typedef struct {
    char* name;
    VARTYPE vartype;
} NameTypePair;

typedef struct {
    int maxsize;
    int currentsize;
    NameTypePair** pairs;
} VARtable;

typedef struct astnodestruct {
    ASTNODETYPE nodeType;
    VARTYPE varType;
    NameTypePair* varPair;

    int maxChildren;
    int numChildren;
    int ival;
    char* varName;
    float fval;
    struct astnodestruct** children;
} ASTnode;



//varTable.pairs = (NameTypePair**)calloc(sizeof(NameTypePair*)*10, 0);
//varTable.maxsize = 10;

ASTnode* registerVars(ASTnode*, VARTYPE);
NameTypePair* registerVar(char*, VARTYPE);
void doublePairsAllocation(VARtable*);
void doubleChildrenAllocation(ASTnode*);
void addASTnodeChildren(ASTnode*, ASTnode**, int);

ASTnode* create_AST_LITERAL_INT(int);
ASTnode* create_AST_LITERAL_FLOAT(float);
ASTnode* create_AST_VAR_REF(char*);
ASTnode* create_AST_ARRAY_REF(char*, ASTnode*);
ASTnode* create_AST_VAR_LIST(ASTnode*);
ASTnode* merge_AST_VAR_LIST(ASTnode*, ASTnode*);
ASTnode* create_AST_BIN_OP(ASTNODETYPE, ASTnode*, ASTnode*);
NameTypePair* lookupVar(char*);

%}

%union {
    float fval;
    int ival;
    char* sval;
    ASTnode* astNode;
}

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
vardecl:INT var SEMICOLON { $$ = registerVars($2, INT);}
    |FLOAT var SEMICOLON { $$ = registerVars($2, FLOAT);}
    ;
var:    idstmt { $$ = create_AST_VAR_LIST($1);}
    |idstmt COMMA var { $$ = merge_AST_VAR_LIST($1, $3);}
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
expr:expr PLUS expr { $$ = create_AST_BIN_OP(AST_PLUS, $1, $3);}
    |expr MINUS expr { $$ = create_AST_BIN_OP(AST_MINUS, $1, $3);}
    |expr MULT expr  { $$ = create_AST_BIN_OP(AST_MULT, $1, $3);}
    |expr DIV expr  { $$ = create_AST_BIN_OP(AST_DIV, $1, $3);}
    |LPAREN expr RPAREN
    |MINUS expr %prec UMINUS
    |PLUS expr %prec UPLUS
    |ICONST 		{ $$ = create_AST_LITERAL_INT($1);}									
    |FCONST         { $$ = create_AST_LITERAL_FLOAT($1);}   
    |idstmt
    ;
idstmt:ID  {$$ = create_AST_VAR_REF($1);}
    | ID array  {$$ = create_AST_ARRAY_REF($1, $2);}
    ;
array:LBRACKET ICONST RBRACKET
    |LBRACKET ID RBRACKET
    |LBRACKET ICONST RBRACKET array
    |LBRACKET ID RBRACKET array
%%
    #include "./lex.yy.c"



VARtable varTable;

ASTnode* registerVars(ASTnode* vars, VARTYPE vartype){
    int i;
    printf("registerVars()\n");
    ASTnode* output = calloc(1, sizeof(ASTnode));
    output->nodeType = AST_VAR_DECL;
    for(i = 0; i < vars->numChildren; i++){

        ASTnode* child = vars->children[i];
        if(child->varName == NULL)
            printf("varName is NULL\n");
        if(lookupVar(child->varName) != NULL){
            printf("Variable already registered!");
            //TODO throw error
        }
        child->varPair = registerVar(child->varName, vartype);
        child->varType = vartype;
    }
    output->varType = vartype;
    printf("Registered vars\n");
    return output;
}

NameTypePair* registerVar(char* name, VARTYPE vartype){
    printf("registerVar()\n");
    if(varTable.currentsize == varTable.maxsize)
        doublePairsAllocation(&varTable);

    NameTypePair* pair = calloc(1, sizeof(NameTypePair));
    varTable.pairs[varTable.currentsize++] = pair;

    pair->name = name;
    pair->vartype = vartype;
    
    return pair;
}

NameTypePair* lookupVar(char* name){
    printf("lookupVar()\n");
    return NULL;
}

void doublePairsAllocation(VARtable* table){
    printf("doublePairsAllocation()\n");
    if(table->maxsize == 0)
        table->maxsize = 5;
    table->pairs = realloc(table->pairs, sizeof(NameTypePair*)*(table->maxsize*2));
    if(table->pairs == NULL){
        printf("Pairs reallocation failed!");
        exit(-1);
    }
    table->maxsize *= 2;
}

void doubleChildrenAllocation(ASTnode* node){
    printf("doubleChildrenAllocation()\n");
    if(node->maxChildren == 0)
        node->maxChildren = 2;
    node->children = realloc(node->children, sizeof(ASTnode*)*(node->maxChildren*2));
    if(node->children == NULL){
        printf("Pairs reallocation failed!");
        exit(-1);
    }
    node->maxChildren *= 2;
}

void addASTnodeChildren(ASTnode* parent, ASTnode** children, int numChildren){
    printf("addASTnodeChildren()\n");
    int i = 0;
    while(parent->numChildren + numChildren > parent->maxChildren){
        doubleChildrenAllocation(parent);
    }

    for(i = 0; i < numChildren; i++){
        parent->children[parent->numChildren++] = children[i];
    }
}

ASTnode* create_AST_LITERAL_INT(int value){
	ASTnode* output = calloc(1, sizeof(ASTnode));
    output->nodeType = AST_LITERAL;
    output->ival = value;
    output->varType = TYPE_INTEGER;
    return output;
}

ASTnode* create_AST_LITERAL_FLOAT(float value){
    ASTnode* output = calloc(1, sizeof(ASTnode));
    output->nodeType = AST_LITERAL;
    output->fval = value;
    output->varType = TYPE_FLOAT;
    return output;
}

ASTnode* create_AST_VAR_REF(char* var){
    ASTnode* output = calloc(1, sizeof(ASTnode));
    output->nodeType = AST_VAR_REF;
    NameTypePair* pair = lookupVar(var);
    if(pair == NULL)
        printf("Var %s not registered\n", var);
    output->varPair = pair;
    return output;
}

ASTnode* create_AST_ARRAY_REF(char* varId, ASTnode* arrayIndex){
    ASTnode* output = calloc(1, sizeof(ASTnode));
    output->nodeType = AST_ARRAY_REF;
    //TODO
    //Fill in array info - name, sizes/indices
    return output;
}

ASTnode* create_AST_VAR_LIST(ASTnode* idNode){
    ASTnode* output = calloc(1, sizeof(ASTnode));
    output->nodeType = AST_VAR_LIST;
    printf("VARLIST adding child\n");
    addASTnodeChildren(output, (ASTnode**){idNode}, 1);
    printf("VARLIST added child\n");
    return output;
}

ASTnode* merge_AST_VAR_LIST(ASTnode* a, ASTnode* b){
    addASTnodeChildren(a, b->children, b->numChildren);
    free(b->children);
    free(b);
    return a;
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

ASTnode* create_AST_BIN_OP(ASTNODETYPE binOpType, ASTnode* a, ASTnode* b){
    ASTnode* output = calloc(1, sizeof(ASTnode));
    output->nodeType = binOpType;
    addASTnodeChildren(output, (ASTnode*[]){a, b}, 2);
    return output;
}