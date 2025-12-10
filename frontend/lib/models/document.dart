class Document {
  final int id;
  final String title;
  final String description;
  final String filePath;
  final int priority;
  final String status;
  final String? rejectionReason;
  final DateTime? deadline;
  final int creatorId;
  final int? assignedToId;
  final String? creatorName;
  final String? assignedToName;
  final DateTime createdAt;
  final DateTime updatedAt;

  Document({
    required this.id,
    required this.title,
    required this.description,
    required this.filePath,
    required this.priority,
    required this.status,
    this.rejectionReason,
    this.deadline,
    required this.creatorId,
    this.assignedToId,
    this.creatorName,
    this.assignedToName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      filePath: json['file_path'] ?? '',
      priority: json['priority'] ?? 1,
      status: json['status'] ?? 'pending',
      rejectionReason: json['rejection_reason'],
      deadline: json['deadline'] != null 
          ? DateTime.parse(json['deadline']) 
          : null,
      creatorId: json['creator_id'] ?? 0,
      assignedToId: json['assigned_to_id'],
      creatorName: json['creator_name'],
      assignedToName: json['assigned_to_name'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'file_path': filePath,
      'priority': priority,
      'status': status,
      'rejection_reason': rejectionReason,
      'deadline': deadline?.toIso8601String(),
      'creator_id': creatorId,
      'assigned_to_id': assignedToId,
      'creator_name': creatorName,
      'assigned_to_name': assignedToName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get hasFile => filePath.isNotEmpty;
  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isExpired => status == 'expired';

  String get priorityLabel {
    switch (priority) {
      case 3:
        return 'High';
      case 2:
        return 'Medium';
      default:
        return 'Low';
    }
  }

  String get statusLabel {
    switch (status) {
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'expired':
        return 'Expired';
      default:
        return 'Pending';
    }
  }
}
