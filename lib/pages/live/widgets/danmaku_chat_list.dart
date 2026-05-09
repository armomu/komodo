import 'package:flutter/material.dart';
import '../models/danmaku_item.dart';

/// 左下角聊天弹幕列表
class DanmakuChatList extends StatelessWidget {
  final List<DanmakuItem> danmakuList;
  final ScrollController scrollController;

  const DanmakuChatList({
    super.key,
    required this.danmakuList,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.80;
    return Positioned(
      left: 8,
      bottom: 82,
      child: SizedBox(
        width: maxWidth,
        height: 200,
        child: ListView.builder(
          controller: scrollController,
          itemCount: danmakuList.length,
          itemBuilder: (context, index) {
            final item = danmakuList[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.only(
                          left: 8,
                          right: 8,
                          top: 4,
                          bottom: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: RichText(
                          text: TextSpan(children: [
                            TextSpan(
                              text: '${item.username}：',
                              style: TextStyle(
                                color: item.color,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(
                              text: item.content,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                            ),
                          ]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
