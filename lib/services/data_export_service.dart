import 'dart:convert';
import 'package:intl/intl.dart';
import '../models/collection_item.dart';
import '../models/memory_item.dart';

class DataExportService {
  static final DataExportService instance = DataExportService._internal();
  DataExportService._internal();

  /// Exports all memories and collections into a complete JSON vault format.
  String exportToJson(List<MemoryItem> memories, List<MemoryCollection> collections) {
    final exportData = {
      'app': 'ATLAS Personal Memory OS',
      'version': '3.0.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'totalMemories': memories.length,
      'totalCollections': collections.length,
      'collections': collections.map((c) => c.toMap()).toList(),
      'memories': memories.map((m) => m.toMap()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  /// Exports memories into a combined Obsidian / Notion compatible Markdown vault.
  String exportToObsidianMarkdown(List<MemoryItem> memories, List<MemoryCollection> collections) {
    final buffer = StringBuffer();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    buffer.writeln('# ATLAS Memory Vault Export');
    buffer.writeln('> Generated on ${dateFormat.format(DateTime.now())}');
    buffer.writeln('> Total Memories: ${memories.length} | Collections: ${collections.length}\n');
    buffer.writeln('---\n');

    // Collections Index
    if (collections.isNotEmpty) {
      buffer.writeln('## 📁 Collections Index\n');
      for (final col in collections) {
        buffer.writeln('- **${col.title}** (${col.isSmart ? "⚡ Smart Album" : "Custom Space"})');
        if (col.description.isNotEmpty) {
          buffer.writeln('  - *${col.description}*');
        }
      }
      buffer.writeln('\n---\n');
    }

    // Memories
    buffer.writeln('## 🧠 Memories & Second Brain Notes\n');
    for (final memory in memories) {
      buffer.writeln('### ${memory.title}\n');
      buffer.writeln('```yaml');
      buffer.writeln('id: "${memory.id}"');
      buffer.writeln('date: "${dateFormat.format(memory.savedAt)}"');
      buffer.writeln('type: "${memory.type.name}"');
      buffer.writeln('category: "${memory.category}"');
      buffer.writeln('source: "${memory.sourceApp}"');
      if (memory.url != null && memory.url!.isNotEmpty) {
        buffer.writeln('url: "${memory.url}"');
      }
      if (memory.tags.isNotEmpty) {
        buffer.writeln('tags: [${memory.tags.map((t) => '"$t"').join(', ')}]');
      }
      buffer.writeln('favorite: ${memory.isFavorite}');
      buffer.writeln('```\n');

      if (memory.aiSummary.isNotEmpty) {
        buffer.writeln('**AI Summary:**\n> ${memory.aiSummary}\n');
      }

      if (memory.content.isNotEmpty) {
        buffer.writeln('**Content / Note:**\n${memory.content}\n');
      }

      if (memory.extractedText != null && memory.extractedText!.isNotEmpty && memory.extractedText != memory.content) {
        buffer.writeln('**Extracted OCR / Transcript:**\n```text');
        buffer.writeln(memory.extractedText);
        buffer.writeln('```\n');
      }

      if (memory.structuredEntities != null && memory.structuredEntities!.isNotEmpty) {
        buffer.writeln('**Structured Entities:**');
        memory.structuredEntities!.forEach((k, v) {
          buffer.writeln('- **$k**: $v');
        });
        buffer.writeln('');
      }

      buffer.writeln('---\n');
    }

    return buffer.toString();
  }

  /// Exports memories into a spreadsheet-compatible CSV string.
  String exportToCsv(List<MemoryItem> memories) {
    final buffer = StringBuffer();
    // CSV Header
    buffer.writeln('ID,Title,Category,Type,SourceApp,SavedAt,Favorite,Tags,Summary,URL');

    for (final m in memories) {
      final id = _escapeCsv(m.id);
      final title = _escapeCsv(m.title);
      final category = _escapeCsv(m.category);
      final type = _escapeCsv(m.type.name);
      final source = _escapeCsv(m.sourceApp);
      final date = _escapeCsv(m.savedAt.toIso8601String());
      final fav = m.isFavorite ? 'TRUE' : 'FALSE';
      final tags = _escapeCsv(m.tags.join('; '));
      final summary = _escapeCsv(m.aiSummary);
      final url = _escapeCsv(m.url ?? '');

      buffer.writeln('$id,$title,$category,$type,$source,$date,$fav,$tags,$summary,$url');
    }

    return buffer.toString();
  }

  String _escapeCsv(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }
}
