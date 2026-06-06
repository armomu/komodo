import 'package:flutter/material.dart';

/// 底部播放控制栏（上一首/播放暂停/下一首/播放列表）
class MusicPlaybackControls extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onTogglePlay;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPlaylist;

  const MusicPlaybackControls({
    super.key,
    required this.isPlaying,
    required this.onTogglePlay,
    required this.onPrevious,
    required this.onNext,
    required this.onPlaylist,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: bottomPadding > 0 ? bottomPadding + 8 : 28,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 播放模式
          const IconButton(
            onPressed: null,
            icon: Icon(Icons.repeat_rounded),
            color: Colors.white54,
            iconSize: 22,
          ),
          // 上一首
          IconButton(
            onPressed: onPrevious,
            icon: const Icon(Icons.skip_previous_rounded),
            color: Colors.white,
            iconSize: 32,
          ),
          // 播放/暂停
          GestureDetector(
            onTap: onTogglePlay,
            child: Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white10,
              ),
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
          ),
          // 下一首
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.skip_next_rounded),
            color: Colors.white,
            iconSize: 32,
          ),
          // 播放列表
          IconButton(
            onPressed: onPlaylist,
            icon: const Icon(Icons.queue_music_rounded),
            color: Colors.white54,
            iconSize: 24,
          ),
        ],
      ),
    );
  }
}
