import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/memory_item.dart';
import '../providers/memory_provider.dart';
import '../theme/app_theme.dart';
import 'edit_memory_sheet.dart';

class DetailScreen extends StatefulWidget {
  final MemoryItem memory;

  const DetailScreen({super.key, required this.memory});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late MemoryItem _currentMemory;

  @override
  void initState() {
    super.initState();
    _currentMemory = widget.memory;
  }

  void _openEditSheet() async {
    final updated = await showModalBottomSheet<MemoryItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditMemorySheet(memory: _currentMemory),
    );

    if (updated != null && mounted) {
      setState(() {
        _currentMemory = updated;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Memory updated successfully!')),
      );
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Move to Trash?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(
          'This memory will be moved to the Trash. You can restore it anytime from your Account & Privacy settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              final provider = Provider.of<MemoryProvider>(context, listen: false);
              final deletedItem = _currentMemory;
              provider.softDeleteMemory(_currentMemory.id);
              Navigator.of(context).pop();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Moved to Trash'),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () {
                      provider.restoreMemory(deletedItem.id);
                    },
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AtlasColors.rose,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Move to Trash', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MemoryProvider>(context);

    // Keep state updated from provider if modified elsewhere
    final found = provider.memories.firstWhere(
      (m) => m.id == _currentMemory.id,
      orElse: () => _currentMemory,
    );
    _currentMemory = found;

    return Scaffold(
      backgroundColor: AtlasColors.surface,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 280,
                  color: _currentMemory.iconBgColor,
                  child: _currentMemory.imageBytes != null
                      ? Image.memory(_currentMemory.imageBytes!, fit: BoxFit.cover)
                      : (_currentMemory.imagePath != null
                          ? Image.file(File(_currentMemory.imagePath!), fit: BoxFit.cover)
                          : Center(
                              child: Icon(
                                _currentMemory.iconData,
                                size: 80,
                                color: AtlasColors.blue.withValues(alpha: 0.4),
                              ),
                            )),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white.withValues(alpha: 0.95),
                          radius: 22,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_rounded, size: 18, color: AtlasColors.blue),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.white.withValues(alpha: 0.95),
                              radius: 22,
                              child: IconButton(
                                icon: Icon(
                                  _currentMemory.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                  size: 20,
                                  color: _currentMemory.isFavorite ? AtlasColors.rose : AtlasColors.blue,
                                ),
                                onPressed: () {
                                  provider.toggleFavorite(_currentMemory.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      duration: const Duration(seconds: 1),
                                      content: Text(
                                        _currentMemory.isFavorite
                                            ? 'Removed from Favorites'
                                            : 'Added to Favorites',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            CircleAvatar(
                              backgroundColor: Colors.white.withValues(alpha: 0.95),
                              radius: 22,
                              child: IconButton(
                                icon: const Icon(Icons.edit_rounded, size: 18, color: AtlasColors.blue),
                                onPressed: _openEditSheet,
                              ),
                            ),
                            const SizedBox(width: 8),
                            CircleAvatar(
                              backgroundColor: Colors.white.withValues(alpha: 0.95),
                              radius: 22,
                              child: IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AtlasColors.rose),
                                onPressed: _confirmDelete,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            Transform.translate(
              offset: const Offset(0, -28),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28.0),
                decoration: const BoxDecoration(
                  color: AtlasColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(Icons.language_rounded, size: 14, color: Colors.grey),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_currentMemory.sourceApp.toUpperCase()} • ${_currentMemory.category.toUpperCase()}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.grey.shade500,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                        if (_currentMemory.isArchived)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'ARCHIVED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Text(
                      _currentMemory.title,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AtlasColors.blue,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // AI Understanding block
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [AtlasTheme.softShadow],
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ShaderMask(
                                shaderCallback: (bounds) => const LinearGradient(
                                  colors: [AtlasColors.purple, Colors.blueAccent],
                                ).createShader(bounds),
                                child: const Icon(
                                  Icons.auto_awesome_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 8),
                              ShaderMask(
                                shaderCallback: (bounds) => const LinearGradient(
                                  colors: [AtlasColors.purple, Colors.blueAccent],
                                ).createShader(bounds),
                                child: const Text(
                                  'AI UNDERSTANDING',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _currentMemory.aiSummary.isNotEmpty
                                ? _currentMemory.aiSummary
                                : 'Extracted and indexed in ATLAS Memory Space.',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Notes / Content block if available
                    if (_currentMemory.content.isNotEmpty &&
                        _currentMemory.content != _currentMemory.aiSummary) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [AtlasTheme.softShadow],
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'NOTES & SNIPPET',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AtlasColors.blue,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _currentMemory.content,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade800,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Action Buttons Row
                    Row(
                      children: [
                        if (_currentMemory.url != null && _currentMemory.url!.isNotEmpty)
                          Expanded(
                            child: SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Opening ${_currentMemory.url}...')),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AtlasColors.blue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  elevation: 4,
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.open_in_new_rounded, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      'Open Link',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        else
                          Expanded(
                            child: SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _openEditSheet,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AtlasColors.blue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  elevation: 4,
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.edit_rounded, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      'Edit Notes',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(width: 12),
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: IconButton(
                            icon: Icon(
                              _currentMemory.isArchived ? Icons.unarchive_rounded : Icons.archive_outlined,
                              color: AtlasColors.blue,
                              size: 22,
                            ),
                            onPressed: () {
                              provider.toggleArchive(_currentMemory.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    _currentMemory.isArchived ? 'Unarchived memory' : 'Archived memory',
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    const Text(
                      'Related Memories',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AtlasColors.blue,
                      ),
                    ),
                    const SizedBox(height: 14),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Center(
                              child: Icon(Icons.palette_rounded, color: Colors.grey, size: 20),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'UI Inspiration Board',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AtlasColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Collection • ${_currentMemory.category}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
