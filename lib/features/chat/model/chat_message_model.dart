class ChatMessageModel {
  final int? id;
  final int matchId;
  final int senderId;
  final String? senderName;
  final String content;
  final String messageType;
  final String? sentAt;

  const ChatMessageModel({
    this.id,
    required this.matchId,
    required this.senderId,
    this.senderName,
    required this.content,
    this.messageType = 'TEXT',
    this.sentAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) =>
      ChatMessageModel(
        id: json['id'] as int?,
        matchId: json['matchId'] as int,
        senderId: json['senderId'] as int,
        senderName: json['senderName'] as String?,
        content: json['content'] as String,
        messageType: json['messageType'] as String? ?? 'TEXT',
        sentAt: json['sentAt'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'content': content,
        'messageType': messageType,
        'sentAt': sentAt ?? DateTime.now().toIso8601String(),
      };
}
