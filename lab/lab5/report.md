#                                       编译原理第五次实验报告

​                                                                       201220187 孙赫彬

#### 一、功能

本次实验没有使用任何框架代码, 为了将实验三中得到的中间代码进行优化，需要先将中间代码的输入读入并存储在需要的结构体中, 然后遍历代码, 分析结构, 进行优化, 再按照实验三中的方法进行输出. 

本次实验我进行的优化具体包括：

			1. 局部子表达式消除
			2. 局部无用代码消除
			3. 常量折叠
			4. 全局子表达式消除
			5. 全局无用代码消除

#### 二、实现思路

1. 输入输出处理

   为了处理输入的文件, 采用和之前的实验一样的方式, 使用lexical.l文件将输入划分为词法单元, 再使用syntax.y文件对词法单元进行按行处理, 最终将每行的内容存储在结构体中, 再将结构体按输入顺序存储为链表.

   因为语句的存储方式与实验三相同, 故输出方式也与结构体相同, 这里就不多加赘述了.

2. 结构体

   每个操作数存储在结构体Operand中, 结构体InterCode中存储了单条语句的相关信息, 包括这条指令的类型和指令中的操作数, 根据操作数的个数存储对应个数的Operand结构体指针. 结构体InterCodes是为了将InterCode连成链表而设计的, 它里面存储了一个InterCode指针和一个指向下一个InterCodes的指针. 这三个结构都与实验三相同, 故省略代码展示部分.

   本次实验新设置了两个结构体用于存储基本块. Basic_block用于存储基本块的相关信息, Basic_block_list用于将基本块串成链表.

   ```
   typedef struct Basic_block_* Basic_block;
   typedef struct Basic_block_list_* Basic_block_list;
   typedef struct ConstantList_* ConstantList;
   struct Basic_block_{
       InterCodes head;//基本块第一条指令的地址
       InterCodes tail;//基本块最后一条指令的地址
       OperandList def_B,use_B;//活跃变量
       OperandList IN,OUT;//活跃变量
       InterCodes e_gen;OperandList e_kill;//可用表达式
       InterCodes e_IN,e_OUT;//可用表达式
       ConstantList r_gen,r_IN,r_OUT;OperandList r_kill;//到达定值
       Basic_block_list in_list;//该基本块所有前驱组成的链表
       Basic_block_list out_list;//该基本块所有后继组成的链表
   };
   
   struct Basic_block_list_{
       Basic_block basic_block;//指向基本块信息Basic_block
       Basic_block_list next;//指向下一个Basic_block_list
   };
   ```

   在处理输入时, 需要遍历所有的指令, 根据FUNCTION, LABEL, IFGOTO, GOTO, RETURN指令将所有的指令划分为若干基本块, 并对基本块的head和tail赋值, 然后遍历所有的基本块, 根据代码顺序和IFGOTO, GOTO指令填入每个基本块的in_list和out_list.接着每个函数单独处理, 进行优化.

3. 公共子表达式消除

   首先遍历所有基本块的所有指令, 来计算每个基本块的e_gen和e_kill. 如果是加减乘除的指令, 则先把e_gen中所有与该指令结果的变量相关的表达式都移除, 然后将该指令结果的变量加入e_kill中, 最后将该指令的表达式加入e_gen中. 如果是赋值指令,READ指令或者CALL指令, 则先把e_gen中所有与该指令结果的变量相关的表达式都移除, 然后将该指令结果的变量加入e_kill中.

   接下来计算e_IN和e_OUT, 初始时程序入口的e_OUT是空值, 其他地方的e_OUT是之前遇到的所有表达式的全集. 接下来进行循环, 遍历每个基本块, 每次e_IN为该基本块所有前驱的e_OUT的交集, e_OUT为在e_IN中不在e_kill中的表达式, 和e_gen中的表达式的并集. 重复循环直到e_OUT的值不再改变.

   然后就可以进行消除工作了, 维护一张表available_list, 用来记录当前的可用表达式. 对于每个基本块, 这张表的 初始值都是e_IN. 从基本块的第一条指令向后遍历, 如果遇到加减乘除指令, 则查询是否有符合的可用表达式, 如果有则替换, 然后进行相关表达式的删除, 再将这个表达式加入available_list. 如果遇到赋值指令,READ指令或者CALL指令, 则从available_list中删除与该指令结果变量相关的表达式.

4. 无用代码消除

   首先进行活跃变量分析, 从头向后遍历每个基本块, 如果一个变量先被赋值, 则将它加入def_B, 如果先被使用, 则将它加入use_B. 接着计算IN和OUT的值, 初始时所有基本块的IN都是空值. 进行循环, 遍历每个基本块, 每次OUT是该基本块所有后继的IN的并集, IN是在OUT中而不在def_B中, 或者在use_B中的所有变量的并集.重复循环直到所有基本块的IN值不再变化.

   接下来进行无用代码的消除. 维护一张表active_list, 用于记录当前的活跃变量. 对于每个基本块, active_list的初始值为OUT. 从后往前遍历所有指令, 如果遇到对变量进行赋值的相关语句, 则判断该赋值结果是否在active_list中, 如果不在, 则删除该语句. 对于所有使用了变量的语句, 将使用的变量加入active_list中.

5. 常量折叠

   首先进行到达定值分析, 从头向后遍历所有基本块, 如果一个变量被赋值, 则记录该语句到r_gen中, 并且将被赋值的变量记录到r_kill中. 然后计算r_IN和r_OUT, 首先设置所有的r_OUT为空, 然后进行循环, 遍历所有基本块, 每次r_IN是当前基本块所有前驱r_OUT的并集, OUT是IN-r_kill和r_gen的并集. 重复循环直到所有基本块的r_OUT值不再变化.
   
   然后进行常量折叠, 维护一张表constant_list用于记录当前能用的常量. 对于每个基本块, constant_list初始值为r_IN中所有常量. 从前向后遍历所有指令, 如果遇到赋值语句则更新constant_list, 如果使用变量则判断是否需要将变量替换为常量.

#### 三、编译方法

使用makefile编译，输入命令`make`

#### 四、编译环境

1) GNU Linux Release: Ubuntu 20.04, kernel version 5.15.0-48-generic
2) GCC version 7.5.0
3) GNU Flex version 2.6.4
4) GNU Bison version 3.5.1