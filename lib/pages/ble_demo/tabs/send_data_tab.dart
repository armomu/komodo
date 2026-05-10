import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../ble_demo_controller.dart';
import '../widgets/hex_keyboard.dart';

/// 合并后的日志条目
class _MergedLogEntry {
  final String time;
  final bool isSend;
  final String message;
  final List<int>? data;

  _MergedLogEntry({
    required this.time,
    required this.isSend,
    required this.message,
    this.data,
  });
}

/// 发送数据 Tab（合并了发送和接收日志）
class SendDataTab extends StatefulWidget {
  const SendDataTab({super.key});

  @override
  State<SendDataTab> createState() => _SendDataTabState();
}

class _SendDataTabState extends State<SendDataTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final ctrl = Get.find<BleDemoController>();

  // 自定义发送数据
  final _hexInputCtrl = TextEditingController(text: 'AA 01 00 BB');
  final _descCtrl = TextEditingController(text: '测试命令');

  @override
  void dispose() {
    _hexInputCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _sendCustomData() {
    final hexStr = _hexInputCtrl.text.replaceAll(' ', '').toUpperCase();
    if (hexStr.isEmpty) {
      Get.snackbar('提示', '请输入十六进制数据', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      final bytes = <int>[];
      for (int i = 0; i < hexStr.length; i += 2) {
        bytes.add(int.parse(hexStr.substring(i, i + 2), radix: 16));
      }
      ctrl.sendCustomData(
        bytes,
        _descCtrl.text.trim().isEmpty ? '自定义数据' : _descCtrl.text.trim(),
      );
    } catch (e) {
      Get.snackbar(
        '格式错误',
        '请输入有效的十六进制数据（如 AA 01 00 BB）',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return Column(
      children: [
        // ── 操作区 ────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 说明 ─────────────────────────────────────
                _buildInfoBanner(context),
                const SizedBox(height: 16),

                // ── 自定义发送 ─────────────────────────────────
                _buildSectionTitle('自定义发送', theme),
                const SizedBox(height: 8),
                Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _descCtrl,
                          decoration: const InputDecoration(
                            labelText: '描述（可选）',
                            hintText: '如：设置费率',
                          ),
                        ),
                        const SizedBox(height: 12),
                        _HexInputField(
                          controller: _hexInputCtrl,
                          onTap: () {
                            HexKeyboard.show(
                              value: _hexInputCtrl.text,
                              onConfirm: (val) {
                                setState(() => _hexInputCtrl.text = val);
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Obx(
                          () => SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: FilledButton.icon(
                              onPressed: ctrl.isConnected.value
                                  ? _sendCustomData
                                  : null,
                              icon: const Icon(Icons.send_rounded, size: 18),
                              label: const Text('发送'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── 日志面板（发送+接收合并）─────────────────────────────
        _buildLogPanel(),
      ],
    );
  }

  Widget _buildInfoBanner(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '输入自定义十六进制数据进行测试，发送和接收数据将显示在下方日志中。',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onPrimaryContainer,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurfaceVariant,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildLogPanel() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D0D14) : const Color(0xFF1A1A2E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.terminal_rounded,
                size: 14,
                color: Colors.white.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 6),
              const Text(
                '通信日志',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  ctrl.clearSendLogs();
                  ctrl.clearReceiveLogs();
                },
                child: Text(
                  '清空',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 16),
          Expanded(
            child: Obx(() {
              // 合并发送和接收日志
              final allLogs = <_MergedLogEntry>[];
              for (final log in ctrl.sendLogs) {
                allLogs.add(
                  _MergedLogEntry(
                    time: log.time,
                    isSend: true,
                    message: log.message,
                    data: log.data,
                  ),
                );
              }
              for (final log in ctrl.receiveLogs) {
                allLogs.add(
                  _MergedLogEntry(
                    time: log.time,
                    isSend: false,
                    message: log.message,
                    data: log.data,
                  ),
                );
              }
              // 按时间倒序
              allLogs.sort((a, b) => b.time.compareTo(a.time));

              if (allLogs.isEmpty) {
                return Center(
                  child: Text(
                    '暂无通信记录',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.25),
                      fontSize: 12,
                    ),
                  ),
                );
              }
              return ListView.builder(
                itemCount: allLogs.length,
                itemBuilder: (context, i) {
                  final log = allLogs[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                        children: [
                          TextSpan(
                            text: '[${log.time}] ',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.35),
                            ),
                          ),
                          TextSpan(
                            text: log.isSend ? 'TX ' : 'RX ',
                            style: TextStyle(
                              color: log.isSend
                                  ? const Color(0xFF66BB6A)
                                  : const Color(0xFF42A5F5),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: log.message,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          if (log.data != null) ...[
                            TextSpan(
                              text: '\n    ',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            TextSpan(
                              text: _formatHex(log.data!),
                              style: TextStyle(
                                color: log.isSend
                                    ? const Color(0xFFFFB74D)
                                    : const Color(0xFF4DD0E1),
                              ),
                            ),
                          ],
                        ],
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

  String _formatHex(List<int> data) {
    return data
        .map((e) => e.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(' ');
  }
}

// ── 十六进制输入展示框（只读，点击弹键盘）────────────────────────
class _HexInputField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onTap;

  const _HexInputField({required this.controller, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, __) {
          final empty = controller.text.isEmpty;
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0D0D14) : const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.keyboard_alt_outlined,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.45),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: empty
                      ? Text(
                          '点击输入十六进制数据',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 13,
                            fontFamily: 'monospace',
                          ),
                        )
                      : Text(
                          controller.text,
                          style: const TextStyle(
                            color: Color(0xFFFFD60A),
                            fontSize: 14,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: Colors.white.withValues(alpha: 0.25),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
