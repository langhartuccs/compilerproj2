
%token <sval> COMMENT
%token IF ELSE WHILE INT FLOAT
%token <sval> ID 
%token <ival> ICONST
%token <fval> FCONST
%token  LPAREN RPAREN LBRACE RBRACE ASSIGN SEMICOLON COMMA LBRACKET RBRACKET
%left  NE LE GE LT GT EQ AND OR
%left  PLUS MINUS
%left  MULT DIV
%right  UMINUS NOT UPLUS

%type <astNode> expr idstmt array vardecl var boolean exprstmt whilestmt start ifstmt stmt

%{
 /* put your c declarations here */
#define YYDEBUG 1

typedef enum {AST_PROGRAM, AST_WHILE, AST_ASSIGN, AST_TYPEDECL, 
              AST_DECLLIST, AST_COMMENT, AST_IF, AST_IFELSE, AST_LITERAL, AST_PLUS, 
              AST_MINUS, AST_MULT, AST_DIV, AST_NEG, AST_NOT, AST_NE, AST_LE, AST_GE,
              AST_LT, AST_GT, AST_EQ, AST_AND, AST_OR, AST_VAR_DECL, 
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
    char* sval;
    float fval;
    char* varName;
    struct astnodestruct** children;
} ASTnode;

ASTnode* rootNode;
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
ASTnode* create_AST_COMMENT(char*);
ASTnode* create_AST_VAR_REF(char*, ASTnode*);
ASTnode* create_AST_VAR_LIST(ASTnode*);
ASTnode* merge_AST_VAR_LIST(ASTnode*, ASTnode*);
ASTnode* create_AST_ARRAY_INDICES(ASTnode*);
ASTnode* merge_AST_ARRAY_INDICES(ASTnode*, ASTnode*);
ASTnode* create_AST_ASSIGN(ASTnode*, ASTnode*);
ASTnode* create_AST_WHILE(ASTnode*, ASTnode*);
ASTnode* create_AST_IF(ASTnode*, ASTnode*);
ASTnode* create_AST_IFELSE(ASTnode*, ASTnode*, ASTnode*);
ASTnode* create_AST_PROGRAM(ASTnode*);
ASTnode* merge_AST_PROGRAMS(ASTnode*, ASTnode*);
ASTnode* create_AST_UNARY_OP(ASTNODETYPE, ASTnode*);
ASTnode* create_AST_BIN_OP(ASTNODETYPE, ASTnode*, ASTnode*);
NameTypePair* lookupVar(char*);
void printAST();
void printASTNode(ASTnode*, int);

%}

%union {
    float fval;
    int ival;
    char* sval;
    ASTnode* astNode;
}

%%
start:stmt { $$ = create_AST_PROGRAM($1); rootNode = $$;}
    |stmt start { $$ = merge_AST_PROGRAMS(create_AST_PROGRAM($1), $2); rootNode = $$;}
    |LBRACE start RBRACE { $$ = $2; rootNode = $$;}
    |LBRACE start RBRACE start { $$ = merge_AST_PROGRAMS($2, $4); rootNode = $$;}
    ;
stmt:ifstmt
    |vardecl {$$ = $1;}
    |whilestmt {$$ = $1;}
    |exprstmt {$$ = $1;}
    |COMMENT {$$ = create_AST_COMMENT($1);}
    ;
ifstmt:IF LPAREN boolean RPAREN start ELSE start { $$ = create_AST_IFELSE($3, $5, $7);}
    | IF LPAREN boolean RPAREN start { $$ = create_AST_IF($3, $5);}
    ;
vardecl:INT var SEMICOLON { $$ = registerVars($2, INT);}
    |FLOAT var SEMICOLON { $$ = registerVars($2, FLOAT);}
    ;
var:    idstmt { $$ = create_AST_VAR_LIST($1);}
    |idstmt COMMA var { $$ = merge_AST_VAR_LIST(create_AST_VAR_LIST($1), $3);}
    ;
whilestmt:WHILE LPAREN boolean RPAREN start { $$ = create_AST_WHILE($3, $5);}
    ;
exprstmt:idstmt ASSIGN expr SEMICOLON { $$ = create_AST_ASSIGN($1, $3);}
    ;
