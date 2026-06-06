import 'package:flutter/material.dart';
import 'package:komodo/components/app_bottom_sheet.dart';
import 'comment_data.dart';

void showCommentBottomSheet({
  required BuildContext context,
  required int commentCount,
}) {
  final comments = [
    const CommentItem(
      username: '@观众小明',
      avatar: Icons.person,
      content: '这个视频拍得真好！',
      time: '3分钟前',
      likes: 128,
    ),
    const CommentItem(
      username: '@旅行者',
      avatar: Icons.person,
      content: '收藏了，下次去这里打卡 📍',
      time: '15分钟前',
      likes: 56,
    ),
    const CommentItem(
      username: '@摄影师小王',
      avatar: Icons.person,
      content: '运镜很稳，用的什么稳定器？',
      time: '1小时前',
      likes: 42,
    ),
    const CommentItem(
      username: '@美食家',
      avatar: Icons.person,
      content: '旁边那家餐厅也超好吃！推荐大家去试试',
      time: '2小时前',
      likes: 89,
    ),
    const CommentItem(
      username: '@户外达人',
      avatar: Icons.person,
      content: '这个地方我去过，风景确实绝了',
      time: '3小时前',
      likes: 37,
    ),
  ];

  AppBottomSheet.show(
    child: SizedBox(
      height: 400,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$commentCount 条评论',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: comments.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, indent: 72),
              itemBuilder: (context, index) =>
                  CommentItemWidget(comment: comments[index]),
            ),
          ),
          const Divider(height: 1),
          const _CommentInput(),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// 评论列表行
// ─────────────────────────────────────────────────────────────────────────────

class CommentItemWidget extends StatelessWidget {
  final CommentItem comment;

  const CommentItemWidget({super.key, required this.comment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 18, child: Icon(comment.avatar, size: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment.username,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(comment.content, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      comment.time,
                      style:
                          const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(width: 16),
                    const Text('回复', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              const Icon(Icons.favorite_border, size: 16),
              const SizedBox(height: 2),
              Text(
                '${comment.likes}',
                style: const TextStyle(fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 评论输入框
// ─────────────────────────────────────────────────────────────────────────────

class _CommentInput extends StatefulWidget {
  const _CommentInput();

  @override
  State<_CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<_CommentInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 36,
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: '说点什么...',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                    border: InputBorder.none,
                    fillColor: Colors.transparent,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.image),
              onPressed: () {},
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            IconButton(
              icon: const Icon(Icons.alternate_email),
              onPressed: () {},
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            IconButton(
              icon: const Icon(Icons.mood),
              onPressed: () {},
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}
