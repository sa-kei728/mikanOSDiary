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
なお、本環境は特にIncludePathをclang向けに設定できてないので、下記の設定が必要。
```
CXXFLAGS += -I/usr/include/c++/7 -I/usr/include/x86_64-linux-gnu/ -I/usr/include/x86_64-linux-gnu/c++/7/
```

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

# ピクセル描画
UEFIにてピクセルのデータ形式は下記のように定められている。  
[UEFIの仕様書](https://uefi.org/sites/default/files/resources/UEFI_Spec_2_8_final.pdf)の  
PDFで見づらいので、RustのRedoxOSで使われている[UEFIの仕様](https://docs.rs/redox_uefi/0.1.0/uefi/graphics/enum.GraphicsPixelFormat.html)も参考として挙げておく。  
|データ形式|説明|
|---|---|
|PixelRedGreenBlueReserved8BitPerColor|1ピクセルは32ビットで、バイト0が赤、バイト1が緑、バイト2が青、バイト3が予約。赤、緑、青の各成分のバイト値は、色の強度を表していて、最小の強さ0から最大の強さ255までの範囲になる。|
|PixelBlueGreenRedReserved8BitPerColor|1ピクセルは32ビットで、バイト0が青、バイト1が緑、バイト2が赤、バイト3が予約。青、緑、赤の各成分のバイト値は、色の強度を表していて、最小の強さ0から最大の強さ255までの範囲になる。|
|PixelBitMask|固有のBitMask設定によって色表現を行う。基本使わない。|
|PixelBltOnly|ピクセル単位で描画せず、メモリ上の絵をコピーすることで描画。基本使わない。|

```
  struct FrameBufferConfig config = {
    (UINT8*)gop->Mode->FrameBufferBase,
    gop->Mode->Info->PixelsPerScanLine,
    gop->Mode->Info->HorizontalResolution,
    gop->Mode->Info->VerticalResolution,
    0
  };
  switch (gop->Mode->Info->PixelFormat) {
    case PixelRedGreenBlueReserved8BitPerColor:
      config.pixel_format = kPixelRGBResv8BitPerColor;
      break;
    case PixelBlueGreenRedReserved8BitPerColor:
      config.pixel_format = kPixelBGRResv8BitPerColor;
      break;
    default:
      Print(L"Unimplemented pixel format: %d\n", gop->Mode->Info->PixelFormat);
      Halt();
  }

  typedef void EntryPointType(const struct FrameBufferConfig*);
  EntryPointType* entry_point = (EntryPointType*)entry_addr;
  entry_point(&config);
```
UEFI側にGOPから情報取得して、EntryPointに渡すようにBootLoaderを変更。

```
extern "C" void KernelMain(const FrameBufferConfig& frame_buffer_config) {
  for (int x = 0; x < frame_buffer_config.horizontal_resolution; ++x) {
    for (int y = 0; y < frame_buffer_config.vertical_resolution; ++y) {
      WritePixel(frame_buffer_config, x, y, {255, 255, 255});
    }
  }
  for (int x = 0; x < 200; ++x) {
    for (int y = 0; y < 100; ++y) {
      WritePixel(frame_buffer_config, 100 + x, 100 + y, {0, 255, 0});
    }
  }
  while (1) __asm__("hlt");
}
```
Kernel側では受け取ったフレームバッファ情報を基にピクセル描画を行う。  
まずは全体を白埋めした後、(100, 100)~(300, 200)の区画を緑で埋める。

```
struct PixelColor {
  uint8_t r, g, b;
};

/** WritePixelは1つの点を描画します．
 * @retval 0   成功
 * @retval 非0 失敗
 */
int WritePixel(const FrameBufferConfig& config,
               int x, int y, const PixelColor& c) {
  const int pixel_position = config.pixels_per_scan_line * y + x;
  if (config.pixel_format == kPixelRGBResv8BitPerColor) {
    uint8_t* p = &config.frame_buffer[4 * pixel_position];
    p[0] = c.r;
    p[1] = c.g;
    p[2] = c.b;
  } else if (config.pixel_format == kPixelBGRResv8BitPerColor) {
    uint8_t* p = &config.frame_buffer[4 * pixel_position];
    p[0] = c.b;
    p[1] = c.g;
    p[2] = c.r;
  } else {
    return -1;
  }
  return 0;
}
```
WritePixelは1ラインごとのピクセル数とXY座標の位置を基に、フレームバッファ上のピクセル位置を算出して、  
RGB or BGRの情報を書き出す。

BootLoaderとKernelを作成し、QEMU用のディスクを作って起動。  
![green_square](./green_square.png)  

