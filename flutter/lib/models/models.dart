import 'dart:convert';

// ─── User Model ──────────────────────────────────────────────────────────────
class UserModel {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? avatarUrl;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
    this.createdAt,
  });

  bool get isAdmin => role == 'admin';

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id:        json['id'] as int,
    name:      json['name'] as String,
    email:     json['email'] as String,
    role:      json['role'] as String,
    avatarUrl: json['avatar_url'] as String?,
    createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'email': email, 'role': role,
    'avatar_url': avatarUrl, 'created_at': createdAt?.toIso8601String(),
  };

  String toJsonString() => jsonEncode(toJson());
  factory UserModel.fromJsonString(String s) => UserModel.fromJson(jsonDecode(s));
}

// ─── Media Metadata Model ────────────────────────────────────────────────────
class MediaMetadata {
  final String? eventName;
  final String? location;
  final String? description;
  final String? participants;
  final String? speakerName;
  final String? sermonTopic;
  final String? serviceDate;

  const MediaMetadata({
    this.eventName,
    this.location,
    this.description,
    this.participants,
    this.speakerName,
    this.sermonTopic,
    this.serviceDate,
  });

  factory MediaMetadata.fromJson(Map<String, dynamic> json) => MediaMetadata(
    eventName:    json['event_name'] as String?,
    location:     json['location'] as String?,
    description:  json['description'] as String?,
    participants: json['participants'] as String?,
    speakerName:  json['speaker_name'] as String?,
    sermonTopic:  json['sermon_topic'] as String?,
    serviceDate:  json['service_date'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'event_name': eventName, 'location': location, 'description': description,
    'participants': participants, 'speaker_name': speakerName,
    'sermon_topic': sermonTopic, 'service_date': serviceDate,
  };
}

// ─── Media Model ─────────────────────────────────────────────────────────────
class MediaModel {
  final int id;
  final String type;          // 'video' | 'photo' | 'audio'
  final String? title;
  final String? filePath;     // Local path (before upload)
  final String? thumbnailUrl;
  final String status;
  final String? uploadedByName;
  final DateTime createdAt;
  final MediaMetadata? metadata;
  final String? youtubeLink;
  final String? youtubeVideoId;
  final String? telegramMsgId;

  const MediaModel({
    required this.id,
    required this.type,
    this.title,
    this.filePath,
    this.thumbnailUrl,
    required this.status,
    this.uploadedByName,
    required this.createdAt,
    this.metadata,
    this.youtubeLink,
    this.youtubeVideoId,
    this.telegramMsgId,
  });

  bool get isVideo  => type == 'video';
  bool get isPhoto  => type == 'photo';
  bool get isAudio  => type == 'audio';
  bool get isUploaded  => status == 'uploaded';
  bool get isPending   => status == 'pending';
  bool get isUploading => status == 'uploading';
  bool get isFailed    => status == 'failed';

  String get displayTitle {
    if (title != null && title!.isNotEmpty) return title!;
    if (metadata?.eventName != null) return metadata!.eventName!;
    return 'Church Media';
  }

  factory MediaModel.fromJson(Map<String, dynamic> json) => MediaModel(
    id:             json['id'] as int,
    type:           json['type'] as String,
    title:          json['title'] as String?,
    filePath:       json['file_path'] as String?,
    thumbnailUrl:   json['thumbnail_url'] as String?,
    status:         json['status'] as String? ?? 'pending',
    uploadedByName: json['uploaded_by_name'] as String?,
    createdAt:      json['created_at'] != null
                    ? DateTime.parse(json['created_at'])
                    : DateTime.now(),
    metadata:       MediaMetadata.fromJson(json),
    youtubeLink:    json['youtube_link'] as String?,
    youtubeVideoId: json['youtube_video_id'] as String?,
    telegramMsgId:  json['telegram_msg_id'] as String?,
  );
}

// ─── Upload Model ─────────────────────────────────────────────────────────────
class UploadModel {
  final int id;
  final int mediaId;
  final String platform;
  final String uploadStatus;
  final String? telegramMsgId;
  final String? youtubeLink;
  final int retryCount;
  final String? errorMessage;
  final DateTime? uploadDate;
  // joined fields
  final String? mediaType;
  final String? mediaTitle;
  final String? eventName;

  const UploadModel({
    required this.id,
    required this.mediaId,
    required this.platform,
    required this.uploadStatus,
    this.telegramMsgId,
    this.youtubeLink,
    required this.retryCount,
    this.errorMessage,
    this.uploadDate,
    this.mediaType,
    this.mediaTitle,
    this.eventName,
  });

  factory UploadModel.fromJson(Map<String, dynamic> json) => UploadModel(
    id:            json['id'] as int,
    mediaId:       json['media_id'] as int,
    platform:      json['platform'] as String,
    uploadStatus:  json['upload_status'] as String,
    telegramMsgId: json['telegram_msg_id'] as String?,
    youtubeLink:   json['youtube_link'] as String?,
    retryCount:    json['retry_count'] as int? ?? 0,
    errorMessage:  json['error_message'] as String?,
    uploadDate:    json['upload_date'] != null ? DateTime.tryParse(json['upload_date']) : null,
    mediaType:     json['type'] as String?,
    mediaTitle:    json['title'] as String?,
    eventName:     json['event_name'] as String?,
  );
}

// ─── Pending Upload (local queue) ─────────────────────────────────────────────
class PendingUpload {
  final String localId;
  final String type;
  final String filePath;
  final MediaMetadata metadata;
  String status;
  double progress;
  String? error;

  PendingUpload({
    required this.localId,
    required this.type,
    required this.filePath,
    required this.metadata,
    this.status = 'pending',
    this.progress = 0.0,
    this.error,
  });
}
