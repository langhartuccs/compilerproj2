

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

typedef enum {AST_PROGRAM, AST_WHILE, AST_ASSIGN, AST_TYPEDECL, 
              AST_DECLLIST, AST_IFELSE, AST_LITERAL, AST_PLUS, 
              AST_MINUS, AST_MULT, AST_DIV, AST_VAR_DECL, 
              AST_VAR_REF, AST_VAR_LIST, AST_ARRAY_REF, AST_ARRAY_INDICES} ASTNODETYPE;
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

VARtable varTable;

void initialize();
ASTnode* registerVars(ASTnode*, VARTYPE);
NameTypePair* registerVar(char*, VARTYPE);
void doublePairsAllocation(VARtable*);
void doubleChildrenAllocation(ASTnode*);
void addASTnodeChildren(ASTnode*, ASTnode**, int);

ASTnode* newASTnode();
void destroyASTnode(ASTnode*);
NameTypePair* newNameTypePair();
void destroyNameTypePair(NameTypePair*);
ASTnode* create_AST_LITERAL_INT(int);
ASTnode* create_AST_LITERAL_FLOAT(float);
ASTnode* create_AST_VAR_REF(char*, ASTnode*);
ASTnode* create_AST_VAR_LIST(ASTnode*);
ASTnode* merge_AST_VAR_LIST(ASTnode*, ASTnode*);
ASTnode* create_AST_ARRAY_INDICES(ASTnode*);
ASTnode* merge_AST_ARRAY_INDICES(ASTnode*, ASTnode*);
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
    |idstmt COMMA var { $$ = merge_AST_VAR_LIST(create_AST_VAR_LIST($1), $3);}
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
    |LPAREN expr RPAREN { $$ = $2;}
    |MINUS expr %prec UMINUS { $$ = $2;}
    |PLUS expr %prec UPLUS { $$ = $2;}
    |ICONST 		{ $$ = create_AST_LITERAL_INT($1);}									
    |FCONST         { $$ = create_AST_LITERAL_FLOAT($1);}   
    |idstmt
    ;
idstmt:ID  {$$ = create_AST_VAR_REF($1, NULL);}
    | ID array  {$$ = create_AST_VAR_REF($1, $2);}
    ;
array:LBRACKET ICONST RBRACKET { $$ = create_AST_ARRAY_INDICES(create_AST_LITERAL_INT($2));}
    |LBRACKET ID RBRACKET { $$ = create_AST_ARRAY_INDICES(create_AST_VAR_REF($2, NULL));}
    |LBRACKET ICONST RBRACKET array { $$ = merge_AST_ARRAY_INDICES(create_AST_ARRAY_INDICES(create_AST_LITERAL_INT($2)), $4);}
    |LBRACKET ID RBRACKET array { $$ = merge_AST_ARRAY_INDICES(create_AST_ARRAY_INDICES(create_AST_VAR_REF($2, NULL)), $4);}
%%
    #include "./lex.yy.c"



void initialize(){
    printf("Initializing global variables\n");
    memset(&varTable, 0, sizeof(VARtable));
}

ASTnode* newASTnode(){
    return calloc(1, sizeof(ASTnode));
}

void destroyASTnode(ASTnode* node){
    if(node->children != NULL)
        free(node->children);
    if(node->varPair != NULL)
        destroyNameTypePair(node->varPair);
    free(node);
}

NameTypePair* newNameTypePair(){
    return calloc(1, sizeof(NameTypePair));
}

void destroyNameTypePair(NameTypePair* pair){
    free(pair);
}

ASTnode* registerVars(ASTnode* vars, VARTYPE vartype){
    int i;
    printf("registerVars()\n");
    if(vars->nodeType != AST_VAR_LIST){
        printf("NOT AST_VAR_LIST! %d %d\n", AST_VAR_LIST, vars->nodeType);
    }
    ASTnode* output = newASTnode();
    output->nodeType = AST_VAR_DECL;
    for(i = 0; i < vars->numChildren; i++){
        ASTnode* child = vars->children[i];
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
    printf("registerVar(). name=%s\n", name);
    if(varTable.currentsize == varTable.maxsize)
        doublePairsAllocation(&varTable);

    NameTypePair* pair = newNameTypePair();
    varTable.pairs[varTable.currentsize++] = pair;

    pair->name = name;
    pair->vartype = vartype;
    
    return pair;
}

NameTypePair* lookupVar(char* name){
    int i;
    printf("lookupVar()\n");
    for(i = 0; i < varTable.currentsize; i++){
        if(strcmp(varTable.pairs[i]->name, name) == 0)
            return varTable.pairs[i];
    }
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
	ASTnode* output = newASTnode();
    output->nodeType = AST_LITERAL;
    output->ival = value;
    output->varType = TYPE_INTEGER;
    return output;
}

ASTnode* create_AST_LITERAL_FLOAT(float value){
    ASTnode* output = newASTnode();
    output->nodeType = AST_LITERAL;
    output->fval = value;
    output->varType = TYPE_FLOAT;
    return output;
}

ASTnode* create_AST_VAR_REF(char* var, ASTnode* arrayIndices){
    printf("create_AST_VAR_REF() for var %s\n", var);
    ASTnode* output = newASTnode();
    output->nodeType = AST_VAR_REF;
    NameTypePair* pair = lookupVar(var);
    if(pair == NULL)
        printf("Var %s not registered\n", var);
    output->varPair = pair;
    output->varName = var;
    if(arrayIndices != NULL)
        output = merge_AST_ARRAY_INDICES(output, arrayIndices);
    return output;
}

ASTnode* create_AST_VAR_LIST(ASTnode* idNode){
    ASTnode* output = newASTnode();
    output->nodeType = AST_VAR_LIST;
    addASTnodeChildren(output, (ASTnode*[]){idNode}, 1);
    return output;
}

ASTnode* merge_AST_VAR_LIST(ASTnode* a, ASTnode* b){
    addASTnodeChildren(a, b->children, b->numChildren);
    destroyASTnode(b);
    return a;
}

ASTnode* create_AST_ARRAY_INDICES(ASTnode* idNode){
    ASTnode* output = newASTnode();
    output->nodeType = AST_ARRAY_INDICES;
    addASTnodeChildren(output, (ASTnode*[]){idNode}, 1);
    return output;
}

ASTnode* merge_AST_ARRAY_INDICES(ASTnode* a, ASTnode* b){
    addASTnodeChildren(a, b->children, b->numChildren);
    destroyASTnode(b);
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
    ASTnode* output = newASTnode();
    output->nodeType = binOpType;
    addASTnodeChildren(output, (ASTnode*[]){a, b}, 2);
    return output;
}