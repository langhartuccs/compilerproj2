
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

<<<<<<< HEAD
typedef enum {PROGRAM, WHILE, ASSIGN, TYPEDECL, DECLLIST, IFELSE, LITERAL} ASTNODETYPE;
typedef enum {INTEGER, FLOAT, BOOLEAN} VARTYPE;



class ASTnode {
 	public:
	ASTNODETYPE nodeType;
	VARTYPE varType;
	vector<ASTnode*> children;
}

ASTnode registerVar(char* name, VARTYPE vartype);
ASTnode registerVar(string name, VARTYPE vartype);

map<char* name, VARTYPE vartype> varTable();
=======
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
void typeCheckVarRefs(ASTnode*);
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
>>>>>>> ecba946bada00060b463789e0bc58fe75635d82c

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
    |vardecl { typeCheckVarRefs($1); $$ = $1;}
    |whilestmt { typeCheckVarRefs($1); $$ = $1;}
    |exprstmt { typeCheckVarRefs($1); $$ = $1;}
    |COMMENT {$$ = create_AST_COMMENT($1);}
    ;
ifstmt:IF LPAREN boolean RPAREN start ELSE start { $$ = create_AST_IFELSE($3, $5, $7);}
    | IF LPAREN boolean RPAREN start { $$ = create_AST_IF($3, $5);}
    ;
vardecl:INT var SEMICOLON { $$ = registerVars($2, TYPE_INTEGER);}
    |FLOAT var SEMICOLON { $$ = registerVars($2, TYPE_FLOAT);}
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
    |LBRACKET expr RBRACKET { $$ = create_AST_ARRAY_INDICES($2);}
    |LBRACKET ICONST RBRACKET array { $$ = merge_AST_ARRAY_INDICES(create_AST_ARRAY_INDICES(create_AST_LITERAL_INT($2)), $4);}
    |LBRACKET ID RBRACKET array { $$ = merge_AST_ARRAY_INDICES(create_AST_ARRAY_INDICES(create_AST_VAR_REF($2, NULL)), $4);}
    |LBRACKET expr RBRACKET array { $$ = merge_AST_ARRAY_INDICES(create_AST_ARRAY_INDICES($2), $4);}
    ;
%%
    #include "./lex.yy.c"

<<<<<<< HEAD
    ASTnode registerVar(char* name, VARTYPE vartype){
    	return registerVar(string(name), vartype);
    }

    ASTnode registerVar(string name, VARTYPE vartype){
    	varTable[name] = vartype;
    	ASTnode output;
    	output.nodeType = LITERAL;
    	output.varType = vartype;
    	return output;
    }

=======


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
    ASTnode* output = newASTnode();
    output->nodeType = AST_VAR_DECL;
    for(i = 0; i < vars->numChildren; i++){
        ASTnode* child = vars->children[i];
        if(lookupVar(child->varName) != NULL){
            yyerror("Error: Variable already declared!");
            //TODO throw error
        }
        child->varPair = registerVar(child->varName, vartype);
        child->varType = vartype;
    }
    output->varType = vartype;
    addASTnodeChildren(output, (ASTnode*[]){vars}, 1);
    return output;
}

NameTypePair* registerVar(char* name, VARTYPE vartype){
    if(varTable.currentsize == varTable.maxsize)
        doublePairsAllocation(&varTable);

    NameTypePair* pair = newNameTypePair();
    pair->name = name;
    pair->vartype = vartype;
    varTable.pairs[varTable.currentsize++] = pair;
    
    return pair;
}

NameTypePair* lookupVar(char* name){
    int i;
    for(i = 0; i < varTable.currentsize; i++){
        if(strcmp(varTable.pairs[i]->name, name) == 0)
            return varTable.pairs[i];
    }
    return NULL;
}

void doublePairsAllocation(VARtable* table){
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
    int i = 0;
    while(parent->numChildren + numChildren > parent->maxChildren){
        doubleChildrenAllocation(parent);
    }

    for(i = 0; i < numChildren; i++){
        parent->children[parent->numChildren++] = children[i];
    }
}

