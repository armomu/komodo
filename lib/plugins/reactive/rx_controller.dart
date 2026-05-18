import 'package:flutter/foundation.dart';

/// 响应式控制器基类（类似 GetX 的 GetxController）
abstract class RxController extends ChangeNotifier {
  bool _disposed = false;

  /// 控制器被销毁时调用（可 override 做清理）
  void onClose() {
    if (!_disposed) {
      _disposed = true;
      dispose();
    }
  }

  @override
  void dispose() {
    if (!_disposed) {
      _disposed = true;
      super.dispose();
    }
  }

  /// 手动触发 UI 更新
  void update() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  /// 是否已销毁
  bool get isDisposed => _disposed;
}
