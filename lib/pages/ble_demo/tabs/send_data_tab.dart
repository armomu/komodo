import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../ble_demo_controller.dart';

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
    final colorScheme = theme.colorScheme;

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
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _descCtrl,
                          decoration: InputDecoration(
                            labelText: '描述（可选）',
                            hintText: '如：设置费率',
                            filled: true,
                            fillColor: colorScheme.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: colorScheme.outline,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _hexInputCtrl,
                          decoration: InputDecoration(
                            labelText: '十六进制数据',
                            hintText: '如: AA 01 00 BB',
                            prefixIcon: Icon(
                              Icons.code,
                              color: colorScheme.primary,
                            ),
                            filled: true,
                            fillColor: colorScheme.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: colorScheme.outline,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                        const SizedBox(height: 12),
                        Obx(
                          () => SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: ctrl.isConnected.value
                                  ? _sendCustomData
                                  : null,
                              icon: const Icon(Icons.send),
                              label: const Text('发送'),
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '发送数据示例：选择预设命令或输入自定义十六进制数据进行测试。发送的数据将显示在下方日志中。',
              style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildLogPanel() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '通信日志',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  ctrl.clearSendLogs();
                  ctrl.clearReceiveLogs();
                },
                child: const Text(
                  '清空',
                  style: TextStyle(color: Colors.blue, fontSize: 11),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 12),
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
                return const Center(
                  child: Text(
                    '暂无通信记录',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
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
                            style: const TextStyle(color: Colors.grey),
                          ),
                          TextSpan(
                            text: log.isSend ? '→ ' : '← ',
                            style: TextStyle(
                              color: log.isSend
                                  ? Colors.greenAccent
                                  : Colors.cyanAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: log.message,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          if (log.data != null) ...[
                            const TextSpan(
                              text: '\n    数据: ',
                              style: TextStyle(color: Colors.grey),
                            ),
                            TextSpan(
                              text: _formatHex(log.data!),
                              style: TextStyle(
                                color: log.isSend
                                    ? Colors.amberAccent
                                    : Colors.cyanAccent,
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
