import 'dart:convert';
import 'package:flutter/material.dart';

class MemoryCollection {
  final String id;
  final String title;
  final String description;
  final Color color;
  final IconData icon;
  final List<String> itemIds;
  final DateTime createdAt;
  final bool isSmart;
  final String? smartRule;

  MemoryCollection({
    required this.id,
    required this.title,
    required this.description,
    required this.color,
    required this.icon,
    this.itemIds = const [],
    required this.createdAt,
    this.isSmart = false,
    this.smartRule,
  });

  MemoryCollection copyWith({
    String? id,
    String? title,
    String? description,
    Color? color,
    IconData? icon,
    List<String>? itemIds,
    DateTime? createdAt,
    bool? isSmart,
    String? smartRule,
  }) {
    return MemoryCollection(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      itemIds: itemIds ?? this.itemIds,
      createdAt: createdAt ?? this.createdAt,
      isSmart: isSmart ?? this.isSmart,
      smartRule: smartRule ?? this.smartRule,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'colorCode': color.toARGB32(),
      'iconCode': icon.codePoint,
      'itemIds': jsonEncode(itemIds),
      'createdAt': createdAt.toIso8601String(),
      'isSmart': isSmart ? 1 : 0,
      'smartRule': smartRule,
    };
  }

  factory MemoryCollection.fromMap(Map<String, dynamic> map) {
    List<String> parsedItemIds = [];
    if (map['itemIds'] != null) {
      if (map['itemIds'] is List) {
        parsedItemIds = List<String>.from(map['itemIds']);
      } else if (map['itemIds'] is String) {
        try {
          final decoded = jsonDecode(map['itemIds'] as String);
          if (decoded is List) {
            parsedItemIds = decoded.map((e) => e.toString()).toList();
          }
        } catch (_) {}
      }
    }

    return MemoryCollection(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      color: map['colorCode'] != null
          ? Color(map['colorCode'] as int)
          : const Color(0xFF0F172A),
      icon: _resolveIcon(map['iconCode']),
      itemIds: parsedItemIds,
      createdAt:
          DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      isSmart: map['isSmart'] is bool ? map['isSmart'] : (map['isSmart'] == 1),
      smartRule: map['smartRule']?.toString(),
    );
  }

  static IconData _resolveIcon(dynamic codePoint) {
    final int code = codePoint is int
        ? codePoint
        : int.tryParse(codePoint?.toString() ?? '') ??
              Icons.folder_rounded.codePoint;

    if (code == Icons.folder_rounded.codePoint) {
      return Icons.folder_rounded;
    }
    if (code == Icons.flight_takeoff_rounded.codePoint) {
      return Icons.flight_takeoff_rounded;
    }
    if (code == Icons.lightbulb_rounded.codePoint) {
      return Icons.lightbulb_rounded;
    }
    if (code == Icons.work_rounded.codePoint) {
      return Icons.work_rounded;
    }
    if (code == Icons.home_work_rounded.codePoint) {
      return Icons.home_work_rounded;
    }
    if (code == Icons.receipt_long_rounded.codePoint) {
      return Icons.receipt_long_rounded;
    }
    if (code == Icons.mic_rounded.codePoint) {
      return Icons.mic_rounded;
    }
    if (code == Icons.restaurant_menu_rounded.codePoint) {
      return Icons.restaurant_menu_rounded;
    }
    if (code == Icons.bookmark_rounded.codePoint) {
      return Icons.bookmark_rounded;
    }
    if (code == Icons.code_rounded.codePoint) {
      return Icons.code_rounded;
    }
    return Icons.folder_rounded;
  }
}
