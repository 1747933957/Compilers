#ifndef MY_DEF
#define MY_DEF
union Content {
	int my_int;
	float my_float;
	char my_char[32];
};
struct Node {
	int flex;
	char Type[32];
	union Content content;
	int line;
	struct Node* first_child;
	struct Node* sibling;
	struct Node* tail_child;
};
#endif
struct Node* root;
struct Node* init(const char* type, int line,int flex);
void insert(struct Node* parent, struct Node* child);
void print_tree(struct Node* r,int pre);
