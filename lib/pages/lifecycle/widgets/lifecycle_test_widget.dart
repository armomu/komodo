import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../lifecycle_controller.dart';

/// 生命周期测试子组件
class LifecycleTestWidget extends StatefulWidget {
  final String title;

  const LifecycleTestWidget({super.key, required this.title});

  @override
  State<LifecycleTestWidget> createState() {
    return _LifecycleTestWidgetState();
  }
}

class _LifecycleTestWidgetState extends State<LifecycleTestWidget> {
  int _counter = 0;

  _LifecycleTestWidgetState() {
    _addLog('🏗️ 构造函数执行');
  }

  /// 辅助方法：安全地添加日志
  void _addLog(String message) {
    if (Get.isRegistered<LifecycleController>()) {
      Get.find<LifecycleController>().addLog(message);
    }
  }

  @override
  void initState() {
    super.initState();
    _addLog('🌱 initState - 初始化开始');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _addLog('🔄 didChangeDependencies');
  }

  @override
  Widget build(BuildContext context) {
    _addLog('🎨 build - 构建UI (计数器: $_counter)');
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.code, size: 40, color: Colors.blue),
            const SizedBox(height: 8),
            Text('📝 传入: ${widget.title}'),
            Text('🔢 计数: $_counter'),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _addLog('🔘 点击增加计数');
                    setState(() {
                      _counter++;
                    });
                  },
                  child: const Text('增加'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    _addLog('🔄 点击强制重建');
                    setState(() {});
                  },
                  child: const Text('刷新'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant LifecycleTestWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _addLog('🔄 didUpdateWidget');
    if (oldWidget.title != widget.title) {
      _addLog('   ⚠️ 标题已变: ${widget.title}');
    }
  }

  @override
  void deactivate() {
    _addLog('⚠️ deactivate - 即将移除');
    super.deactivate();
  }

  @override
  void dispose() {
    _addLog('🗑️ dispose - 永久销毁');
    super.dispose();
  }
}
