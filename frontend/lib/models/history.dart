class History {
  final int id;
  final int documentId;
  final int actorId;
  final String actorName;
  final String action;
  final String? comment;
  final DateTime timestamp;

  History({
    required this.id,
    required this.documentId,
    required this.actorId,
    required this.actorName,
    required this.action,
    this.comment,
    required this.timestamp,
  });

  factory History.fromJson(Map<String, dynamic> json) {
    return History(
      id: json['id'] ?? 0,
      documentId: json['document_id'] ?? 0,
      actorId: json['actor_id'] ?? 0,
      actorName: json['actor_name'] ?? 'Unknown',
      action: json['action'] ?? '',
      comment: json['comment'],
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
    );
  }

  String get actionIcon {
    switch (action.toLowerCase()) {
      case 'created':
        return '📝';
      case 'approved':
        return '✅';
      case 'rejected':
        return '❌';
      case 'delegated':
        return '👥';
      case 'expired':
        return '⏰';
      default:
        return '📋';
    }
  }
}
