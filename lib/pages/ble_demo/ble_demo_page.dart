import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';

import 'ble_demo_controller.dart';
import 'ble_demo_dashboard_page.dart';

/// 蓝牙示例主页——设备扫描与连接
class BleDemoPage extends StatefulWidget {
  const BleDemoPage({super.key});

  @override
  State<BleDemoPage> createState() => _BleDemoPageState();
}

class _BleDemoPageState extends State<BleDemoPage> {
  final ctrl = Get.put(BleDemoController());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('蓝牙设备'),
        actions: [
          Obx(
            () => ctrl.isConnected.value
                ? TextButton.icon(
                    onPressed: ctrl.disconnectDevice,
                    icon: Icon(
                      Icons.bluetooth_disabled,
                      size: 16,
                      color: colorScheme.error,
                    ),
                    label: Text(
                      '断开',
                      style: TextStyle(
                        color: colorScheme.error,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── 顶部状态卡片 ──────────────────────────────────────
          _StatusCard(ctrl: ctrl),
          const SizedBox(height: 4),

          // ── 扫描结果列表标题 ──────────────────────────────────
          Obx(
            () => Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  Text(
                    '附近设备',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  if (ctrl.scanResults.isNotEmpty)
                    Text(
                      '${ctrl.scanResults.length} 台',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(width: 8),
                  if (ctrl.isScanning.value)
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── 设备列表 ──────────────────────────────────────────
          Expanded(child: _ScanResultsList(ctrl: ctrl)),
        ],
      ),

      // ── 底部扫描按钮 ────────────────────────────────────────
      floatingActionButton: Obx(
        () => FloatingActionButton.extended(
          onPressed: ctrl.isScanning.value ? ctrl.stopScan : ctrl.startScan,
          icon: Icon(
            ctrl.isScanning.value
                ? Icons.stop_rounded
                : Icons.bluetooth_searching,
            size: 20,
          ),
          label: Text(
            ctrl.isScanning.value ? '停止扫描' : '扫描设备',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// ── 状态卡片 ─────────────────────────────────────────────────
class _StatusCard extends StatelessWidget {
  final BleDemoController ctrl;
  const _StatusCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Obx(() {
      final connected = ctrl.isConnected.value;

      return Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: connected
              ? (isDark ? colorScheme.primary : colorScheme.primary)
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          boxShadow: connected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(
                      alpha: isDark ? 0.2 : 0.12,
                    ),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // 蓝牙图标
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: connected
                    ? (isDark
                          ? colorScheme.onPrimary.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.2))
                    : colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                connected
                    ? Icons.bluetooth_connected
                    : Icons.bluetooth_outlined,
                color: connected
                    ? (isDark ? colorScheme.onPrimary : Colors.white)
                    : colorScheme.onPrimaryContainer,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            // 设备信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    connected
                        ? (ctrl
                                      .connectedDevice
                                      .value
                                      ?.platformName
                                      .isNotEmpty ==
                                  true
                              ? ctrl.connectedDevice.value!.platformName
                              : '蓝牙设备')
                        : '未连接设备',
                    style: TextStyle(
                      color: connected
                          ? (isDark ? colorScheme.onPrimary : Colors.white)
                          : colorScheme.onSurface,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    connected
                        ? (ctrl.connectedDevice.value?.remoteId.str ?? '—')
                        : '扫描并连接附近的蓝牙设备',
                    style: TextStyle(
                      color: connected
                          ? (isDark
                                ? colorScheme.onPrimary.withValues(alpha: 0.7)
                                : Colors.white.withValues(alpha: 0.75))
                          : colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // 进入按钮
            if (connected)
              Container(
                decoration: BoxDecoration(
                  color: isDark ? colorScheme.onPrimary : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () => Get.to(() => const BleDemoDashboardPage()),
                  icon: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: isDark ? colorScheme.primary : colorScheme.primary,
                  ),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(40, 40),
                    maximumSize: const Size(40, 40),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

// ── 扫描结果列表 ──────────────────────────────────────────────
class _ScanResultsList extends StatelessWidget {
  final BleDemoController ctrl;
  const _ScanResultsList({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.scanResults.isEmpty && !ctrl.isScanning.value) {
        return _buildEmptyHint(context);
      }
      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: ctrl.scanResults.length,
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemBuilder: (context, i) {
          return _DeviceCard(result: ctrl.scanResults[i]);
        },
      );
    });
  }

  Widget _buildEmptyHint(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.bluetooth_searching_rounded,
                size: 40,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '暂未发现设备',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '点击下方按钮扫描附近蓝牙设备',
              style: TextStyle(color: colorScheme.outline, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 单个设备卡片 ──────────────────────────────────────────────
class _DeviceCard extends StatelessWidget {
  final ScanResult result;
  const _DeviceCard({required this.result});

  /// 根据 RSSI 估算信号强度等级 (0-3)
  int _signalLevel(int rssi) {
    if (rssi >= -55) return 3;
    if (rssi >= -70) return 2;
    if (rssi >= -85) return 1;
    return 0;
  }

  /// 根据信号等级返回对应图标
  IconData _signalIcon(int level) {
    switch (level) {
      case 3:
        return Icons.signal_cellular_alt;
      case 2:
        return Icons.signal_cellular_alt_2_bar;
      case 1:
        return Icons.signal_cellular_alt_1_bar;
      default:
        return Icons.signal_cellular_0_bar;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ctrl = Get.find<BleDemoController>();
    final name = result.device.platformName.isNotEmpty
        ? result.device.platformName
        : '未知设备';
    final rssi = result.rssi;
    final signal = _signalLevel(rssi);

    return Obx(() {
      final isThisDeviceConnecting =
          ctrl.isConnecting.value &&
          ctrl.connectingDeviceId.value == result.device.remoteId.str;
      final isConnected =
          ctrl.isConnected.value &&
          ctrl.connectedDevice.value?.remoteId == result.device.remoteId;

      return Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // 蓝牙图标
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isConnected
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.bluetooth,
                  color: isConnected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              // 设备信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          _signalIcon(signal),
                          size: 14,
                          color: signal >= 2
                              ? colorScheme.onSurfaceVariant
                              : colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$rssi dBm',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // 连接按钮
              isConnected
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '已连接',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SizedBox(
                      width: 64,
                      height: 32,
                      child: FilledButton(
                        onPressed: isThisDeviceConnecting
                            ? null
                            : () => ctrl.connectDevice(result.device),
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          disabledBackgroundColor:
                              colorScheme.surfaceContainerHighest,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: isThisDeviceConnecting
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              )
                            : const Text(
                                '连接',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
            ],
          ),
        ),
      );
    });
  }
}
