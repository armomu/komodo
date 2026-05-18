import 'package:komodo/plugins/reactive/reactive_plugin.dart';

/// 日志服务（Demo 用，全局永久保留）
class LoggerService extends RxController {
  final RxList<String> logs = RxList<String>([]);

  void log(String message) {
    // ignore: avoid_print
    print('[LOG] $message');
    logs.add('[${DateTime.now().toLocal().toString().substring(11, 19)}] $message');
  }

  void clearLogs() {
    logs.clear();
  }

  @override
  void onClose() {
    // ignore: avoid_print
    print('LoggerService 已销毁');
    super.onClose();
  }
}
