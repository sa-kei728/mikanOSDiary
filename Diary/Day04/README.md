# Day4

## makeについて
基本知識が殆どだがおさらいがてらまとめる。  
```
TARGET = kernel.elf
OBJS = main.o

CXXFLAGS += -O2 -Wall -g --target=x86_64-elf -ffreestanding -mno-red-zone \
            -fno-exceptions -fno-rtti -std=c++17
LDFLAGS  += --entry KernelMain -z norelro --image-base 0x100000 --static
```
上記はビルドに必要な変数をまとめたもの。  
コンパイル、リンカオプションの意味は[Day03](../Day03/README.md)を参照  


```
.PHONY: all
all: $(TARGET)

.PHONY: clean
clean:
	rm -rf *.o

kernel.elf: $(OBJS) Makefile
	ld.lld $(LDFLAGS) -o kernel.elf $(OBJS)

%.o: %.cpp Makefile
	clang++ $(CPPFLAGS) $(CXXFLAGS) -c $<
```

これはルールと呼ばれるもので、下記のような構成になっている。  
```
ターゲット: 必須項目
    レシピ
```
.PHONYはphony target(偽ターゲット)という意味で、  
上記のようなall, cleanなど具体的なファイルがない場合でもルールを作る場合に宣言するもの。  
※なお、実際にall, cleanというファイル名があるときには必須設定になる。

今回の場合、make allを実行すると下記のフローで実行される。  
```
all: $(TARGET)=kernel.elf
    kernel.elf: $(OBJS)=main.o Makefile
        %.o=main.o: %.cpp=main.cpp Makefile
            main.cppのルールはないのでストップ
            Makefileのルールはないのでストップ
            clang++ $(CPPFLAGS) $(CXXFLAGS) -c $<=main.cpp
        Makefileのルールはないのでストップ
    ld.lld $(LDFLAGS) -o kernel.elf $(OBJS)=main.o
```

