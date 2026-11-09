/// Model catatan perolehan poin sosial relawan warga (tabel `social_credits`)
class SocialCredit {
  final String id;
  final String responderId;
  final String responderName;
  final String sourceType; // 'task' atau 'emergency'
  final String sourceId;
  final int points;
  final String description;
  final DateTime createdAt;

  const SocialCredit({
    required this.id,
    required this.responderId,
    required this.responderName,
    required this.sourceType,
    required this.sourceId,
    required this.points,
    required this.description,
    required this.createdAt,
  });

  factory SocialCredit.fromJson(Map<String, dynamic> json) {
    return SocialCredit(
      id: json['id'] as String,
      responderId: json['responder_id'] as String,
      responderName: json['responder_name'] as String? ?? 'Relawan',
      sourceType: json['source_type'] as String? ?? 'task',
      sourceId: json['source_id'] as String? ?? '',
      points: json['points'] as int? ?? 10,
      description: json['description'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'responder_id': responderId,
      'responder_name': responderName,
      'source_type': sourceType,
      'source_id': sourceId,
      'points': points,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Item peringkat relawan pada papan peringkat RT (Leaderboard)
class LeaderboardEntry {
  final String responderId;
  final String responderName;
  final int totalPoints;
  final int tasksCompleted;
  final int emergencyResponses;
  final int rank;

  const LeaderboardEntry({
    required this.responderId,
    required this.responderName,
    required this.totalPoints,
    required this.tasksCompleted,
    required this.emergencyResponses,
    required this.rank,
  });
}

