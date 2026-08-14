import 'dart:typed_data';
import 'package:flutter/material.dart';

enum MemoryType {
  link,
  screenshot,
  pdf,
  note,
}

class MemoryItem {
  final String id;
  final String title;
  final String subtitle;
  final String sourceApp;
  final MemoryType type;
  final DateTime savedAt;
  final String aiSummary;
  final String category;
  final String? url;
  final String? imagePath;
  final Uint8List? imageBytes;
  final String? snippet;
  final Color iconBgColor;
  final IconData iconData;

  MemoryItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.sourceApp,
    required this.type,
    required this.savedAt,
    required this.aiSummary,
    required this.category,
    this.url,
    this.imagePath,
    this.imageBytes,
    this.snippet,
    required this.iconBgColor,
    required this.iconData,
  });
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
