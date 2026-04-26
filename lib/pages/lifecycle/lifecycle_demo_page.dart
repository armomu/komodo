import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'lifecycle_controller.dart';
import 'widgets/lifecycle_test_widget.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 生命周期 Demo 页面入口
// ═══════════════════════════════════════════════════════════════════════════

class LifecycleDemoPage extends StatelessWidget {
  const LifecycleDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 按需注入 Controller（离开时自动销毁）
    Get.put(LifecycleController());

    return const _LifecycleDemoView();
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 主视图（StatefulWidget 以便演示自身生命周期）
// ─────────────────────────────────────────────────────────────────────────

class _LifecycleDemoView extends StatefulWidget {
  const _LifecycleDemoView();

  @override
  State<_LifecycleDemoView> createState() => _LifecycleDemoViewState();
}

class _LifecycleDemoViewState extends State<_LifecycleDemoView> {
  final LifecycleController _ctrl = Get.find();

  @override
  void initState() {
    super.initState();
    _ctrl.addLog('📱 Demo 页面 initState');
  }

  @override
  void dispose() {
    _ctrl.addLog('📱 Demo 页面 dispose');
    Get.delete<LifecycleController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('生命周期 Demo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Get.back(),
        ),
        actions: [
          // 清除日志
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: '清空日志',
            onPressed: _ctrl.clearLogs,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── 控制面板 ────────────────────────────────────────────
          _buildControlPanel(context),
          // ── 子组件预览区 ─────────────────────────────────────────
          _buildWidgetPreview(),
          // ── 日志列表 ─────────────────────────────────────────────
          Expanded(child: _buildLogPanel()),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 控制面板
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildControlPanel(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tune,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                '操作面板',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => _ActionButton(
                    icon: _ctrl.showChildWidget.value
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    label: _ctrl.showChildWidget.value ? '隐藏子组件' : '显示子组件',
                    color: _ctrl.showChildWidget.value
                        ? Colors.orange
                        : Colors.green,
                    onTap: _ctrl.toggleChildWidget,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  icon: Icons.title,
                  label: '切换标题',
                  color: Colors.purple,
                  onTap: _ctrl.toggleParentTitle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 子组件预览区
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildWidgetPreview() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Obx(() {
        if (!_ctrl.showChildWidget.value) {
          return Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.visibility_off, color: Colors.grey),
                  SizedBox(width: 8),
                  Text('子组件已隐藏', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          );
        }
        return LifecycleTestWidget(title: _ctrl.parentTitle.value);
      }),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 日志面板
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildLogPanel() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Row(
              children: [
                const Icon(Icons.terminal, color: Colors.greenAccent, size: 16),
                const SizedBox(width: 6),
                const Text(
                  '生命周期日志',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                const Spacer(),
                Obx(
                  () => Text(
                    '${_ctrl.logCount} 条',
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          // 日志内容
          Expanded(
            child: Obx(() {
              if (_ctrl.isEmptyLogs) {
                return const Center(
                  child: Text(
                    '暂无日志',
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                itemCount: _ctrl.logCount,
                itemBuilder: (context, index) {
                  final log = _ctrl.logs[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      log,
                      style: TextStyle(
                        color: _logColor(log),
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  /// 根据日志内容给不同颜色
  Color _logColor(String log) {
    if (log.contains('dispose') ||
        log.contains('销毁') ||
        log.contains('deactivate')) {
      return Colors.redAccent;
    } else if (log.contains('initState') ||
        log.contains('onReady') ||
        log.contains('初始化')) {
      return Colors.greenAccent;
    } else if (log.contains('build') || log.contains('构建')) {
      return Colors.lightBlueAccent;
    } else if (log.contains('清空')) {
      return Colors.orangeAccent;
    }
    return Colors.white70;
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 操作按钮组件
// ─────────────────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
