// main.dart
//
// Flutter アプリの main() や、任意の Widget/Provider から呼び出す
// イメージのサンプル実行コードです。
// 実際の Flutter プロジェクトでは、このロジックを Service クラスや
// Repository クラスに置き、UI から利用してください。
import 'mylib_bindings.dart';

void main() {
  // ビルド済みの libmylib.so への絶対パスを指定してロード。
  // (Flutter アプリでは通常、OSごとの標準配置場所からロードするため
  //  libraryPath は省略できます)
  final mylib = MyLib(libraryPath: '../build/linux/libmylib.so');

  final sum = mylib.add(3, 4);
  print('Add(3, 4) = $sum');

  final greeting = mylib.greet('devlights');
  print('Greet("devlights") = $greeting');
}
