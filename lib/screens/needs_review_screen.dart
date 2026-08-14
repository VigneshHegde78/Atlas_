import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/memory_provider.dart';
import '../theme/app_theme.dart';

class NeedsReviewScreen extends StatelessWidget {
  const NeedsReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final memoryProvider = Provider.of<MemoryProvider>(context);

    return Scaffold(
      backgroundColor: AtlasColors.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Just a quick check'),
      ),
      body: SafeArea(
        child: memoryProvider.triageItems.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: AtlasColors.emeraldLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.check_rounded,
                          color: AtlasColors.emerald,
                          size: 32,
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
                      'No items need clarification right now.',
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
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'I\'m not completely sure where this belongs. Tap a suggestion to help me learn.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Expanded(
                      child: ListView.separated(
                        itemCount: memoryProvider.triageItems.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final item = memoryProvider.triageItems[index];
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
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          item.iconData,
                                          color: Colors.grey.shade600,
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.title,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: AtlasColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            item.subtitle,
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
                                const SizedBox(height: 20),

                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _buildCategoryChip(
                                      context,
                                      item.id,
                                      'Travel',
                                      AtlasColors.blueLight.withOpacity(0.1),
                                      AtlasColors.blue,
                                    ),
                                    _buildCategoryChip(
                                      context,
                                      item.id,
                                      'Finance',
                                      Colors.grey.shade100,
                                      Colors.grey.shade800,
                                    ),
                                    _buildCategoryChip(
                                      context,
                                      item.id,
                                      'Reference',
                                      Colors.grey.shade100,
                                      Colors.grey.shade800,
                                    ),
                                    _buildCategoryChip(
                                      context,
                                      item.id,
                                      'Other...',
                                      Colors.grey.shade50,
                                      Colors.grey.shade500,
                                      isDashed: true,
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
    Color textCol, {
    bool isDashed = false,
  }) {
    return InkWell(
      onTap: () {
        final provider = Provider.of<MemoryProvider>(context, listen: false);
        provider.resolveTriageItem(itemId, label);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Categorized as $label')),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: isDashed ? Border.all(color: Colors.grey.shade300, style: BorderStyle.solid) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: textCol,
          ),
        ),
      ),
    );
  }
}
