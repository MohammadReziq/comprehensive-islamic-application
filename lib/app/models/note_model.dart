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
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id:         json['id'] as String,
      childId:    json['child_id'] as String,
      senderId:   json['sender_id'] as String,
      mosqueId:   json['mosque_id'] as String,
      message:    json['message'] as String,
      isRead:     json['is_read'] as bool? ?? false,
      createdAt:  DateTime.parse(json['created_at'] as String),
      childName:  json['child_name'] as String?,
      senderName: json['sender_name'] as String?,
    );
  }

  NoteModel copyWith({bool? isRead}) => NoteModel(
    id:         id,
    childId:    childId,
    senderId:   senderId,
    mosqueId:   mosqueId,
    message:    message,
    isRead:     isRead ?? this.isRead,
    createdAt:  createdAt,
    childName:  childName,
    senderName: senderName,
  );
}
