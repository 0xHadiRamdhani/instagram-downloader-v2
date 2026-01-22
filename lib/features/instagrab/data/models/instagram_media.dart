import 'package:instagram_downloader/core/constants.dart';

/// Model class for parsed Instagram media content
class InstagramMedia {
  final String originalUrl;
  final String? videoUrl;
  final String? imageUrl;
  final String? title;
  final MediaType type;
  final DateTime fetchedAt;
  final String? filename;

  InstagramMedia({
    required this.originalUrl,
    this.videoUrl,
    this.imageUrl,
    this.title,
    required this.type,
    DateTime? fetchedAt,
    this.filename,
  }) : fetchedAt = fetchedAt ?? DateTime.now();

  String? get mediaUrl => videoUrl ?? imageUrl;
  bool get hasMedia => mediaUrl != null;
  bool get isVideo => videoUrl != null && videoUrl!.isNotEmpty;
  String get fileExtension => isVideo ? 'mp4' : 'jpg';

  String get generatedFilename {
    if (filename != null) return filename!;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final prefix = isVideo ? 'video' : 'image';
    return 'instagrab_${prefix}_$timestamp.$fileExtension';
  }

  factory InstagramMedia.fromJson(Map<String, dynamic> json) {
    return InstagramMedia(
      originalUrl: json['originalUrl'] as String,
      videoUrl: json['videoUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
      title: json['title'] as String?,
      type: MediaType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MediaType.unknown,
      ),
      fetchedAt:
          DateTime.tryParse(json['fetchedAt'] as String? ?? '') ??
          DateTime.now(),
      filename: json['filename'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'originalUrl': originalUrl,
    'videoUrl': videoUrl,
    'imageUrl': imageUrl,
    'title': title,
    'type': type.name,
    'fetchedAt': fetchedAt.toIso8601String(),
    'filename': filename,
  };

  InstagramMedia copyWith({String? filename}) => InstagramMedia(
    originalUrl: originalUrl,
    videoUrl: videoUrl,
    imageUrl: imageUrl,
    title: title,
    type: type,
    fetchedAt: fetchedAt,
    filename: filename ?? this.filename,
  );
}

/// Download history item
class DownloadHistoryItem {
  final InstagramMedia media;
  final String localPath;
  final DateTime downloadedAt;
  final int? fileSize;

  DownloadHistoryItem({
    required this.media,
    required this.localPath,
    DateTime? downloadedAt,
    this.fileSize,
  }) : downloadedAt = downloadedAt ?? DateTime.now();

  factory DownloadHistoryItem.fromJson(Map<String, dynamic> json) {
    return DownloadHistoryItem(
      media: InstagramMedia.fromJson(json['media'] as Map<String, dynamic>),
      localPath: json['localPath'] as String,
      downloadedAt:
          DateTime.tryParse(json['downloadedAt'] as String? ?? '') ??
          DateTime.now(),
      fileSize: json['fileSize'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'media': media.toJson(),
    'localPath': localPath,
    'downloadedAt': downloadedAt.toIso8601String(),
    'fileSize': fileSize,
  };

  String get fileSizeDisplay {
    if (fileSize == null) return 'Unknown';
    if (fileSize! < 1024) return '$fileSize B';
    if (fileSize! < 1024 * 1024)
      return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get downloadDateDisplay {
    final diff = DateTime.now().difference(downloadedAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${downloadedAt.day}/${downloadedAt.month}/${downloadedAt.year}';
  }
}
