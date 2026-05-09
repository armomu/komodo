import 'package:flutter/material.dart';
import 'package:komodo/pages/message/emojis.dart';

/// 表情选择面板
class EmojiPickerWidget extends StatelessWidget {
  final double height;
  final ValueChanged<String> onEmojiSelected;

  const EmojiPickerWidget({
    super.key,
    this.height = 260.0,
    required this.onEmojiSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        border:
            Border(top: BorderSide(color: colorScheme.outline, width: 1)),
      ),
      child: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: EmojiList.length,
              itemBuilder: (context, index) => GestureDetector(
                onTap: () => onEmojiSelected(EmojiList[index]),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: colorScheme.surface,
                  ),
                  alignment: Alignment.center,
                  child: Text(EmojiList[index],
                      style: const TextStyle(fontSize: 24)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