void typeCheckVarRefs(ASTnode* node){
    int i;
    switch(node->nodeType){
        case AST_VAR_REF:
            if(node->varPair == NULL){
                yyerror("ERROR!! VARIABLE NOT DECLARED!\n");
            }
        break;
    }
    for(i = 0; i < node->numChildren; i++){
        typeCheckVarRefs(node->children[i]);
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
    ASTnode* output = newASTnode();
    output->nodeType = AST_VAR_REF;
    NameTypePair* pair = lookupVar(var);
    output->varPair = pair;
    output->varName = var;
    if(pair != NULL)
        output->varType = pair->vartype;
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
    if(idNode->varType != TYPE_INTEGER){
        yyerror("Array indices must evaluate to integers");
    }
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
    if(dest->varType != src->varType){
        yyerror("Type mismatch");
    }
    output->varType = dest->varType;
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
    output->varType = a->varType;
    return output;
}

ASTnode* create_AST_BIN_OP(ASTNODETYPE binOpType, ASTnode* a, ASTnode* b){
    ASTnode* output = newASTnode();
    output->nodeType = binOpType;
    if(a->varType != b->varType)
        yyerror("Type mismatch");
    output->varType = a->varType;
    addASTnodeChildren(output, (ASTnode*[]){a, b}, 2);
    return output;
}

void printAST(){
    int i;
    printf("Printed AST:\n");
    printASTNode(rootNode, 0);
}

void getTypeStr(VARTYPE varType, char* output){
    switch(varType){
        case TYPE_INTEGER:
            strcpy(output, "Int");
        break;
        case TYPE_FLOAT:
            strcpy(output, "Float");
        break;
        case TYPE_BOOLEAN:
            strcpy(output, "Bool");
        break;
        default:
            strcpy(output, "??");
    }
}

void printASTNode(ASTnode* node, int tabDepth){
    int i;
    char* tabs = calloc(1, sizeof(char)*tabDepth+1);
    char typeStr[50];
    for(i = 0; i < tabDepth; i++){
        tabs[i] = ' ';
    }
    switch(node->nodeType){
        case (AST_PROGRAM):
                printf("%sAST_PROGRAM\n", tabs);
                break;
        case (AST_WHILE):
        		printf("%sAST_WHILE\n", tabs);
        		break;
        case (AST_ASSIGN):
        		printf("%sAST_ASSIGN\n", tabs);
        		break;
        case (AST_TYPEDECL):
        		printf("%sAST_TYPEDECL\n", tabs);
        		break;
        case (AST_DECLLIST):
        		printf("%sAST_DECLLIST\n", tabs);
        		break;
        case (AST_COMMENT):
        		printf("%sAST_COMMENT\n", tabs);
        		break;
        case (AST_IF):
        		printf("%sAST_IF\n", tabs);
        		break;
        case (AST_IFELSE):
        		printf("%sAST_IFELSE\n", tabs);
        		break;
        case (AST_LITERAL):
                switch(node->varType){
                    case TYPE_INTEGER: printf("%sAST_LITERAL (%d)\n", tabs, node->ival); break;
                    case TYPE_FLOAT: printf("%sAST_LITERAL (%f)\n", tabs, node->fval); break;
                    default: printf("%sAST_LITERAL\n", tabs);
                }        		
        		break;
        case (AST_PLUS):
        		printf("%sAST_PLUS\n", tabs);
        		break;
        case (AST_MINUS):
        		printf("%sAST_MINUS\n", tabs);
        		break;
        case (AST_MULT):
        		printf("%sAST_MULT\n", tabs);
        		break;
        case (AST_DIV):
        		printf("%sAST_DIV\n", tabs);
        		break;
        case (AST_NEG):
        		printf("%sAST_NEG\n", tabs);
        		break;
        case (AST_NOT):
        		printf("%sAST_NOT\n", tabs);
        		break;
        case (AST_NE):
        		printf("%sAST_NE\n", tabs);
        		break;
        case (AST_LE):
        		printf("%sAST_LE\n", tabs);
        		break;
        case (AST_GE):
        		printf("%sAST_GE\n", tabs);
        		break;
        case (AST_LT):
        		printf("%sAST_LT\n", tabs);
        		break;
        case (AST_GT):
        		printf("%sAST_GT\n", tabs);
        		break;
        case (AST_EQ):
        		printf("%sAST_EQ\n", tabs);
        		break;
        case (AST_AND):
        		printf("%sAST_AND\n", tabs);
        		break;
        case (AST_OR):
        		printf("%sAST_OR\n", tabs);
        		break;
        case (AST_VAR_DECL):
        		printf("%sAST_VAR_DECL\n", tabs);
        		break;
        case (AST_VAR_REF):
                getTypeStr(node->varPair->vartype, typeStr);
        		printf("%sAST_VAR_REF (\"%s\":%s)\n", tabs, node->varPair->name, typeStr);
        		break;
        case (AST_VAR_LIST):
        		printf("%sAST_VAR_LIST\n", tabs);
        		break;
        case (AST_ARRAY_REF):
        		printf("%sAST_ARRAY_REF\n", tabs);
        		break;
        case (AST_ARRAY_INDICES):
        		printf("%sAST_ARRAY_INDICES\n", tabs);
        		break;
    }

    for(i = 0; i < node->numChildren; i++){
        printASTNode(node->children[i], tabDepth+1);
    }
    free(tabs);
}
>>>>>>> ecba946bada00060b463789e0bc58fe75635d82c
