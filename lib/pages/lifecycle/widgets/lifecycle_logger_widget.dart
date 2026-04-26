import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../lifecycle_controller.dart';

/// 生命周期日志显示组件
class LifecycleLoggerWidget extends StatelessWidget {
  const LifecycleLoggerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LifecycleController>();

    return Container(
      color: Colors.black87,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.black54,
            child: const Row(
              children: [
                Icon(Icons.terminal, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  '生命周期日志输出',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(
              () => ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: controller.logs.length,
                itemBuilder: (context, index) {
                  return _buildLogItem(controller.logs[index]);
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: controller.clearLogs,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 40),
              ),
              child: const Text('清空日志'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(String log) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _getLogColor(log),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        log,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Color _getLogColor(String log) {
    if (log.contains('initState')) return Colors.green[700]!;
    if (log.contains('dispose')) return Colors.red[700]!;
    if (log.contains('setState')) return Colors.orange[700]!;
    if (log.contains('didUpdateWidget')) return Colors.purple[700]!;
    if (log.contains('didChangeDependencies')) return Colors.cyan[700]!;
    if (log.contains('deactivate')) return Colors.yellow[800]!;
    if (log.contains('build')) return Colors.blue[700]!;
    return Colors.grey[800]!;
  }
}
