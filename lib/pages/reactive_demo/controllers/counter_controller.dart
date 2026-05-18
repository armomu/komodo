import 'package:komodo/plugins/reactive/reactive_plugin.dart';

/// 响应式计数器控制器（Demo 用）
class CounterController extends RxController {
  final Rx<int> count = Rx<int>(0);
  final Rx<String> message = Rx<String>('点击按钮增加计数');
  final RxList<String> history = RxList<String>([]);

  void increment() {
    count.value++;
    message.value = '当前计数: ${count.value}';
    history.add('增加 → ${count.value}');
  }

  void decrement() {
    if (count.value > 0) {
      count.value--;
      message.value = '当前计数: ${count.value}';
      history.add('减少 → ${count.value}');
    }
  }

  void reset() {
    count.value = 0;
    message.value = '已重置';
    history.clear();
    history.add('重置 → 0');
  }

  @override
  void onClose() {
    // ignore: avoid_print
    print('CounterController 已销毁');
    super.onClose();
  }
}
