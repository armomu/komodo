import 'package:flutter/material.dart';

/// 被叫方来电接听界面
///
/// 在被叫方进入 [VideoCallPage] 时全屏展示，让用户手动选择接听或拒绝。
/// 接听后，页面调用 [VideoCallController.startAsCallee] 开始建连。
///
/// 参数：
///   - [peerName]  对方昵称
///   - [onAccept]  用户点击"接听"时的回调
///   - [onReject]  用户点击"拒绝"时的回调
class IncomingCallOverlay extends StatefulWidget {
  final String peerName;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const IncomingCallOverlay({
    super.key,
    required this.peerName,
    required this.onAccept,
    required this.onReject,
  });

  @override
  State<IncomingCallOverlay> createState() => _IncomingCallOverlayState();
}

class _IncomingCallOverlayState extends State<IncomingCallOverlay>
    with SingleTickerProviderStateMixin {
  // 铃声动画：视频图标脉冲缩放
  late final AnimationController _animCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _scaleAnim = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      // 毛玻璃渐变背景
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),

            // ── 对方头像 + 脉冲动画 ──
            ScaleTransition(
              scale: _scaleAnim,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white12,
                  border: Border.all(color: Colors.white30, width: 2),
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white54,
                  size: 52,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── 对方昵称 ──
            Text(
              widget.peerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),

            const SizedBox(height: 8),

            // ── 来电描述 ──
            const Text(
              '视频通话邀请',
              style: TextStyle(color: Colors.white60, fontSize: 15),
            ),

            // ── 信号波动点 ──
            const SizedBox(height: 16),
            _RippleDots(),

            const Spacer(flex: 3),

            // ── 操作按钮 ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 拒绝
                  _CallButton(
                    icon: Icons.call_end,
                    label: '拒绝',
                    color: const Color(0xFFE53935),
                    onTap: widget.onReject,
                  ),
                  // 接听
                  _CallButton(
                    icon: Icons.videocam,
                    label: '接听',
                    color: const Color(0xFF43A047),
                    onTap: widget.onAccept,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 内部：接听/拒绝按钮
// ─────────────────────────────────────────────
class _CallButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _CallButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 内部：三个跳动圆点，模拟信号动态
// ─────────────────────────────────────────────
class _RippleDots extends StatefulWidget {
  @override
  State<_RippleDots> createState() => _RippleDotsState();
}

class _RippleDotsState extends State<_RippleDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = (_ctrl.value - i * 0.2).clamp(0.0, 1.0);
            final opacity = (0.3 + 0.7 * (t < 0.5 ? t * 2 : (1 - t) * 2))
                .clamp(0.2, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Opacity(
                opacity: opacity,
                child: const CircleAvatar(
                  radius: 4,
                  backgroundColor: Colors.white54,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
