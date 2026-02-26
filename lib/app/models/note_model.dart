// lib/app/models/note_model.dart

class NoteModel {
  final String id;
  final String childId;
  final String senderId;
  final String mosqueId;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  // حقول اختيارية من JOIN
  final String? childName;
  final String? senderName;

  // رد ولي الأمر (التحسين 3)
  final String? parentReply;
  final DateTime? parentRepliedAt;

  const NoteModel({
    required this.id,
    required this.childId,
    required this.senderId,
    required this.mosqueId,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.childName,
    this.senderName,
    this.parentReply,
    this.parentRepliedAt,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    // اسم الابن: من JOIN مع children أو من الحقل المباشر
    String? childName;
    final childrenData = json['children'];
    if (childrenData is Map<String, dynamic> && childrenData['name'] != null) {
      childName = childrenData['name'] as String;
    } else {
      childName = json['child_name'] as String?;
    }

    // تاريخ رد ولي الأمر
    final repliedAtRaw = json['parent_replied_at'] as String?;

    return NoteModel(
      id:              json['id'] as String,
      childId:         json['child_id'] as String,
      senderId:        json['sender_id'] as String,
      mosqueId:        json['mosque_id'] as String,
      message:         json['message'] as String,
      isRead:          json['is_read'] as bool? ?? false,
      createdAt:       DateTime.parse(json['created_at'] as String),
      childName:       childName,
      senderName:      json['sender_name'] as String?,
      parentReply:     json['parent_reply'] as String?,
      parentRepliedAt: repliedAtRaw != null ? DateTime.parse(repliedAtRaw) : null,
    );
  }

  /// هل ردّ ولي الأمر على الملاحظة؟
  bool get hasParentReply => parentReply != null && parentReply!.isNotEmpty;

  NoteModel copyWith({
    bool? isRead,
    String? parentReply,
    DateTime? parentRepliedAt,
  }) => NoteModel(
    id:              id,
    childId:         childId,
    senderId:        senderId,
    mosqueId:        mosqueId,
    message:         message,
    isRead:          isRead ?? this.isRead,
    createdAt:       createdAt,
    childName:       childName,
    senderName:      senderName,
    parentReply:     parentReply ?? this.parentReply,
    parentRepliedAt: parentRepliedAt ?? this.parentRepliedAt,
  );
}
