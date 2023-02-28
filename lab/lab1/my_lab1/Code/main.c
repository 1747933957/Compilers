#include <stdio.h>
#include "tree.h"
extern FILE* yyin;
extern int yylex();
extern struct Node*root;
extern int yylineno;
extern void yyrestart(FILE *input_file);
extern int yyparse (void);
extern int ERROR;

int main(int argc, char** argv)
{
    if (argc <= 1) return 1;
    FILE* f = fopen(argv[1], "r");
    if (!f)
    {
        perror(argv[1]);
        return 1;
    }
    yylineno=1;
    yyrestart(f);
    yyparse();
    if(ERROR == 0) 
        print_tree(root,0);
    return 0;
}
