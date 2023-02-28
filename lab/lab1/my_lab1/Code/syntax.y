%{
#include <stdio.h>
#include "lex.yy.c"
#include"tree.h"
int yyerror(char* msg);
extern struct Node* root;
extern int yylineno;
extern int ERROR;
%}

/* declared types */
%union {
    int type_int;
    float type_float;
    double type_double;
    struct Node* node;
}

%locations
/* declared tokens */
//%token <type_int> INT
//%token <type_float> FLOAT
%token <node> INT
%token <node> FLOAT
%token <node> ID
%token <node> SEMI COMMA ASSIGNOP
%token <node> RELOP
%token <node> PLUS MINUS STAR DIV
%token <node> AND OR DOT NOT
%token <node> TYPE
%token <node> LP RP LB RB LC RC
%token <node> STRUCT RETURN IF ELSE WHILE

%type <node> Program ExtDefList ExtDef ExtDecList
%type <node> Specifier StructSpecifier OptTag Tag
%type <node> VarDec FunDec VarList ParamDec
%type <node> CompSt StmtList Stmt
%type <node> DefList Def DecList Dec
%type <node> Exp Args

%start Program
%right ASSIGNOP
%left OR
%left AND
%left RELOP
%left PLUS MINUS
%left STAR DIV
%right NOT HIGHER_MINUS
%left DOT LB RB LP RP

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%
//High-level Definitions
Program : ExtDefList{
        root=init("Program",@$.first_line,0);
        $$=root;
        insert($$,$1);
    };
ExtDefList : ExtDef ExtDefList{
        $$=init("ExtDefList",@$.first_line,0);
        insert($$,$1);insert($$,$2);
    }
    | /* empty */{$$=NULL;}
    ;
ExtDef : Specifier ExtDecList SEMI{
        $$=init("ExtDef",@$.first_line,0);
        insert($$,$1);insert($$,$2);insert($$,$3);
    }
    | Specifier SEMI{
        $$=init("ExtDef",@$.first_line,0);
        insert($$,$1);insert($$,$2);
    }
    | Specifier FunDec CompSt{
        $$=init("ExtDef",@$.first_line,0);
        insert($$,$1);insert($$,$2);insert($$,$3);
    }

    |Specifier ExtDecList error{printf("Error type B at Line %d: Specifier ExtDecList error.\n",@3.first_line);}
    //|Specifier error SEMI{printf("Error type B at Line %d: Specifier error SEMI.\n",@2.first_line);}
    //|error SEMI{printf("Error type B at Line %d: error SEMI.\n",@1.first_line);}
    |Specifier error{printf("Error type B at Line %d: Specifier error.\n",@2.first_line);}
    |error FunDec CompSt{printf("Error type B at Line %d: error FunDec CompSt.\n",@1.first_line);}
    |Specifier error CompSt{printf("Error type B at Line %d: Specifier error CompSt.\n",@2.first_line);}
    |Specifier FunDec error{printf("Error type B at Line %d: Specifier FunDec error.\n",@3.first_line);}
    ;
ExtDecList : VarDec{
        $$=init("ExtDecList",@$.first_line,0);
        insert($$,$1);
    }
    | VarDec COMMA ExtDecList{
        $$=init("ExtDecList",@$.first_line,0);
        insert($$,$1);insert($$,$2);insert($$,$3);
    }
    //|VarDec error ExtDecList{printf("Error type B at Line %d: VarDec error ExtDecList.\n",@2.first_line);}
    |VarDec COMMA error{printf("Error type B at Line %d: VarDec COMMA error.\n",@3.first_line);}
    |error COMMA ExtDecList{printf("Error type B at Line %d: error COMMA ExtDecList.\n",@1.first_line);}
    ;

//Specifiers
Specifier : TYPE {
        $$=init("Specifier",@$.first_line,0);
        insert($$,$1);
    }
    | StructSpecifier {
        $$=init("Specifier",@$.first_line,0);
        insert($$,$1);
    }
    ;
