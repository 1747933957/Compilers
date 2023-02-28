#include "tree.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct Node* init(const char* type, int line,int flex){
	//flex-1,bison-0
	struct Node* p = (struct Node*)malloc(sizeof(struct Node));
	strcpy(p->Type, type);
	p->line = line;
	p->flex = flex;
	p->first_child=p->sibling=p->tail_child=NULL;
	return p;
}
void insert(struct Node* parent, struct Node* child) {
	if (child == NULL)return;
	if (parent->tail_child == NULL){
		parent->first_child = child;
		parent->tail_child = child;
	}
	else {
		parent->tail_child->sibling = child;
		parent->tail_child = child;
	}
}
void print_tree(struct Node* r,int pre) {
	if (r == NULL)return;
	for (int i = 0; i < pre; ++i)printf("  ");
	printf("%s", r->Type);
	if (r->flex == 1) {
		if (strcmp(r->Type, "ID") == 0)
			printf(": %s", r->content.my_char);
		else if (strcmp(r->Type, "TYPE") == 0)
			printf(": %s", r->content.my_char);
		else if (strcmp(r->Type, "INT") == 0)
			printf(": %d", r->content.my_int);
		else if (strcmp(r->Type, "FLOAT") == 0)
			printf(": %f", r->content.my_float);
	}
	else
		printf(" (%d)", r->line);
	printf("\n");
	print_tree(r->first_child, pre + 1);
	print_tree(r->sibling, pre);
}