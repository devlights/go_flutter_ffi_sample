// mylib_bindings.dart
//
// Go 側 (mylib.go) が cgo でエクスポートした C 関数への
// 低レベルバインディング定義です。
//
// C ヘッダー (libmylib.h) 側のシグネチャ:
//   extern int   Add(int a, int b);
//   extern char* Greet(char* name);
//   extern void  FreeString(char* s);
//
// dart:ffi では「ネイティブ側の型シグネチャ (Native)」と
// 「Dart 側で呼び出す際の型シグネチャ (Dart)」の2つを typedef で
// 定義し、asFunction<>() / lookupFunction<>() で変換するのが
// 基本パターンです。
// 文字列の UTF-8 変換には package:ffi (pub.dev) の
// toNativeUtf8() / toDartString() / calloc を利用します。
library mylib_bindings;

import 'dart:ffi' as ffi;
import 'dart:io' show Platform;
import 'package:ffi/ffi.dart' as pkg_ffi;

// ---- Native側 (C言語のシグネチャに対応する) 型定義 ----
typedef _AddNative = ffi.Int32 Function(ffi.Int32 a, ffi.Int32 b);
typedef _GreetNative = ffi.Pointer<pkg_ffi.Utf8> Function(
    ffi.Pointer<pkg_ffi.Utf8> name);
typedef _FreeStringNative = ffi.Void Function(ffi.Pointer<pkg_ffi.Utf8> s);

// ---- Dart側 (呼び出す際に使う) 型定義 ----
typedef _AddDart = int Function(int a, int b);
typedef _GreetDart = ffi.Pointer<pkg_ffi.Utf8> Function(
    ffi.Pointer<pkg_ffi.Utf8> name);
typedef _FreeStringDart = void Function(ffi.Pointer<pkg_ffi.Utf8> s);

/// Go の cgo c-shared ライブラリをロードし、型安全な Dart API として
/// 公開するラッパークラスです。
///
/// 実運用の Flutter アプリでは、ライブラリを Isolate 内で毎回
/// open するのではなく、アプリ起動時に一度だけロードして
/// シングルトンとして保持するのが定石です。
class MyLib {
  late final ffi.DynamicLibrary _lib;
  late final _AddDart _add;
  late final _GreetDart _greet;
  late final _FreeStringDart _freeString;

  /// [libraryPath] を省略した場合、OS ごとの標準的なファイル名で
  /// カレントディレクトリからロードを試みます。
  /// Flutter アプリでは、Android は so を jniLibs に、
  /// iOS/macOS は xcframework に、Windows/Linux はビルド成果物と
  /// 同一ディレクトリに配置し、DynamicLibrary.open() に絶対パス
  /// または相対パスを渡します。
  MyLib({String? libraryPath}) {
    _lib = ffi.DynamicLibrary.open(libraryPath ?? _defaultLibraryName());

    _add = _lib.lookupFunction<_AddNative, _AddDart>('Add');
    _greet = _lib.lookupFunction<_GreetNative, _GreetDart>('Greet');
    _freeString =
        _lib.lookupFunction<_FreeStringNative, _FreeStringDart>('FreeString');
  }

  static String _defaultLibraryName() {
    if (Platform.isWindows) return 'mylib.dll';
    if (Platform.isMacOS) return 'libmylib.dylib';
    return 'libmylib.so'; // Linux / Android
  }

  /// 2つの整数を Go 側の Add() で加算します。
  int add(int a, int b) => _add(a, b);

  /// 名前を渡して Go 側の Greet() で挨拶文字列を生成します。
  ///
  /// 重要: Greet() が返す char* は Go 側で C.CString() により
  /// malloc されたメモリです。Dart の GC はこれを管理しないため、
  /// 文字列に変換した後、必ず FreeString() (Go側の解放関数) で
  /// 解放します。finally 節で確実に解放するのがポイントです。
  String greet(String name) {
    // Dart側で確保するメモリ (引数用)。こちらは package:ffi の calloc で
    // 解放します（Go側のFreeStringを呼んではいけません。
    // アロケータが異なるため未定義動作になります）。
    final namePtr = name.toNativeUtf8();
    try {
      final resultPtr = _greet(namePtr);
      try {
        return resultPtr.toDartString();
      } finally {
        // Go側 (C.CString) が確保したメモリは、必ずGo側が提供する
        // 解放関数 (FreeString) を呼び出して解放する。
        _freeString(resultPtr);
      }
    } finally {
      pkg_ffi.calloc.free(namePtr);
    }
  }
}