StructSpecifier : STRUCT OptTag LC DefList RC{
        $$=init("StructSpecifier",@$.first_line,0);
        insert($$,$1);insert($$,$2);insert($$,$3);insert($$,$4);insert($$,$5);
    }
    | STRUCT Tag{
        $$=init("StructSpecifier",@$.first_line,0);
        insert($$,$1);insert($$,$2);
    }

    |STRUCT error RC{printf("Error type B at Line %d: STRUCT error RC.\n",@2.first_line);}
    //|STRUCT OptTag LC DefList error{printf("Error type B at Line %d: STRUCT OptTag LC DefList error.\n",@5.first_line);}
    |STRUCT OptTag LC error RC{printf("Error type B at Line %d: STRUCT OptTag LC error RC.\n",@4.first_line);}
    ;
OptTag : ID {
        $$=init("OptTag",@$.first_line,0);
        insert($$,$1);
    }
    | /* empty */{$$=NULL;}
    ;
Tag : ID {
        $$=init("Tag",@$.first_line,0);
        insert($$,$1);
    };

//Declarators
VarDec : ID{
        $$=init("VarDec",@$.first_line,0);
        insert($$,$1);
    }
    | VarDec LB INT RB{
        $$=init("VarDec",@$.first_line,0);
        insert($$,$1);insert($$,$2);insert($$,$3);insert($$,$4);
    }

    |VarDec LB error RB{printf("Error type B at Line %d: VarDec LB error RB.\n",@3.first_line);}
    |VarDec LB INT error{printf("Error type B at Line %d: VarDec LB INT error.\n",@4.first_line);}
    ;
FunDec : ID LP VarList RP{
        $$=init("FunDec",@$.first_line,0);
        insert($$,$1);insert($$,$2);insert($$,$3);insert($$,$4);
    }
    | ID LP RP {
        $$=init("FunDec",@$.first_line,0);
        insert($$,$1);insert($$,$2);insert($$,$3);
    }

    |ID LP error{printf("Error type B at Line %d: ID LP error.\n",@3.first_line);}
    |ID LP VarList error{printf("Error type B at Line %d: ID LP VarList error.\n",@4.first_line);}
    |error RP{printf("Error type B at Line %d: error RP.\n",@1.first_line);}
    ;
VarList : ParamDec COMMA VarList{
        $$=init("VarList",@$.first_line,0);
        insert($$,$1);insert($$,$2);insert($$,$3);
    }
    | ParamDec{
        $$=init("VarList",@$.first_line,0);
        insert($$,$1);
    }
    |error COMMA VarList{printf("Error type B at Line %d: error COMMA VarList.\n",@1.first_line);}
    //|ParamDec error VarList{printf("Error type B at Line %d: ParamDec error VarList.\n",@2.first_line);}
    ;
ParamDec : Specifier VarDec{
        $$=init("ParamDec",@$.first_line,0);
        insert($$,$1);insert($$,$2);
    };

//Statements
CompSt : LC DefList StmtList RC{
        $$=init("CompSt",@$.first_line,0);
        insert($$,$1);insert($$,$2);insert($$,$3);insert($$,$4);
    }
    //|LC error RC{printf("Error type B at Line %d: LC error RC.\n",@2.first_line);}
    //|LC DefList StmtList error{printf("Error type B at Line %d: LC DefList StmtList error.\n",@4.first_line);}
    ;
StmtList : Stmt StmtList {
        $$=init("StmtList",@$.first_line,0);
        insert($$,$1);insert($$,$2);
    }
    | /* empty */{$$=NULL;}
    ;
