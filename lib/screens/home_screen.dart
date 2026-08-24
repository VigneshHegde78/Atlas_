import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/memory_item.dart';
import '../providers/memory_provider.dart';
import '../services/firebase_sync_service.dart';
import '../theme/app_theme.dart';
import 'detail_screen.dart';
import 'search_screen.dart';
import 'needs_review_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedFilter = 'All'; // 'All', 'Favorites', or category name

  @override
  Widget build(BuildContext context) {
    final memoryProvider = Provider.of<MemoryProvider>(context);

    // Compute filtered list
    List<MemoryItem> displayedMemories;
    if (_selectedFilter == 'Favorites') {
      displayedMemories = memoryProvider.favoriteMemories;
    } else if (_selectedFilter != 'All') {
      displayedMemories = memoryProvider.memories
          .where((m) => m.category == _selectedFilter)
          .toList();
    } else {
      displayedMemories = memoryProvider.memories;
    }

    // Extract unique categories for filter chips
    final categories = <String>{'All', 'Favorites'};
    for (final m in memoryProvider.memories) {
      if (m.category.isNotEmpty) categories.add(m.category);
    }

    return Scaffold(
      backgroundColor: AtlasColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header with Sync Status Indicator & Profile Avatar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Good morning, Alex',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildSyncStatusBadge(memoryProvider),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Your Memory',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: AtlasColors.blue,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [AtlasTheme.softShadow],
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.person_outline_rounded,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Search Trigger Bar
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SearchScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [AtlasTheme.softShadow],
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Row(
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [AtlasColors.purple, Colors.blueAccent],
                        ).createShader(bounds),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'Ask ATLAS anything...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Filter Chips Bar
              SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, idx) {
                    final cat = categories.elementAt(idx);
                    final isSelected = _selectedFilter == cat;
                    final isFavTab = cat == 'Favorites';

                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedFilter = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isFavTab ? AtlasColors.rose : AtlasColors.blue)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? (isFavTab ? AtlasColors.rose : AtlasColors.blue)
                                  : Colors.grey.shade200,
                            ),
                            boxShadow: isSelected ? [AtlasTheme.softShadow] : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isFavTab) ...[
                                Icon(
                                  Icons.favorite_rounded,
                                  size: 13,
                                  color: isSelected ? Colors.white : AtlasColors.rose,
                                ),
                                const SizedBox(width: 5),
                              ],
                              Text(
                                isFavTab
                                    ? 'Favorites (${memoryProvider.favoriteMemories.length})'
                                    : cat,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? Colors.white : AtlasColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Needs Clarification Triage Alert
              if (memoryProvider.triageItems.isNotEmpty)
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const NeedsReviewScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AtlasColors.amberLight.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: AtlasColors.amber.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Clarify ${memoryProvider.triageItems.length} Items',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF78350F),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'I\'m not completely sure how to organize a few recent saves.',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFFB45309).withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AtlasColors.amber.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              color: Color(0xFF78350F),
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (memoryProvider.triageItems.isNotEmpty) const SizedBox(height: 24),

              // Memories List Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedFilter == 'Favorites'
                        ? 'Favorite Memories'
                        : (_selectedFilter == 'All' ? 'Recently Saved' : '$_selectedFilter Saves'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AtlasColors.blue,
                    ),
                  ),
                  Text(
                    '${displayedMemories.length} items',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Empty State
              if (displayedMemories.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _selectedFilter == 'Favorites'
                            ? Icons.favorite_border_rounded
                            : Icons.auto_awesome_rounded,
                        size: 48,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _selectedFilter == 'Favorites'
                            ? 'No favorites yet'
                            : 'No memories saved here',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AtlasColors.blue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedFilter == 'Favorites'
                            ? 'Tap the heart icon on any memory to pin it here.'
                            : 'Share links, screenshots, or tap (+) below to save.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              else
                // Memory Cards with Swipe-to-Delete
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayedMemories.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final item = displayedMemories[index];

                    return Dismissible(
                      key: Key('mem_${item.id}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        decoration: BoxDecoration(
                          color: AtlasColors.rose,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Move to Trash',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
                          ],
                        ),
                      ),
                      onDismissed: (_) {
                        final deletedItem = item;
                        memoryProvider.softDeleteMemory(item.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Moved "${deletedItem.title}" to Trash'),
                            action: SnackBarAction(
                              label: 'Undo',
                              onPressed: () {
                                memoryProvider.restoreMemory(deletedItem.id);
                              },
                            ),
                          ),
                        );
                      },
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => DetailScreen(memory: item),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [AtlasTheme.softShadow],
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: item.iconBgColor,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: item.imageBytes != null
                                      ? Image.memory(item.imageBytes!, fit: BoxFit.cover)
                                      : (item.imagePath != null
                                          ? Image.file(File(item.imagePath!), fit: BoxFit.cover)
                                          : Center(
                                              child: Icon(
                                                item.iconData,
                                                color: AtlasColors.blue,
                                                size: 24,
                                              ),
                                            )),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          'Saved ${item.category}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AtlasColors.purple.withValues(alpha: 0.8),
                                          ),
                                        ),
                                        if (item.isFavorite) ...[
                                          const SizedBox(width: 6),
                                          const Icon(Icons.favorite_rounded, color: AtlasColors.rose, size: 12),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  item.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                  color: item.isFavorite ? AtlasColors.rose : Colors.grey.shade300,
                                  size: 20,
                                ),
                                onPressed: () {
                                  memoryProvider.toggleFavorite(item.id);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSyncStatusBadge(MemoryProvider provider) {
    Color badgeColor;
    IconData badgeIcon;
    String label;

    switch (provider.syncState) {
      case CloudSyncState.synced:
        badgeColor = AtlasColors.emerald;
        badgeIcon = Icons.cloud_done_rounded;
        label = 'Cloud Synced';
        break;
      case CloudSyncState.syncing:
        badgeColor = AtlasColors.amber;
        badgeIcon = Icons.sync_rounded;
        label = 'Syncing...';
        break;
      case CloudSyncState.offline:
      case CloudSyncState.error:
        badgeColor = Colors.grey.shade400;
        badgeIcon = Icons.cloud_off_rounded;
        label = 'Local Only';
        break;
    }

    return GestureDetector(
      onTap: () => provider.syncNow(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: badgeColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(badgeIcon, size: 12, color: badgeColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: badgeColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
