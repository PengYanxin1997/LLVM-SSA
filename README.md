LLVM-SSA
========================

  我使用LLVM框架进行静态程序分析，使用LLVM框架中的Clang前端工具生成LLVM-IR，而LLVM-IR就是SSA形式。（但实际使用过程中发现LLVM-IR并不是严格的SSA）。

1 构造一个无法完全转换成SSA形式的程序
------------------------------
  我构造了一个C程序，源码见`/src/test.c`
  
  由于C语言指针的特性，同一个内存位置可能有不同的别名，因此无法保证需要分析的每一个内存位置一旦赋值都不会发生改变。这就需要将变量分为address-taken（曾被取过地址的变量）和top-level（未被取过地址的变量）两组，含有address-taken变量的程序无法完全转换成SSA，需要一些其他的机制来实现中间代码的转换。
按照这个思路，我构造的程序为：

    int f() {
    
       int x = 10;
       int *i;
       i = &x;
       *i = 11;
       *i = *i +1;
       return a;
    }

2 使用Clang工具生成LLVM中间形式
--------------
LLVM IR有3种表示形式

* text:便于阅读的文本格式，类似于汇编语言，拓展名.ll
* memory:内存格式
* bitcode:二进制格式，拓展名.bc

它们本质是等价的，所以我以text形式查看，编译命令为：

`clang -S -emit-llvm -O0 test.c -o test.ll`

生成的ll文件在`/dist/test.ll`，部分IR内容为：

      %1 = alloca i32, align 4
      %2 = alloca i32*, align 8
      store i32 6, i32* %1, align 4
      store i32* %1, i32** %2, align 8
      %3 = load i32*, i32** %2, align 8
      store i32 11, i32* %3, align 4
      %4 = load i32*, i32** %2, align 8
      %5 = load i32, i32* %4, align 4
      %6 = add nsw i32 %5, 1
      %7 = load i32*, i32** %2, align 8
      store i32 %6, i32* %7, align 4
      %8 = load i32, i32* %1, align 4
      ret i32 %8

其中有一些LLVM的基本语法：
* %：局部标识符，以%开头
* alloca：在当前函数栈帧中分配内存
* i32：32bit，4个字节整型
* align：内存对齐位数
* store：写入数据
* load：读取数据，存入一个局部标识符

为了便于您阅读，我尝试把上面的LLVM-IR形式表示成更容易读的格式：

    alloca x0
    alloca *y0
    x0 = 6
    y0 = &x0

    ;following instructions’ function is:*y = 11
    y1 = y0    
    *y1 = 11

    ;following instructions’ function is:*y = *y+1
    y2 = y0
    y3 = *y2
    y4 = y3 +1
    y5 = y0
    *y5 = y4

    x1 = *(&x0)
    return x1;

可以很容易地看出，以上形式并非SSA（%2使用大于两次，即使内存地址的内容改变）。但是我注意到不论变量是否被取过地址，好像LLVM对变量的使用均会创建一个局部标识符（即不论变量是否被赋值，均使用新的变量下标）。于是我进行了进一步的验证。


3 构造一个可以完全转换成SSA形式的程序
--------------------
我编写了一个只含top-level变量的C程序，代码见`/src/test2.c`
部分代码为：

    int f(int a,int b){
    double c = 5.5;

    if(a>b) c = a;
    else c = b;
    //…

对应的ll文件见`dist/test2-O0.ll`，部分内容为：


    define dso_local i32 @f(i32 %0, i32 %1) #0 {
        %3 = alloca i32, align 4
        %4 = alloca i32, align 4
        %5 = alloca double, align 8
        %6 = alloca i32, align 4
        store i32 %0, i32* %3, align 4
        store i32 %1, i32* %4, align 4
        store double 5.500000e+00, double* %5, align 8
        %7 = load i32, i32* %3, align 4
        %8 = load i32, i32* %4, align 4
        %9 = icmp sgt i32 %7, %8
        br i1 %9, label %10, label %13


可以看到，在判断a是否大于b的语句中，即使a、b变量在使用前都没有被修改过值，Clang编译后依然使用了不必要的新的局部标识符（%7、%8）。因此可以断定，使用O0级编译生成的LLVM的中间形式不是简化的SSA形式。

后来我继续了解发现，这是LLVM所特有的特性，这样做主要是为了将前端Clang分离。LLVM官方文档对此也有说明：

> LLVM does require all register values to be in SSA form, it does not require (or permit) memory objects to be in SSA form.

如果是因为O0级别的编译不作任何优化才导致的非简化SSA形式，那么尝试O1级别的编译会怎么样呢，编译test2.c产生的文件在`/dist/test2-01.ll`，可以看到其形式非常简洁，但一定是SSA形式。

因此得到一个结论，LLVM-IR不一定是最简化的SSA表示。


4 实验中踩过的坑
------------
编译LLVM出现错误：

`collect2: error: ld terminated with signal 9 [Killed]`

我使用的是Ubuntu虚拟机环境，编译出错主要原因是虚拟机虚拟内存不足导致，而虚拟机swap分区不够大，所以需要新建个swap分区，可使用GParted工具，或者参考网上的方法：

    cd /
    sudo mkdir swapfile
    sudo dd if=/dev/zero of=swap bs=1024 count=20000000
    sudo mkswap -f  swap
    sudo swapon swap
    
同时，编译整个LLVM时默认是debug模式的，这会非常耗时，如果只编译其中Clang工具的release版会节省很多时间，具体命令为：

`cmake -DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_PROJECTS=clang -G "Unix Makefiles" ../llvm`
