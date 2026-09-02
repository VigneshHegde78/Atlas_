import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

enum MemoryType { link, screenshot, pdf, note, audio }

enum SyncStatus { synced, pendingUpload, pendingDelete }

class MemoryItem {
  final String id;
  final String title;
  final String subtitle;
  final String sourceApp;
  final MemoryType type;
  final DateTime savedAt;
  final DateTime updatedAt;
  final String aiSummary;
  final String category;
  final String? url;
  final String? imagePath;
  final Uint8List? imageBytes;
  final String? snippet;
  final String content;
  final String? extractedText;
  final Map<String, dynamic>? structuredEntities;
  final List<String> tags;
  final bool isFavorite;
  final bool isArchived;
  final bool isDeleted;
  final SyncStatus syncStatus;
  final Color iconBgColor;
  final IconData iconData;

  MemoryItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.sourceApp,
    required this.type,
    required this.savedAt,
    DateTime? updatedAt,
    required this.aiSummary,
    required this.category,
    this.url,
    this.imagePath,
    this.imageBytes,
    this.snippet,
    this.content = '',
    this.extractedText,
    this.structuredEntities,
    this.tags = const [],
    this.isFavorite = false,
    this.isArchived = false,
    this.isDeleted = false,
    this.syncStatus = SyncStatus.synced,
    required this.iconBgColor,
    required this.iconData,
  }) : updatedAt = updatedAt ?? savedAt;

  MemoryItem copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? sourceApp,
    MemoryType? type,
    DateTime? savedAt,
    DateTime? updatedAt,
    String? aiSummary,
    String? category,
    String? url,
    String? imagePath,
    Uint8List? imageBytes,
    String? snippet,
    String? content,
    String? extractedText,
    Map<String, dynamic>? structuredEntities,
    List<String>? tags,
    bool? isFavorite,
    bool? isArchived,
    bool? isDeleted,
    SyncStatus? syncStatus,
    Color? iconBgColor,
    IconData? iconData,
  }) {
    return MemoryItem(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      sourceApp: sourceApp ?? this.sourceApp,
      type: type ?? this.type,
      savedAt: savedAt ?? this.savedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      aiSummary: aiSummary ?? this.aiSummary,
      category: category ?? this.category,
      url: url ?? this.url,
      imagePath: imagePath ?? this.imagePath,
      imageBytes: imageBytes ?? this.imageBytes,
      snippet: snippet ?? this.snippet,
      content: content ?? this.content,
      extractedText: extractedText ?? this.extractedText,
      structuredEntities: structuredEntities ?? this.structuredEntities,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      isArchived: isArchived ?? this.isArchived,
      isDeleted: isDeleted ?? this.isDeleted,
      syncStatus: syncStatus ?? this.syncStatus,
      iconBgColor: iconBgColor ?? this.iconBgColor,
      iconData: iconData ?? this.iconData,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'sourceApp': sourceApp,
      'type': type.name,
      'savedAt': savedAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'aiSummary': aiSummary,
      'category': category,
      'url': url,
      'imagePath': imagePath,
      'snippet': snippet,
      'content': content,
      'extractedText': extractedText,
      'structuredEntities': structuredEntities != null
          ? jsonEncode(structuredEntities)
          : null,
      'tags': jsonEncode(tags),
      'isFavorite': isFavorite ? 1 : 0,
      'isArchived': isArchived ? 1 : 0,
      'isDeleted': isDeleted ? 1 : 0,
      'syncStatus': syncStatus.name,
      'iconBgColor': iconBgColor.toARGB32(),
      'iconDataCode': iconData.codePoint,
    };
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'sourceApp': sourceApp,
      'type': type.name,
      'savedAt': savedAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'aiSummary': aiSummary,
      'category': category,
      'url': url,
      'imagePath': imagePath,
      'snippet': snippet,
      'content': content,
      'extractedText': extractedText,
      'structuredEntities': structuredEntities,
      'tags': tags,
      'isFavorite': isFavorite,
      'isArchived': isArchived,
      'isDeleted': isDeleted,
      'iconBgColor': iconBgColor.toARGB32(),
      'iconDataCode': iconData.codePoint,
    };
  }

  factory MemoryItem.fromMap(Map<String, dynamic> map) {
    List<String> parsedTags = [];
    if (map['tags'] != null) {
      if (map['tags'] is List) {
        parsedTags = List<String>.from(map['tags']);
      } else if (map['tags'] is String) {
        try {
          final decoded = jsonDecode(map['tags'] as String);
          if (decoded is List) {
            parsedTags = decoded.map((e) => e.toString()).toList();
          }
        } catch (_) {}
      }
    }

    Map<String, dynamic>? parsedEntities;
    if (map['structuredEntities'] != null) {
      if (map['structuredEntities'] is Map) {
        parsedEntities = Map<String, dynamic>.from(map['structuredEntities']);
      } else if (map['structuredEntities'] is String) {
        try {
          final decoded = jsonDecode(map['structuredEntities'] as String);
          if (decoded is Map) {
            parsedEntities = Map<String, dynamic>.from(decoded);
          }
        } catch (_) {}
      }
    }

    final type = MemoryType.values.firstWhere(
      (t) => t.name == (map['type'] ?? ''),
      orElse: () => MemoryType.note,
    );

    final syncStatus = SyncStatus.values.firstWhere(
      (s) => s.name == (map['syncStatus'] ?? ''),
      orElse: () => SyncStatus.synced,
    );

    final bool isFav = map['isFavorite'] is bool
        ? map['isFavorite']
        : (map['isFavorite'] == 1);

    final bool isArch = map['isArchived'] is bool
        ? map['isArchived']
        : (map['isArchived'] == 1);

    final bool isDel = map['isDeleted'] is bool
        ? map['isDeleted']
        : (map['isDeleted'] == 1);

    return MemoryItem(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      subtitle: map['subtitle']?.toString() ?? '',
      sourceApp: map['sourceApp']?.toString() ?? 'Atlas',
      type: type,
      savedAt:
          DateTime.tryParse(map['savedAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt:
          DateTime.tryParse(map['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
      aiSummary: map['aiSummary']?.toString() ?? '',
      category: map['category']?.toString() ?? 'Uncategorized',
      url: map['url']?.toString(),
      imagePath: map['imagePath']?.toString(),
      snippet: map['snippet']?.toString(),
      content: map['content']?.toString() ?? (map['snippet']?.toString() ?? ''),
      extractedText: map['extractedText']?.toString(),
      structuredEntities: parsedEntities,
      tags: parsedTags,
      isFavorite: isFav,
      isArchived: isArch,
      isDeleted: isDel,
      syncStatus: syncStatus,
      iconBgColor: Color(
        map['iconBgColor'] is int
            ? map['iconBgColor']
            : int.tryParse(map['iconBgColor']?.toString() ?? '') ?? 0xFFEFF6FF,
      ),
      iconData: _resolveIcon(map['iconDataCode']),
    );
  }

  static IconData _resolveIcon(dynamic codePoint) {
    final int code = codePoint is int
        ? codePoint
        : int.tryParse(codePoint?.toString() ?? '') ??
              Icons.image_rounded.codePoint;

    if (code == Icons.receipt_long_rounded.codePoint) {
      return Icons.receipt_long_rounded;
    }
    if (code == Icons.restaurant_rounded.codePoint) {
      return Icons.restaurant_rounded;
    }
    if (code == Icons.flight_takeoff_rounded.codePoint) {
      return Icons.flight_takeoff_rounded;
    }
    if (code == Icons.palette_rounded.codePoint) return Icons.palette_rounded;
    if (code == Icons.code_rounded.codePoint) return Icons.code_rounded;
    if (code == Icons.link_rounded.codePoint) return Icons.link_rounded;
    if (code == Icons.notes_rounded.codePoint) return Icons.notes_rounded;
    if (code == Icons.share_rounded.codePoint) return Icons.share_rounded;
    if (code == Icons.image_rounded.codePoint) return Icons.image_rounded;
    if (code == Icons.picture_as_pdf_rounded.codePoint) {
      return Icons.picture_as_pdf_rounded;
    }
    if (code == Icons.insert_drive_file_rounded.codePoint) {
      return Icons.insert_drive_file_rounded;
    }
    if (code == Icons.shopping_bag_rounded.codePoint) {
      return Icons.shopping_bag_rounded;
    }
    return Icons.notes_rounded;
  }
}

class GlobeMemoryNode {
  final MemoryItem memory;
  final double lat;
  final double lng;
  final Color color;

  GlobeMemoryNode({
    required this.memory,
    required this.lat,
    required this.lng,
    required this.color,
  });
}
