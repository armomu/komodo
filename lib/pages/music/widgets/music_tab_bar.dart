import 'package:flutter/material.dart';

/// 歌曲/歌词 Tab 指示器
class MusicTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabChanged;

  static const _titles = ['歌曲', '歌词'];

  const MusicTabBar({
    super.key,
    required this.currentIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: _titles.asMap().entries.map((e) {
        final active = e.key == currentIndex;
        return GestureDetector(
          onTap: () => onTabChanged(e.key),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  e.value,
                  style: TextStyle(
                    color: active ? Colors.white : Colors.white60,
                    fontSize: active ? 16 : 15,
                    fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  width: 20,
                  height: 2,
                  color: active ? Colors.white : Colors.transparent,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