Stmt : Exp SEMI{
        $$=init("Stmt",@$.first_line,0);
        insert($$,$1);insert($$,$2);
    }
    | CompSt{
        $$=init("Stmt",@$.first_line,0);
        insert($$,$1);
    }
    | RETURN Exp SEMI{
        $$=init("Stmt",@$.first_line,0);
        insert($$,$1);insert($$,$2);insert($$,$3);
    }
    | IF LP Exp RP Stmt %prec LOWER_THAN_ELSE{
        $$=init("Stmt",@$.first_line,0);
        insert($$,$1);insert($$,$2);insert($$,$3);insert($$,$4);insert($$,$5);
    }
    | IF LP Exp RP Stmt ELSE Stmt{
        $$=init("Stmt",@$.first_line,0);
        insert($$,$1);insert($$,$2);insert($$,$3);insert($$,$4);
        insert($$,$5);insert($$,$6);insert($$,$7);
    }
    | WHILE LP Exp RP Stmt{
        $$=init("Stmt",@$.first_line,0);
        insert($$,$1);insert($$,$2);insert($$,$3);insert($$,$4);insert($$,$5);
    }
    //|Exp error{printf("Error type B at Line %d: Exp error.\n",@2.first_line);}
    |error SEMI{printf("Error type B at Line %d: error SEMI.\n",@1.first_line);}
    //|RETURN error SEMI{printf("Error type B at Line %d: RETURN error SEMI.\n",@2.first_line);}
    |RETURN Exp error{printf("Error type B at Line %d: RETURN Exp error.\n",@3.first_line);}
    //|IF error RP Stmt %prec LOWER_THAN_ELSE{printf("Error type B at Line %d: syntax error.\n",@2.first_line);}
    //|IF error ELSE Stmt{printf("Error type B at Line %d: syntax error.\n",@2.first_line);}
    |IF error{printf("Error type B at Line %d: IF error.\n",@2.first_line);}
    |WHILE error{printf("Error type B at Line %d: WHILE error.\n",@2.first_line);}
    ;

//Local Definitions
DefList : Def DefList{
        $$=init("DefList",@$.first_line,0);
        insert($$,$1);insert($$,$2);
    }
    | /* empty */{$$=NULL;}
    ;
Def : Specifier DecList SEMI{
        $$=init("Def",@$.first_line,0);
        insert($$,$1);insert($$,$2);insert($$,$3);
    }
    //|error DecList SEMI{printf("Error type B at Line %d: error DecList SEMI.\n",@1.first_line);}
    //|Specifier DecList error{printf("Error type B at Line %d: Specifier DecList error.\n",@3.first_line);}
    |Specifier error SEMI{printf("Error type B at Line %d: Specifier error SEMI.\n",@2.first_line);}
    ;
DecList : Dec{
        $$=init("DecList",@$.first_line,0);
        insert($$,$1);
    }
    | Dec COMMA DecList{
        $$=init("DecList",@$.first_line,0);
        insert($$,$1);insert($$,$2);insert($$,$3);
    }
    ;
Dec : VarDec{
        $$=init("Dec",@$.first_line,0);
        insert($$,$1);
    }
    | VarDec ASSIGNOP Exp{
        $$=init("Dec",@$.first_line,0);
        insert($$,$1);insert($$,$2);insert($$,$3);
    }
    ;