boolean:NOT boolean { $$ = create_AST_UNARY_OP(AST_NOT, $2);}
    |LPAREN boolean RPAREN { $$ = $2;}
    |boolean NE boolean { $$ = create_AST_BIN_OP(AST_NE, $1, $3);}
    |boolean LT boolean { $$ = create_AST_BIN_OP(AST_LT, $1, $3);}
    |boolean LE boolean { $$ = create_AST_BIN_OP(AST_LE, $1, $3);}
    |boolean GT boolean { $$ = create_AST_BIN_OP(AST_GT, $1, $3);}
    |boolean GE boolean { $$ = create_AST_BIN_OP(AST_GE, $1, $3);}
    |boolean AND boolean { $$ = create_AST_BIN_OP(AST_AND, $1, $3);}
    |boolean OR boolean  { $$ = create_AST_BIN_OP(AST_OR, $1, $3);}
    |boolean EQ boolean { $$ = create_AST_BIN_OP(AST_EQ, $1, $3);}
    |expr { $$ = $1;}
    ;
expr:expr PLUS expr { $$ = create_AST_BIN_OP(AST_PLUS, $1, $3);}
    |expr MINUS expr { $$ = create_AST_BIN_OP(AST_MINUS, $1, $3);}
    |expr MULT expr  { $$ = create_AST_BIN_OP(AST_MULT, $1, $3);}
    |expr DIV expr  { $$ = create_AST_BIN_OP(AST_DIV, $1, $3);}
    |LPAREN expr RPAREN { $$ = $2;}
    |MINUS expr %prec UMINUS  { $$ = create_AST_UNARY_OP(AST_NEG, $2);}
    |PLUS expr %prec UPLUS { $$ = $2;}
    |ICONST 		{ $$ = create_AST_LITERAL_INT($1);}									
    |FCONST         { $$ = create_AST_LITERAL_FLOAT($1);}   
    |idstmt { $$ = $1;}
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
    rootNode = NULL;
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

ASTnode* create_AST_COMMENT(char* comment){
    ASTnode* output = newASTnode();
    output->nodeType = AST_COMMENT;
    output->sval = comment;
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

ASTnode* create_AST_ASSIGN(ASTnode* dest, ASTnode* src){
    ASTnode* output = newASTnode();
    output->nodeType = AST_ASSIGN;
    addASTnodeChildren(output, (ASTnode*[]){dest, src}, 2);
    return output;
}

ASTnode* create_AST_WHILE(ASTnode* conditional, ASTnode* body){
    ASTnode* output = newASTnode();
    output->nodeType = AST_WHILE;
    addASTnodeChildren(output, (ASTnode*[]){conditional, body}, 2);
    return output;
}

ASTnode* create_AST_IF(ASTnode* conditional, ASTnode* body){
    ASTnode* output = newASTnode();
    output->nodeType = AST_IF;
    addASTnodeChildren(output, (ASTnode*[]){conditional, body}, 2);
    return output;
}

ASTnode* create_AST_IFELSE(ASTnode* conditional, ASTnode* thenbody, ASTnode* elsebody){
	ASTnode* output = newASTnode();
    output->nodeType = AST_IFELSE;
    addASTnodeChildren(output, (ASTnode*[]){conditional, thenbody, elsebody}, 3);
    return output;
}

ASTnode* create_AST_PROGRAM(ASTnode* stmt){
    ASTnode* output = newASTnode();
    output->nodeType = AST_PROGRAM;
    addASTnodeChildren(output, (ASTnode*[]){stmt}, 1);
    return output;
}

ASTnode* merge_AST_PROGRAMS(ASTnode* a, ASTnode* b){
    addASTnodeChildren(a, b->children, b->numChildren);
    destroyASTnode(b);
    return a;
}

ASTnode* create_AST_DECLLIST(){
	
}

ASTnode* create_AST_TYPEDECL(){
	
}

ASTnode* create_AST_UNARY_OP(ASTNODETYPE unaryOpType, ASTnode* a){
    ASTnode* output = newASTnode();
    output->nodeType = unaryOpType;
    addASTnodeChildren(output, (ASTnode*[]){a}, 1);
    return output;
}

ASTnode* create_AST_BIN_OP(ASTNODETYPE binOpType, ASTnode* a, ASTnode* b){
    ASTnode* output = newASTnode();
    output->nodeType = binOpType;
    addASTnodeChildren(output, (ASTnode*[]){a, b}, 2);
    return output;
}

void printAST(){
    int i;
    printf("Printed AST:\n");
    for(i = 0; i < rootNode->numChildren; i++){
        printf("\tAST type: %d\n", rootNode->children[i]->nodeType);
    }
}

void printASTNode(ASTnode* node, int tabDepth){

}