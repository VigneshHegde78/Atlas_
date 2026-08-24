import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/memory_item.dart';

class LocalDatabaseService {
  static final LocalDatabaseService instance = LocalDatabaseService._internal();
  LocalDatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'atlas_memory.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE memories (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            subtitle TEXT NOT NULL,
            sourceApp TEXT NOT NULL,
            type TEXT NOT NULL,
            savedAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL,
            aiSummary TEXT NOT NULL,
            category TEXT NOT NULL,
            url TEXT,
            imagePath TEXT,
            snippet TEXT,
            content TEXT,
            tags TEXT,
            isFavorite INTEGER NOT NULL DEFAULT 0,
            isArchived INTEGER NOT NULL DEFAULT 0,
            isDeleted INTEGER NOT NULL DEFAULT 0,
            syncStatus TEXT NOT NULL DEFAULT 'synced',
            iconBgColor INTEGER NOT NULL,
            iconDataCode INTEGER NOT NULL
          )
        ''');

        await db.execute('CREATE INDEX idx_memories_category ON memories(category)');
        await db.execute('CREATE INDEX idx_memories_isDeleted ON memories(isDeleted)');
        await db.execute('CREATE INDEX idx_memories_isFavorite ON memories(isFavorite)');
        await db.execute('CREATE INDEX idx_memories_isArchived ON memories(isArchived)');
        await db.execute('CREATE INDEX idx_memories_syncStatus ON memories(syncStatus)');
        await db.execute('CREATE INDEX idx_memories_updatedAt ON memories(updatedAt DESC)');
      },
    );
  }

  Future<void> insertMemory(MemoryItem item) async {
    final db = await database;
    await db.insert(
      'memories',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateMemory(MemoryItem item) async {
    final db = await database;
    final updated = item.copyWith(
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pendingUpload,
    );
    await db.update(
      'memories',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> softDeleteMemory(String id) async {
    final db = await database;
    await db.update(
      'memories',
      {
        'isDeleted': 1,
        'updatedAt': DateTime.now().toIso8601String(),
        'syncStatus': SyncStatus.pendingDelete.name,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> restoreMemory(String id) async {
    final db = await database;
    await db.update(
      'memories',
      {
        'isDeleted': 0,
        'updatedAt': DateTime.now().toIso8601String(),
        'syncStatus': SyncStatus.pendingUpload.name,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> permanentDeleteMemory(String id) async {
    final db = await database;
    await db.delete(
      'memories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> toggleFavorite(String id, bool isFavorite) async {
    final db = await database;
    await db.update(
      'memories',
      {
        'isFavorite': isFavorite ? 1 : 0,
        'updatedAt': DateTime.now().toIso8601String(),
        'syncStatus': SyncStatus.pendingUpload.name,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> toggleArchive(String id, bool isArchived) async {
    final db = await database;
    await db.update(
      'memories',
      {
        'isArchived': isArchived ? 1 : 0,
        'updatedAt': DateTime.now().toIso8601String(),
        'syncStatus': SyncStatus.pendingUpload.name,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<MemoryItem>> getActiveMemories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'memories',
      where: 'isDeleted = 0 AND isArchived = 0',
      orderBy: 'updatedAt DESC',
    );
    return maps.map((m) => MemoryItem.fromMap(m)).toList();
  }

  Future<List<MemoryItem>> getFavoriteMemories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'memories',
      where: 'isDeleted = 0 AND isFavorite = 1',
      orderBy: 'updatedAt DESC',
    );
    return maps.map((m) => MemoryItem.fromMap(m)).toList();
  }

  Future<List<MemoryItem>> getArchivedMemories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'memories',
      where: 'isDeleted = 0 AND isArchived = 1',
      orderBy: 'updatedAt DESC',
    );
    return maps.map((m) => MemoryItem.fromMap(m)).toList();
  }

  Future<List<MemoryItem>> getTrashMemories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'memories',
      where: 'isDeleted = 1',
      orderBy: 'updatedAt DESC',
    );
    return maps.map((m) => MemoryItem.fromMap(m)).toList();
  }

  Future<List<MemoryItem>> getPendingSyncItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'memories',
      where: 'syncStatus != ?',
      whereArgs: [SyncStatus.synced.name],
    );
    return maps.map((m) => MemoryItem.fromMap(m)).toList();
  }

  Future<void> markSynced(String id) async {
    final db = await database;
    await db.update(
      'memories',
      {'syncStatus': SyncStatus.synced.name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> emptyTrash() async {
    final db = await database;
    await db.delete(
      'memories',
      where: 'isDeleted = 1',
    );
  }

  Future<void> seedInitialDataIfEmpty(List<MemoryItem> defaultMemories) async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM memories'),
    );

    if (count == null || count == 0) {
      final batch = db.batch();
      for (final memory in defaultMemories) {
        batch.insert(
          'memories',
          memory.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      await batch.commit(noResult: true);
    }
  }
}
