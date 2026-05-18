import 'package:flutter/material.dart';
import 'package:komodo/plugins/reactive/reactive_plugin.dart';
import 'controllers/counter_controller.dart';
import 'services/logger_service.dart';

/// 注册 Demo 所需依赖（调用一次即可，重复调用幂等）
void _setupReactiveDependencies() {
  // 永久服务——整个 App 生命周期保持
  if (reactiveInjector.findOrNull<LoggerService>() == null) {
    reactiveInjector.putController(
      (inj) => LoggerService(),
      permanent: true,
    );
  }
  // 页面级控制器——由 RxPage 在页面销毁时自动清理
  reactiveInjector.putController((inj) => CounterController());
}

class ReactiveDemoPage extends StatelessWidget {
  const ReactiveDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    _setupReactiveDependencies();

    return RxPage(
      bindings: [
        (inj) => inj.find<CounterController>(),
      ],
      builder: (context) => const _ReactiveDemoView(),
    );
  }
}

class _ReactiveDemoView extends StatelessWidget {
  const _ReactiveDemoView();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = reactiveInjector.find<CounterController>();
    final logger = reactiveInjector.find<LoggerService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('响应式 DI + 状态管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: '打印日志',
            onPressed: () {
              logger.log('当前计数: ${controller.count.value}');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '已写入日志：计数 = ${controller.count.value}',
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── 计数器主区域 ──────────────────────────────────────
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 大计数数字（精确监听 count）
                  RxConsumer(
                    rx: controller.count,
                    builder: (context, value) => Text(
                      '$value',
                      style: TextStyle(
                        fontSize: 80,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 消息文本（精确监听 message）
                  RxConsumer(
                    rx: controller.message,
                    builder: (context, value) => Text(
                      value,
                      style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // 按钮组
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _CircleBtn(
                        icon: Icons.remove,
                        color: colorScheme.error,
                        onTap: controller.decrement,
                      ),
                      const SizedBox(width: 24),
                      _CircleBtn(
                        icon: Icons.add,
                        color: colorScheme.primary,
                        onTap: controller.increment,
                      ),
                      const SizedBox(width: 24),
                      _CircleBtn(
                        icon: Icons.refresh,
                        color: colorScheme.secondary,
                        onTap: controller.reset,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── 历史记录面板 ─────────────────────────────────────
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: isDark
                  ? colorScheme.surfaceContainerHighest
                  : colorScheme.surfaceContainerLow,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(15),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                  child: Row(
                    children: [
                      Icon(
                        Icons.history,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '操作历史',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      // 显示当前注入器里的控制器数量（调试信息）
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'RxController',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RxConsumer(
                    rx: controller.history,
                    builder: (context, historyList) {
                      if (historyList.isEmpty) {
                        return Center(
                          child: Text(
                            '暂无操作记录',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: historyList.length,
                        itemBuilder: (context, index) {
                          // 倒序展示最新的在最上面
                          final item =
                              historyList[historyList.length - 1 - index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  margin: const EdgeInsets.only(
                                    right: 10,
                                    left: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withAlpha(
                                      index == 0 ? 200 : 80,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Text(
                                  item,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: index == 0
                                        ? colorScheme.onSurface
                                        : colorScheme.onSurfaceVariant,
                                    fontWeight: index == 0
                                        ? FontWeight.w500
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 圆形操作按钮
class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CircleBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withAlpha(20),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          child: Icon(icon, color: color, size: 28),
        ),
      ),
    );
  }
}
