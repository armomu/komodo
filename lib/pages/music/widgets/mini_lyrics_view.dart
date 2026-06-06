import 'package:flutter/material.dart';
import '../music_models.dart';

/// Mini 歌词展示（歌曲 Tab 下方，3 行可见，当前行居中高亮）
class MiniLyricsView extends StatelessWidget {
  final List<LyricLine> lyrics;
  final int currentLyricIndex;
  final ScrollController scrollController;
  final double lineHeight;
  final double visibleHeight;

  const MiniLyricsView({
    super.key,
    required this.lyrics,
    required this.currentLyricIndex,
    required this.scrollController,
    this.lineHeight = 32.0,
    this.visibleHeight = 94.0,
  });

  @override
  Widget build(BuildContext context) {
    if (lyrics.isEmpty) {
      return SizedBox(
        width: double.infinity,
        height: visibleHeight,
        child: const Center(
          child: Text(
            '暂无歌词',
            style: TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return SizedBox(
      height: visibleHeight,
      child: ShaderMask(
        shaderCallback: (bounds) {
          return const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.white,
              Colors.white,
              Colors.transparent,
            ],
            stops: [0.0, 0.25, 0.75, 1.0],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: ListView.builder(
          controller: scrollController,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(vertical: lineHeight),
          itemCount: lyrics.length,
          itemExtent: lineHeight,
          itemBuilder: (context, index) {
            final isCurrent = index == currentLyricIndex;
            return Center(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  fontSize: isCurrent ? 16 : 14,
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                  color: isCurrent ? Colors.white : Colors.white38,
                ),
                child: Text(
                  lyrics[index].text,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
