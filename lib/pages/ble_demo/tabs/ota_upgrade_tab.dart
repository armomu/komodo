import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../ble_demo_controller.dart';

/// OTA 升级 Tab
class OtaUpgradeTab extends StatelessWidget {
  const OtaUpgradeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final ctrl = Get.find<BleDemoController>();

    return Obx(() {
      final state = ctrl.otaState.value;

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 说明横幅 ────────────────────────────────────
            _buildInfoBanner(context),
            const SizedBox(height: 20),

            // ── 进度/状态卡片 ─────────────────────────────────
            _buildStatusCard(context, ctrl),
            const SizedBox(height: 20),

            // ── 文件选择区 ────────────────────────────────────
            _buildSectionTitle(context, '选择升级包'),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 文件名展示
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            ctrl.otaFileName.isEmpty
                                ? Icons.file_upload_outlined
                                : Icons.insert_drive_file_outlined,
                            color: ctrl.otaFileName.isEmpty
                                ? colorScheme.onSurfaceVariant
                                : colorScheme.onPrimaryContainer,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              ctrl.otaFileName.isEmpty
                                  ? '未选择文件'
                                  : ctrl.otaFileName.value,
                              style: TextStyle(
                                color: ctrl.otaFileName.isEmpty
                                    ? colorScheme.onSurfaceVariant
                                    : colorScheme.onSurface,
                                fontSize: 13,
                                fontFamily: 'monospace',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: _isLocked(state)
                            ? null
                            : () => _pickFile(ctrl),
                        icon: const Icon(Icons.folder_open_outlined, size: 18),
                        label: const Text('选择 .bin 升级包'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── 操作按钮 / 状态提示 ──────────────────────────────
            if (state == OtaState.idle || state == OtaState.failed)
              _buildStartButton(context, ctrl)
            else if (state == OtaState.success)
              _buildSuccessBanner(context, ctrl)
            else
              _buildUploadingState(context, ctrl),

            const SizedBox(height: 20),

            // ── 日志区域 ──────────────────────────────────────
            if (ctrl.otaLog.isNotEmpty) ...[
              _buildSectionTitle(context, '传输日志'),
              const SizedBox(height: 8),
              _buildLogPanel(context, ctrl),
            ],
          ],
        ),
      );
    });
  }

  bool _isLocked(OtaState state) =>
      state == OtaState.uploading || state == OtaState.verifying;

  Future<void> _pickFile(BleDemoController ctrl) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['bin', 'hex', 'ota'],
    );
    if (result != null && result.files.single.path != null) {
      ctrl.setOtaFile(result.files.single.path!, result.files.single.name);
    }
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
              'OTA 升级期间请保持蓝牙连接稳定，请勿断电。升级完成后设备将自动重启。',
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

  Widget _buildStatusCard(BuildContext context, BleDemoController ctrl) {
    final colorScheme = Theme.of(context).colorScheme;
    final state = ctrl.otaState.value;

    String statusText;
    Color statusColor;
    IconData statusIcon;

    switch (state) {
      case OtaState.idle:
        statusText = '等待升级';
        statusColor = colorScheme.onSurfaceVariant;
        statusIcon = Icons.hourglass_empty_rounded;
        break;
      case OtaState.selecting:
        statusText = '选择文件中';
        statusColor = const Color(0xFFF57C00);
        statusIcon = Icons.folder_open_rounded;
        break;
      case OtaState.uploading:
        statusText = '正在传输';
        statusColor = const Color(0xFF1976D2);
        statusIcon = Icons.upload_rounded;
        break;
      case OtaState.verifying:
        statusText = '校验中';
        statusColor = const Color(0xFF7B1FA2);
        statusIcon = Icons.verified_outlined;
        break;
      case OtaState.success:
        statusText = '升级成功';
        statusColor = const Color(0xFF2E7D32);
        statusIcon = Icons.check_circle_outline_rounded;
        break;
      case OtaState.failed:
        statusText = '升级失败';
        statusColor = const Color(0xFFD32F2F);
        statusIcon = Icons.error_outline_rounded;
        break;
    }

    final progress = ctrl.otaProgress.value;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '升级状态',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 进度条
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(statusColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton(BuildContext context, BleDemoController ctrl) {
    final canStart = ctrl.otaFileName.isNotEmpty;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton.icon(
        onPressed: canStart ? ctrl.startOta : null,
        icon: const Icon(Icons.rocket_launch_outlined, size: 18),
        label: const Text(
          '开始 OTA 升级',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildUploadingState(BuildContext context, BleDemoController ctrl) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              ctrl.otaState.value == OtaState.verifying
                  ? '设备正在校验升级包...'
                  : '正在分包传输，请勿断开连接...',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessBanner(BuildContext context, BleDemoController ctrl) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                color: Color(0xFF2E7D32),
                size: 28,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'OTA 升级完成！设备将自动重启。',
                  style: TextStyle(
                    color: Color(0xFF2E7D32),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton.icon(
            onPressed: ctrl.resetOta,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('重置'),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurfaceVariant,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildLogPanel(BuildContext context, BleDemoController ctrl) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D0D14) : const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
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
                '传输日志',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: ctrl.otaLog.clear,
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
            child: ListView.builder(
              itemCount: ctrl.otaLog.length,
              reverse: true,
              itemBuilder: (context, i) {
                final log = ctrl.otaLog[ctrl.otaLog.length - 1 - i];
                Color logColor = Colors.white.withValues(alpha: 0.6);
                if (log.contains('success') || log.contains('成功') || log.contains('完成')) {
                  logColor = const Color(0xFF66BB6A);
                }
                if (log.contains('失败') || log.contains('error') || log.contains('Error')) {
                  logColor = const Color(0xFFEF5350);
                }
                if (log.contains('校验') || log.contains('verif')) {
                  logColor = const Color(0xFFCE93D8);
                }
                return Text(
                  log,
                  style: TextStyle(
                    color: logColor,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
