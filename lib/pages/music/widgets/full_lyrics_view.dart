import 'package:flutter/material.dart';
import '../music_models.dart';

/// 完整歌词视图（歌词 Tab）
class FullLyricsView extends StatelessWidget {
  final List<LyricLine> lyrics;
  final int currentLyricIndex;
  final ScrollController scrollController;
  final ValueChanged<Duration> onSeek;
  final double lineHeight;

  const FullLyricsView({
    super.key,
    required this.lyrics,
    required this.currentLyricIndex,
    required this.scrollController,
    required this.onSeek,
    this.lineHeight = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    if (lyrics.isEmpty) {
      return const Center(
        child: Text(
          '暂无歌词',
          style: TextStyle(color: Colors.white38, fontSize: 14),
        ),
      );
    }

    final paddingTop = MediaQuery.of(context).size.height / 3;

    return ListView.builder(
      controller: scrollController,
      padding: EdgeInsets.symmetric(
        vertical: paddingTop,
        horizontal: 32,
      ),
      itemCount: lyrics.length,
      itemBuilder: (context, index) {
        final line = lyrics[index];
        return GestureDetector(
          onTap: () => onSeek(line.timestamp),
          child: Container(
            height: lineHeight,
            alignment: Alignment.center,
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                fontSize: currentLyricIndex == index ? 17 : 14,
                fontWeight: currentLyricIndex == index
                    ? FontWeight.w600
                    : FontWeight.w400,
                color: currentLyricIndex == index
                    ? Colors.white
                    : Colors.white38,
                height: 1.5,
              ),
              child: Text(
                line.text,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        );
      },
    );
  }
}
