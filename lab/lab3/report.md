#                                       编译原理第三次实验报告

​                                                                       201220187 孙赫彬

#### 一、功能

1. 将C--源代码翻译为中间代码，并将中间代码输出成线性结构
2. 使源代码中 可以出现结构体类型的变量，结构体类型的变量可以作为函数的参数
3. 使源代码中一维数组类型的变量可以作为函数参数，可以出现高维数组类型的变量

#### 二、实现思路

1. 符号表

   在实验2中，为了实现嵌套，我实现的符号表是栈式结构，因此退出嵌套后，里层的符号表就会弹出。为了在实验3的代码中继续使用符号表，我将弹出的符号表的头指针保存在了语法树的结点上。语法树的结点结构改动如下，添加compst_symbol_table来存储弹出的符号表。

   ```
   struct Node {
   	int flex;
   	char Node_Type[32];
   	union Content content;
   	int line;
   	struct Node* first_child;
   	struct Node* sibling;
   	struct Node* tail_child;
   	FieldList compst_symbol_table;
   };
   ```
   
   注意到嵌套的进入和退出都是在结构CompSt的前后，所以可以在实验3遍历语法树遇到CompSt之前将结点中的符号表入栈，在CompSt遍历结束后，将栈顶弹出，这样就实现了实验2中符号表的复现。
   
2. 中间代码的存储

   单个操作数的定义如下，kind中存储了操作数的类型，op_u中存储了该操作数的名称等信息。

   其中VARIABLE_OP代表kind为变量，op_u.var_no中存储了变量的序号n，即该变量名为vn

   CONSTANT_OP代表kind为立即数，op_u.value中存储了该立即数的值

   FUNCTION_OP代表kind为函数，op_u.name中存储了该函数的名字

   TEMP_OP代表kind为临时变量，op_u.var_no中存储了临时变量的序号n，即该变量名为tn

   LABEL_OP代表kind为label，op_u.var_no中存储了它的序号

   ```
   typedef struct Operand_* Operand;
   struct Operand_ {
       enum { 
           VARIABLE_OP, 
           CONSTANT_OP, 
           FUNCTION_OP,
           TEMP_OP,
           LABEL_OP } kind;
       union {
           int var_no;
           int value;
           char name[32];
       } op_u;
   };
   ```

   单条中间代码的结构如下，kind表示了该中间代码的类型，每个类型对应的代码形式已经在注释中标明，根据该句代码的操作数数量，选择u中的类型，其中four.relop用于存储运算的符号，dec是特别为指令DEC设置的类型，用于存储要申请空间的变量和空间大小。

   ```
   typedef struct InterCode_* InterCode;
   struct InterCode_
   {
       enum {
           LABEL_IR,//LABEL x :
           FUNCTION_IR,//FUNCTION f :
           ASSIGN_IR,//op1 := op2
           ADD_IR,//res := op1 + op2
           SUB_IR,//x := y - z
           MUL_IR,//x := y * z
           DIV_IR,//x := y / z
           GETADDR_IR,//x := &y
           GETVALUE_IR,//x := *y
           PUTADDR_IR,//*x := y
           GOTO_IR,//GOTO x
           IFGOTO_IR,//IF op1 [relop] op2 GOTO op3
           RETURN_IR,//RETURN x
           DEC_IR,//DEC x [size]
           ARG_IR,//ARG x
           CALL_IR,//op1 := CALL op2,if(op1==NULL)call op2
   		PARAM_IR,//PARAM x
   		READ_IR,//READ x
   		WRITE_IR//WRITE x
       } kind;
       union {
           struct { Operand op; } one;
           struct { Operand op1, op2; } two;
           struct { Operand res, op1, op2; } three;
           struct { Operand op1, op2, op3; char relop[32]; } four;
           struct { Operand x; int size; } dec;
       } u;
   };
   ```

   代码用双向链表进行存储，具体的结构如下，每个链表结点中存储了该条代码的指针和向前后指的结点。

   ```
   typedef struct InterCodes_* InterCodes;
   struct InterCodes_ { InterCode code; InterCodes prev, next; };
   ```

   另外，对于地址类型的变量（也就是作为函数参数的结构体和数组变量），为了与其他变量进行区分，对符号表的结构做如下改动：在FieldList_中添加一项addr_or_not，只有在变量为地址时，它才为1，其余情况下为0。这样，在使用变量的时候，只需要查询符号表，就可以知道该变量是不是地址了。

   ```
   struct FieldList_
   {
   	char name[32]; // 域的名字
   	Type type; // 域的类型
   	FieldList tail; // 下一个域
   	int var_num;
   	int addr_or_not;//1-is a parameter and a 数组/struct
   };
   ```

1. 整体逻辑

   对于变量、临时变量、label分别有一个计数器，每次新建一个则加一。

   在遍历语法树之前，先把各个计数器置零，然后将最底层的符号表放入栈中，接下来就开始从Program遍历语法树。这次遍历不需要对类型信息进行判断，所以对于与Specifier有关的所有分支都可以跳过。遍历的逻辑与实验2相同，各种基本语句的翻译模式按照实验指导写即可，这里不加赘述。

   需要注意的是数组和结构体的翻译：
   
   在Exp中，如果遇到结构Exp LB Exp RB或者Exp DOT ID，就整体解析该结构的类型，并且新建一个临时变量，向下递归，一直到求出整个结构的地址。如果该结构是BASIC，那就代表它是基础类型的变量，需要取出该地址中的值赋给place；反之，则代表要用的就是这个地址，直接将地址赋值给place即可。
   
   如果在Dec中发现数组或者结构体，说明这里要定义新的数组或结构体，要用DEC语句为它们申请空间。
   
如果在函数的定义时，发现参数中有数组或结构体，就将符号表中该变量的addr_or_not置为1，在之后的使用中，如果在Exp中发现ID，需要判断一下addr_or_not是不是1，如果addr_or_not是0（也就是这个变量不是地址），并且该变量是数组或结构体，那么就需要取地址返回给place，其他情况下只需要直接赋值给place即可。

#### 三、编译方法

使用makefile编译，输入命令`make`

#### 四、编译环境

1) GNU Linux Release: Ubuntu 20.04, kernel version 5.15.0-48-generic
2) GCC version 7.5.0
3) GNU Flex version 2.6.4
4) GNU Bison version 3.5.1