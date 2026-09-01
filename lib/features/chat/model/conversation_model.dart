class ConversationModel {
  final int matchId;
  final int otherUserId;
  final String otherUserName;
  final double matchScore;
  final String? lastMessage;
  final String? lastMessageAt;

  const ConversationModel({
    required this.matchId,
    required this.otherUserId,
    required this.otherUserName,
    required this.matchScore,
    this.lastMessage,
    this.lastMessageAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) =>
      ConversationModel(
        matchId: json['matchId'] as int,
        otherUserId: json['otherUserId'] as int,
        otherUserName: json['otherUserName'] as String,
        matchScore: (json['matchScore'] as num?)?.toDouble() ?? 0.0,
        lastMessage: json['lastMessage'] as String?,
        lastMessageAt: json['lastMessageAt'] as String?,
      );
}
