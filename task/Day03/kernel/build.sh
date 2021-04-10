#!/bin/bash

clang++ -O2 -Wall -g --target=x86_64-elf -ffreestanding -mno-red-zone \
-fno-exceptions -fno-rtti -std=c++17 \
-I/usr/include/c++/7 -I/usr/include/x86_64-linux-gnu/ -I/usr/include/x86_64-linux-gnu/c++/7/  \
-c main.cpp

ld.lld --entry kernelMain -z norelro --image-base 0x100000 --static -o kernel.elf main.o