//Expressions
Exp : Exp ASSIGNOP Exp{
        $$=init("Exp",@$.first_line,0);
        insert($$,$1);insert($$,$2);insert($$,$3);
    }
    | Exp AND Exp{
        $$=init("Exp",@$.first_line,0);
        insert($$,$1);insert($$,$2);insert($$,$3);
    }
    | Exp OR Exp{
        $$=init("Exp",@$.first_line,0);
        insert($$,$1);insert($$,$2);insert($$,$3);
    }
    | Exp RELOP Exp{
        $$=init("Exp",@$.first_line,0);
        insert($$,$1);insert($$,$2);insert($$,$3);
    }
    | Exp PLUS Exp{
        $$=init("Exp",@$.first_line,0);
        insert($$,$1);insert($$,$2);insert($$,$3);
    }
    | Exp MINUS Exp{
        $$=init("Exp",@$.first_line,0);
        insert($$,$1);insert($$,$2);insert($$,$3);
    }
    | Exp STAR Exp{
        $$=init("Exp",@$.first_line,0);
        insert($$,$1);insert($$,$2);insert($$,$3);
    }
    | Exp DIV Exp{
        $$=init("Exp",@$.first_line,0);
        insert($$,$1);insert($$,$2);insert($$,$3);
    }
    | LP Exp RP{
        $$=init("Exp",@$.first_line,0);
        insert($$,$1);insert($$,$2);insert($$,$3);
    }
    | MINUS Exp %prec HIGHER_MINUS{
        $$=init("Exp",@$.first_line,0);
        insert($$,$1);insert($$,$2);
    }
    | NOT Exp{
        $$=init("Exp",@$.first_line,0);
        insert($$,$1);insert($$,$2);
    }
    | ID LP Args RP{
        $$=init("Exp",@$.first_line,0);
        insert($$,$1);insert($$,$2);insert($$,$3);insert($$,$4);
    }
    | ID LP RP{
        $$=init("Exp",@$.first_line,0);
        insert($$,$1);insert($$,$2);insert($$,$3);
    }
    | Exp LB Exp RB{
        $$=init("Exp",@$.first_line,0);
        insert($$,$1);insert($$,$2);insert($$,$3);insert($$,$4);
    }
    | Exp DOT ID{
        $$=init("Exp",@$.first_line,0);
        insert($$,$1);insert($$,$2);insert($$,$3);
    }
    | ID{
        $$=init("Exp",@$.first_line,0);
        insert($$,$1);
    }
    | INT{
        $$=init("Exp",@$.first_line,0);
        insert($$,$1);
    }
    | FLOAT{
        $$=init("Exp",@$.first_line,0);
        insert($$,$1);
    }

    |Exp ASSIGNOP error{printf("Error type B at Line %d: Exp ASSIGNOP error.\n",@3.first_line);}
    |Exp AND error{printf("Error type B at Line %d: Exp AND error.\n",@3.first_line);}
    |Exp OR error{printf("Error type B at Line %d: Exp OR error.\n",@3.first_line);}
    |Exp RELOP error{printf("Error type B at Line %d: Exp RELOP error.\n",@3.first_line);}
    |Exp PLUS error{printf("Error type B at Line %d: Exp PLUS error.\n",@3.first_line);}
    |Exp MINUS error{printf("Error type B at Line %d: Exp MINUS error.\n",@3.first_line);}
    |Exp STAR error{printf("Error type B at Line %d: Exp STAR error.\n",@3.first_line);}
    |Exp DIV error{printf("Error type B at Line %d: Exp DIV error.\n",@3.first_line);}
    |LP error RP{printf("Error type B at Line %d: LP error RP.\n",@2.first_line);}
    |MINUS error %prec HIGHER_MINUS{printf("Error type B at Line %d: MINUS error.\n",@2.first_line);}
    |NOT error{printf("Error type B at Line %d: NOT error.\n",@2.first_line);}
    //|error RP{printf("Error type B at Line %d: error RP.\n",@1.first_line);}
    //|ID LP error{printf("Error type B at Line %d: ID LP error.\n",@3.first_line);}
    //|Exp LB error{printf("Error type B at Line %d: Exp LB error.\n",@3.first_line);}
    //|Exp LB error RB{printf("Error type B at Line %d: Exp LB error RB.\n",@3.first_line);}
    |Exp DOT error{printf("Error type B at Line %d: Exp DOT error.\n",@3.first_line);}
    ;
Args : Exp COMMA Args{
        $$=init("Args",@$.first_line,0);
        insert($$,$1);insert($$,$2);insert($$,$3);
    }
    | Exp{
        $$=init("Args",@$.first_line,0);
        insert($$,$1);
    }

    |error COMMA Args{printf("Error type B at Line %d: syntax error.\n",@1.first_line);}
    ;

    
%%
int yyerror(char*msg){
    ERROR+=1;
}
