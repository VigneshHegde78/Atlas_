import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/collection_item.dart';
import '../models/memory_item.dart';
import '../providers/memory_provider.dart';
import 'local_database_service.dart';

class BackupService {
  static final BackupService instance = BackupService._internal();
  BackupService._internal();

  /// Creates a formatted .atlasbackup JSON bundle.
  String createAtlasBackup({
    required List<MemoryItem> memories,
    required List<MemoryCollection> collections,
  }) {
    final payload = {
      'format': 'ATLAS_BACKUP_BUNDLE',
      'version': 3,
      'createdAt': DateTime.now().toIso8601String(),
      'checksum': _generateChecksum(memories, collections),
      'data': {
        'memories': memories.map((m) => m.toMap()).toList(),
        'collections': collections.map((c) => c.toMap()).toList(),
      },
    };
    return jsonEncode(payload);
  }

  /// Restores memories and collections from a backup string.
  Future<bool> restoreAtlasBackup(String backupJson, MemoryProvider provider) async {
    try {
      final decoded = jsonDecode(backupJson) as Map<String, dynamic>;
      final data = decoded['data'] as Map<String, dynamic>?;

      if (data == null) return false;

      final db = LocalDatabaseService.instance;

      // Restore Memories
      if (data['memories'] is List) {
        final rawMemories = data['memories'] as List;
        for (final m in rawMemories) {
          if (m is Map<String, dynamic>) {
            final item = MemoryItem.fromMap(m);
            await db.insertMemory(item);
          }
        }
      }

      // Restore Collections
      if (data['collections'] is List) {
        final rawCollections = data['collections'] as List;
        for (final c in rawCollections) {
          if (c is Map<String, dynamic>) {
            final col = MemoryCollection.fromMap(c);
            await db.insertCollection(col);
          }
        }
      }

      await provider.reloadMemoriesFromDb();
      return true;
    } catch (e) {
      debugPrint('Error restoring backup: $e');
      return false;
    }
  }

  int _generateChecksum(List<MemoryItem> memories, List<MemoryCollection> collections) {
    int sum = 0;
    for (final m in memories) {
      sum = (sum + m.id.hashCode + m.title.hashCode) % 1000000007;
    }
    for (final c in collections) {
      sum = (sum + c.id.hashCode + c.title.hashCode) % 1000000007;
    }
    return sum;
  }
}
