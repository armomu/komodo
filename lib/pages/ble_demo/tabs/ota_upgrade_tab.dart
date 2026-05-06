import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../ble_demo_controller.dart';

/// OTA 升级 Tab
class OtaUpgradeTab extends StatelessWidget {
  const OtaUpgradeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<BleDemoController>();

    return Obx(() {
      final state = ctrl.otaState.value;

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 说明横幅 ────────────────────────────────────
            _buildInfoBanner(),
            const SizedBox(height: 20),

            // ── 进度/状态卡片 ─────────────────────────────────
            _buildStatusCard(ctrl),
            const SizedBox(height: 20),

            // ── 文件选择区 ────────────────────────────────────
            _buildSectionTitle('选择升级包'),
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
                    // 文件名展示
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            ctrl.otaFileName.isEmpty
                                ? Icons.file_upload_outlined
                                : Icons.insert_drive_file_outlined,
                            color: ctrl.otaFileName.isEmpty
                                ? Colors.grey
                                : Colors.blue,
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
                                    ? Colors.grey
                                    : Colors.black87,
                                fontSize: 13,
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
                        icon: const Icon(Icons.folder_open_outlined),
                        label: const Text('选择 .bin 升级包'),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── 操作按钮 ──────────────────────────────────────
            if (state == OtaState.idle || state == OtaState.failed)
              _buildStartButton(ctrl)
            else if (state == OtaState.success)
              _buildSuccessBanner(ctrl)
            else
              _buildUploadingState(ctrl),

            const SizedBox(height: 20),

            // ── 日志区域 ──────────────────────────────────────
            if (ctrl.otaLog.isNotEmpty) ...[
              _buildSectionTitle('传输日志'),
              _buildLogPanel(ctrl),
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

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: Colors.blue[600]),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'OTA 升级期间请保持手机与设备蓝牙连接稳定，升级期间请勿断电。升级完成后设备将自动重启。',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(BleDemoController ctrl) {
    final state = ctrl.otaState.value;
    String statusText;
    Color statusColor;
    IconData statusIcon;

    switch (state) {
      case OtaState.idle:
        statusText = '等待升级';
        statusColor = Colors.grey;
        statusIcon = Icons.hourglass_empty;
        break;
      case OtaState.selecting:
        statusText = '选择文件中';
        statusColor = Colors.orange;
        statusIcon = Icons.folder_open;
        break;
      case OtaState.uploading:
        statusText = '正在传输';
        statusColor = Colors.blue;
        statusIcon = Icons.upload;
        break;
      case OtaState.verifying:
        statusText = '校验中';
        statusColor = Colors.purple;
        statusIcon = Icons.verified_outlined;
        break;
      case OtaState.success:
        statusText = '升级成功';
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        break;
      case OtaState.failed:
        statusText = '升级失败';
        statusColor = Colors.red;
        statusIcon = Icons.error_outline;
        break;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 28),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '升级状态',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
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
                const Spacer(),
                Text(
                  '${(ctrl.otaProgress.value * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ctrl.otaProgress.value,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(statusColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton(BleDemoController ctrl) {
    final canStart = ctrl.otaFileName.isNotEmpty;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: canStart ? ctrl.startOta : null,
        icon: const Icon(Icons.rocket_launch_outlined),
        label: const Text('开始 OTA 升级', style: TextStyle(fontSize: 16)),
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildUploadingState(BleDemoController ctrl) {
    return Card(
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                ctrl.otaState.value == OtaState.verifying
                    ? '设备正在校验升级包...'
                    : '正在分包传输，请勿断开连接...',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessBanner(BleDemoController ctrl) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'OTA 升级完成！设备将自动重启。',
                  style: TextStyle(
                    color: Colors.green,
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
            icon: const Icon(Icons.refresh),
            label: const Text('重置'),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget _buildLogPanel(BleDemoController ctrl) {
    return Container(
      width: double.infinity,
      height: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '传输日志',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: ctrl.otaLog.clear,
                child: const Text(
                  '清空',
                  style: TextStyle(color: Colors.blue, fontSize: 11),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: ctrl.otaLog.length,
              reverse: true,
              itemBuilder: (context, i) {
                final log = ctrl.otaLog[ctrl.otaLog.length - 1 - i];
                Color logColor = Colors.white70;
                if (log.contains('✅')) logColor = Colors.greenAccent;
                if (log.contains('❌')) logColor = Colors.redAccent;
                if (log.contains('校验')) logColor = Colors.purpleAccent;
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
