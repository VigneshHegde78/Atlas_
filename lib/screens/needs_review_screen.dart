import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/memory_item.dart';
import '../providers/memory_provider.dart';
import '../theme/app_theme.dart';

class NeedsReviewScreen extends StatelessWidget {
  const NeedsReviewScreen({super.key});

  void _showCustomCategoryDialog(BuildContext context, String itemId) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Custom Category', style: TextStyle(fontWeight: FontWeight.w800, color: AtlasColors.blue)),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Health, Music, Fitness',
            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AtlasColors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final val = textController.text.trim();
              if (val.isNotEmpty) {
                Navigator.of(dialogCtx).pop();
                final provider = Provider.of<MemoryProvider>(context, listen: false);
                provider.resolveTriageItem(itemId, val);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AtlasColors.blue,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    content: Text('Categorized as "$val" and moved to Memory Space!'),
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final memoryProvider = Provider.of<MemoryProvider>(context);

    return Scaffold(
      backgroundColor: AtlasColors.surface,
      appBar: AppBar(
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: const Text('Clarify & Organize'),
      ),
      body: SafeArea(
        child: memoryProvider.triageItems.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: const BoxDecoration(
                        color: AtlasColors.emeraldLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.check_rounded,
                          color: AtlasColors.emerald,
                          size: 38,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'All caught up!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AtlasColors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No items need clarification right now. All memories are neatly organized.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'I\'m not completely sure how to organize these captures. Tap a suggested space to help me learn.',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),

                    Expanded(
                      child: ListView.separated(
                        itemCount: memoryProvider.triageItems.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final item = memoryProvider.triageItems[index];
                          final hasImage = (item.imageBytes != null) ||
                              (item.imagePath != null && item.imagePath!.isNotEmpty);

                          return Container(
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
                                    Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: item.iconBgColor,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: item.imageBytes != null
                                            ? Image.memory(
                                                item.imageBytes!,
                                                fit: BoxFit.cover,
                                              )
                                            : (item.imagePath != null && item.imagePath!.isNotEmpty
                                                ? (item.imagePath!.startsWith('http')
                                                    ? Image.network(item.imagePath!, fit: BoxFit.cover)
                                                    : Image.file(File(item.imagePath!), fit: BoxFit.cover))
                                                : Center(
                                                    child: Icon(
                                                      item.iconData,
                                                      color: AtlasColors.blue,
                                                      size: 24,
                                                    ),
                                                  )),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: AtlasColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            item.subtitle,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey.shade500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (item.aiSummary.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AtlasColors.purple.withValues(
                                        alpha: 0.06,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.auto_awesome_rounded,
                                          size: 14,
                                          color: AtlasColors.purple,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            item.aiSummary,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey.shade700,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _buildCategoryChip(
                                      context,
                                      item.id,
                                      'Finance',
                                      const Color(0xFFDCFCE7),
                                      const Color(0xFF166534),
                                    ),
                                    _buildCategoryChip(
                                      context,
                                      item.id,
                                      'Recipes',
                                      const Color(0xFFFEF3C7),
                                      const Color(0xFF92400E),
                                    ),
                                    _buildCategoryChip(
                                      context,
                                      item.id,
                                      'Travel',
                                      const Color(0xFFDBEAFE),
                                      const Color(0xFF1E40AF),
                                    ),
                                    _buildCategoryChip(
                                      context,
                                      item.id,
                                      'Development',
                                      const Color(0xFFE0E7FF),
                                      const Color(0xFF3730A3),
                                    ),
                                    _buildCategoryChip(
                                      context,
                                      item.id,
                                      'Design Systems',
                                      const Color(0xFFF3E8FF),
                                      const Color(0xFF6B21A8),
                                    ),
                                    _buildCategoryChip(
                                      context,
                                      item.id,
                                      'Shopping',
                                      const Color(0xFFFFF1F2),
                                      const Color(0xFF9F1239),
                                    ),
                                    _buildCategoryChip(
                                      context,
                                      item.id,
                                      'Work',
                                      const Color(0xFFEFF6FF),
                                      const Color(0xFF1E3A8A),
                                    ),
                                    _buildCategoryChip(
                                      context,
                                      item.id,
                                      'Reference',
                                      const Color(0xFFF1F5F9),
                                      const Color(0xFF334155),
                                    ),
                                    InkWell(
                                      onTap: () => _showCustomCategoryDialog(context, item.id),
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.add_rounded, size: 14, color: AtlasColors.blue),
                                            SizedBox(width: 4),
                                            Text(
                                              'Custom...',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: AtlasColors.blue,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildCategoryChip(
    BuildContext context,
    String itemId,
    String label,
    Color bg,
    Color textCol,
  ) {
    return InkWell(
      onTap: () {
        final provider = Provider.of<MemoryProvider>(context, listen: false);
        provider.resolveTriageItem(itemId, label);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AtlasColors.blue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Text('Categorized as "$label" and moved to Memory Space!'),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: textCol,
          ),
        ),
      ),
    );
  }
}
