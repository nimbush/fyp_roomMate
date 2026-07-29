class MatchModel {
  final int id;
  final int user1Id;
  final int user2Id;
  final double matchScore;
  final String status;
  final String? matchedAt;
  final String? lastInteraction;

  const MatchModel({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.matchScore,
    required this.status,
    this.matchedAt,
    this.lastInteraction,
  });

  bool isPending() => status == 'PENDING';
  bool isAccepted() => status == 'ACCEPTED';
  bool isRejected() => status == 'REJECTED';

  int otherUserId(int currentUserId) =>
      user1Id == currentUserId ? user2Id : user1Id;

  factory MatchModel.fromJson(Map<String, dynamic> json) => MatchModel(
        id: json['id'] as int,
        user1Id: json['user1Id'] as int,
        user2Id: json['user2Id'] as int,
        matchScore: (json['matchScore'] as num?)?.toDouble() ?? 0.0,
        status: json['status'] as String,
        matchedAt: json['matchedAt'] as String?,
        lastInteraction: json['lastInteraction'] as String?,
      );
}
