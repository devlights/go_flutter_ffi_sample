// mylib.go
//
// cgo を使って C ABI 互換の共有ライブラリ (.so / .dll / .dylib) を
// 生成するための Go ソースです。
//
// ビルド例:
//   Linux:   CGO_ENABLED=1 go build -buildmode=c-shared -o libmylib.so mylib.go
//   Windows: CGO_ENABLED=1 GOOS=windows CC=x86_64-w64-mingw32-gcc go build -buildmode=c-shared -o mylib.dll mylib.go
//   macOS:   CGO_ENABLED=1 GOOS=darwin  go build -buildmode=c-shared -o libmylib.dylib mylib.go
//
// -buildmode=c-shared を指定すると、mylib.h という C ヘッダーファイルも
// 自動生成されます (Dart 側では直接使いませんが、C/C++ から利用する際の
// シグネチャ確認に有用です)。
package main

/*
#include <stdlib.h>
*/
import "C"

import (
	"fmt"
	"unsafe"
)

// Add は2つの整数を加算します。
// int/int32 のようなプリミティブ型は cgo が自動的に C の int32_t 等に
// マッピングしてくれるため、特別な変換は不要です。
//
//export Add
func Add(a C.int, b C.int) C.int {
	return a + b
}

// Greet は名前を受け取り、挨拶文字列を生成して返します。
//
// 文字列を Go -> C 境界を越えて返す場合、C.CString() で
// C 側が解放責任を持つ *C.char (malloc されたメモリ) を作成する必要があります。
// Go の GC はこのメモリを管理しないため、呼び出し側 (今回は Dart) が
// 使い終わったら必ず FreeString を呼び出してメモリを解放してください。
//
//export Greet
func Greet(name *C.char) *C.char {
	goName := C.GoString(name) // *C.char -> Go string への変換
	result := fmt.Sprintf("Hello, %s! (from Go via cgo)", goName)
	return C.CString(result) // Go string -> malloc された *C.char への変換
}

// FreeString は Greet などが返した *C.char のメモリを解放します。
// C.CString / C.malloc で確保したメモリは C.free で解放する必要があります。
//
//export FreeString
func FreeString(s *C.char) {
	C.free(unsafe.Pointer(s))
}

// main 関数は c-shared / c-archive ビルドモードでは実行されませんが、
// package main としてビルドするために空実装として必須です。
func main() {}
