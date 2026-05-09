enum ChatMsgType { timestamp, text, voice, image, gift }

class ChatMessage {
  final ChatMsgType type;
  final bool isMe;
  final String? content;
  final String? imageUrl;
  final bool isLocalImage;
  final int? duration;
  final String? voicePath;
  final String? giftEmoji;
  final String? giftLabel;
  final String? time;

  const ChatMessage({
    required this.type,
    this.isMe = false,
    this.content,
    this.imageUrl,
    this.isLocalImage = false,
    this.duration,
    this.voicePath,
    this.giftEmoji,
    this.giftLabel,
    this.time,
  });
}

enum ChatRecordState { idle, ready, recording, preview }
