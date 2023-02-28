%option yylineno
%{
    #include "syntax.tab.h"
    #include <stdlib.h>
    #include <string.h>
    #include"tree.h"
    int yycolumn = 1;
    int ERROR = 0;
    #define YY_USER_ACTION \
        yylloc.first_line = yylloc.last_line = yylineno; \
        yylloc.first_column = yycolumn; \
        yylloc.last_column = yycolumn + yyleng - 1; \
        yycolumn += yyleng;
%}

digit [0-9]
oct 0|([1-9]{digit}*)
dec 0[0-7]+
hex 0[xX][0-9A-Fa-f]+
bad_hex 0[xX][0-9A-Za-z]+
letter [_a-zA-Z]
com_float {digit}+\.{digit}+
sci_float (({digit}+\.{digit}*)|({digit}*\.{digit}+))[eE][+-]?{digit}+

%%
{oct} { 
        struct Node*new_node= init("INT", yylineno, 1);
        int tmp = atoi(yytext);
	    new_node->content.my_int = tmp;
        yylval.node = new_node;
        return INT;
    }
{dec} { 
        struct Node*new_node= init("INT", yylineno, 1);
        char* rubbish;
        int tmp = strtol(yytext, &rubbish, 8);
	    new_node->content.my_int = tmp;
        yylval.node = new_node;
        return INT;
    }
{hex} { 
        struct Node*new_node= init("INT", yylineno, 1);
        char* rubbish;
        int tmp = strtol(yytext, &rubbish, 16);
	    new_node->content.my_int = tmp;
        yylval.node = new_node;
        return INT;
    }
{com_float}|{sci_float} { 
        struct Node*new_node= init("FLOAT", yylineno, 1);
        float tmp = atof(yytext);
	    new_node->content.my_float = tmp;
        yylval.node = new_node;
        return FLOAT;
    }
";" {yylval.node=init("SEMI",yylineno,1);return SEMI;}
"," {yylval.node=init("COMMA",yylineno,1);return COMMA;}
"=" {yylval.node=init("ASSIGNOP",yylineno,1);return ASSIGNOP;}
>|<|>=|<=|==|!= {yylval.node=init("RELOP",yylineno,1);return RELOP;}
"+" {yylval.node=init("PLUS",yylineno,1);return PLUS;}
"-" {yylval.node=init("MINUS",yylineno,1);return MINUS;}
"*" {yylval.node=init("STAR",yylineno,1);return STAR;}
"/" {yylval.node=init("DIV",yylineno,1);return DIV;}
"&&" {yylval.node=init("AND",yylineno,1);return AND;}
"||" {yylval.node=init("OR",yylineno,1);return OR;}
"." {yylval.node=init("DOT",yylineno,1);return DOT;}
"!" {yylval.node=init("NOT",yylineno,1);return NOT;}
"int"|"float" {
        struct Node*new_node= init("TYPE", yylineno, 1);
	    strcpy(new_node->content.my_char, yytext);
        yylval.node = new_node;
        return TYPE;
    }
"(" {yylval.node=init("LP",yylineno,1);return LP;}
")" {yylval.node=init("RP",yylineno,1);return RP;}
"[" {yylval.node=init("LB",yylineno,1);return LB;}
"]" {yylval.node=init("RB",yylineno,1);return RB;}
"{" {yylval.node=init("LC",yylineno,1);return LC;}
"}" {yylval.node=init("RC",yylineno,1);return RC;}
"struct" {yylval.node=init("STRUCT",yylineno,1);return STRUCT;}
"return" {yylval.node=init("RETURN",yylineno,1);return RETURN;}
"if" {yylval.node=init("IF",yylineno,1);return IF;}
"else" {yylval.node=init("ELSE",yylineno,1);return ELSE;}
"while" {yylval.node=init("WHILE",yylineno,1);return WHILE;}
{letter}[_a-zA-Z0-9]* {
        struct Node*new_node= init("ID", yylineno, 1);
        strcpy(new_node->content.my_char,yytext);
        yylval.node = new_node;
        return ID;
    }
[0-9]+|{bad_hex} { 
        ERROR += 1;
        printf("Error type A at Line %d: bad int \'%s\'\n",yylineno, yytext);
        struct Node*new_node= init("INT", yylineno, 1);
	    new_node->content.my_int = 0;
        yylval.node = new_node;
        return INT;
    }


"//" {
        char tmp = input();
        while(tmp!='\n')  tmp = input();
    }
"/*" {
        char tmp = input();
        while(1){
            if(tmp == '*'){
                tmp = input();
                if(tmp == '/')break;
            }
            else tmp = input();
        }
    }
\r  {;}
" "|\t  {;}
\n { yycolumn = 1; }
. {
    ERROR += 1;
    printf("Error type A at Line %d: Mysterious characters \'%s\'\n",
yylineno, yytext);
}

%%