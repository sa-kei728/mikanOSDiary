#!/bin/bash

qemu-img create -f raw disk.img 200M
mkfs.fat -n 'MIKAN OS' -s 2 -f 2 -R 32 -F 32 disk.img
mkdir -p mnt
sudo mount -o loop disk.img mnt
sudo mkdir -p mnt/EFI/BOOT
#sudo cp Loader.efi mnt/EFI/BOOT/BOOTX64.EFI
#sudo cp Loader_GOP.efi mnt/EFI/BOOT/BOOTX64.EFI
sudo cp Loader_kernelFrame.efi mnt/EFI/BOOT/BOOTX64.EFI
sudo cp kernel/kernel.elf mnt/
sudo umount mnt
