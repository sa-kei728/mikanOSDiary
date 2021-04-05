# Day2

## EDKII

UEFI上で動くアプリケーション及びUEFI自体の開発キット。
EDKIIに最低限必要なファイルが3種類あり、

- パッケージ宣言ファイル(.dec): パッケージ名などを設定
- パッケージ記述ファイル(.dsc):  
[define]ホストの情報やアーキテクチャの設定  
[LibrarycClass]必要なライブラリ名と実際に要するライブラリ(.inf)のパスを指定  
[Conponents]ビルド時のコンポーネント(.inf)を指定
- モジュール情報ファイル(.inf): 詳しくは[EDKII Module Information File Specification](https://edk2-docs.gitbook.io/edk-ii-inf-specification/)参照

EDKIIのライブラリを使ったMainコードは下記。  
エントリポイントなどはLoader.infでUefiMainを指すようになっているだけなので、名前が一致すれば名称は何でも良さそうだ。
```
#include  <Uefi.h>
#include  <Library/UefiLib.h>

EFI_STATUS EFIAPI UefiMain(
    EFI_HANDLE image_handle,
    EFI_SYSTEM_TABLE *system_table) {
  Print(L"Hello, Mikan World!\n");
  while (1);
  return EFI_SUCCESS;
}
```

Buildの流れとしては

1. Build対象のソースコード、dec, dsc, infをまとめたディレクトリへのシンボリックリンクをedk2内にはる。
2. edksetup.shをsource実行(多分PATHを通すだけかと)
3. Conf/target.infにACTIVE_PLATGORM/TARGET/TARGET_ARCH/TOOL_CHAIN_TAGを最低限指定
4. buildを実行し、EFIを生成。

Day01でのスクリプトでBOOT Imageを作成してQEMUで起動。  
![qemu_boot_day2](qemu_boot_day2.png)
