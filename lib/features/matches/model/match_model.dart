class MatchModel {
  final int id;
  final int user1Id;
  final int user2Id;

  /// The participant who is *not* the caller. The backend resolves this against
  /// the authenticated user, so it is already correct from the caller's point of
  /// view - prefer it over deriving the id locally.
  final int? otherUserIdFromApi;
  final String? otherUserName;
  final String? otherUserImage;

  final double matchScore;
  final String status;
  final String? matchedAt;
  final String? lastInteraction;

  const MatchModel({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    this.otherUserIdFromApi,
    this.otherUserName,
    this.otherUserImage,
    required this.matchScore,
    required this.status,
    this.matchedAt,
    this.lastInteraction,
  });

  bool isPending() => status == 'PENDING';
  bool isAccepted() => status == 'ACCEPTED';
  bool isRejected() => status == 'REJECTED';

  int otherUserId(int currentUserId) =>
      otherUserIdFromApi ?? (user1Id == currentUserId ? user2Id : user1Id);

  /// What to render as the person's name. Falls back to a neutral placeholder
  /// rather than "User #12" - an internal row id is not a name, and showing one
  /// reads as broken even when the data is fine.
  String get displayName {
    final name = otherUserName?.trim();
    return (name == null || name.isEmpty) ? 'RoomMate Finder user' : name;
  }

  /// First letter for the avatar circle, or '?' when there is no usable name.
  String get initial {
    final name = otherUserName?.trim();
    return (name == null || name.isEmpty) ? '?' : name[0].toUpperCase();
  }

  factory MatchModel.fromJson(Map<String, dynamic> json) => MatchModel(
        id: json['id'] as int,
        user1Id: json['user1Id'] as int,
        user2Id: json['user2Id'] as int,
        otherUserIdFromApi: (json['otherUserId'] as num?)?.toInt(),
        otherUserName: json['otherUserName'] as String?,
        otherUserImage: json['otherUserImage'] as String?,
        matchScore: (json['matchScore'] as num?)?.toDouble() ?? 0.0,
        status: json['status'] as String,
        matchedAt: json['matchedAt'] as String?,
        lastInteraction: json['lastInteraction'] as String?,
      );
}
