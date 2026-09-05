import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/memory_item.dart';
import '../providers/memory_provider.dart';
import '../services/auth_service.dart';
import '../services/firebase_sync_service.dart';
import '../theme/app_theme.dart';
import 'detail_screen.dart';
import 'search_screen.dart';
import 'needs_review_screen.dart';
import 'profile_screen.dart';
import 'add_memory_sheet.dart';
import 'ask_atlas_screen.dart';
import 'collections_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedFilter = 'All'; // 'All', 'Favorites', or category name
  bool _isSelectionMode = false;
  final Set<String> _selectedMemoryIds = {};

  void _openAddMemory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddMemorySheet(),
    );
  }

  void _toggleSelection(String id) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedMemoryIds.contains(id)) {
        _selectedMemoryIds.remove(id);
        if (_selectedMemoryIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedMemoryIds.add(id);
        _isSelectionMode = true;
      }
    });
  }

  void _selectAll(List<MemoryItem> memories) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedMemoryIds.length == memories.length) {
        _selectedMemoryIds.clear();
        _isSelectionMode = false;
      } else {
        _selectedMemoryIds.addAll(memories.map((m) => m.id));
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectedMemoryIds.clear();
      _isSelectionMode = false;
    });
  }

  void _showBulkCategoryPicker(BuildContext context, MemoryProvider provider) {
    final categories = [
      'Finance',
      'Recipes',
      'Travel',
      'Development',
      'Design Systems',
      'Shopping',
      'Work',
      'Reference',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Assign Category to Selected Items',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((cat) {
                return InkWell(
                  onTap: () {
                    provider.bulkAssignCategory(
                      _selectedMemoryIds.toList(),
                      cat,
                    );
                    _exitSelectionMode();
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Updated category to "$cat" for selected items',
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      cat,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showBulkCollectionPicker(
    BuildContext context,
    MemoryProvider provider,
  ) {
    final collections = provider.collections.where((c) => !c.isSmart).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add to Collection Space',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),
            if (collections.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No custom collections created yet.'),
              )
            else
              ...collections.map((col) {
                return ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: col.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(col.icon, color: col.color, size: 18),
                  ),
                  title: Text(
                    col.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    '${col.itemIds.length} items',
                    style: const TextStyle(fontSize: 12),
                  ),
                  onTap: () {
                    provider.bulkAddToCollection(
                      _selectedMemoryIds.toList(),
                      col.id,
                    );
                    _exitSelectionMode();
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Added to collection "${col.title}"'),
                      ),
                    );
                  },
                );
              }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

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
      floatingActionButton: _isSelectionMode
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 74.0),
              child: FloatingActionButton(
                onPressed: _openAddMemory,
                backgroundColor: AtlasColors.blue,
                foregroundColor: Colors.white,
                elevation: 8,
                shape: const CircleBorder(),
                child: const Icon(Icons.add_rounded, size: 30),
              ),
            ),
      bottomNavigationBar: _isSelectionMode
          ? Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AtlasColors.blue,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AtlasColors.blue.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _bulkActionButton(
                    icon: Icons.star_rounded,
                    label: 'Favorite',
                    onTap: () {
                      memoryProvider.bulkToggleFavorite(
                        _selectedMemoryIds.toList(),
                        true,
                      );
                      _exitSelectionMode();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Marked selected items as Favorite'),
                        ),
                      );
                    },
                  ),
                  _bulkActionButton(
                    icon: Icons.folder_rounded,
                    label: 'Collection',
                    onTap: () =>
                        _showBulkCollectionPicker(context, memoryProvider),
                  ),
                  _bulkActionButton(
                    icon: Icons.category_rounded,
                    label: 'Category',
                    onTap: () =>
                        _showBulkCategoryPicker(context, memoryProvider),
                  ),
                  _bulkActionButton(
                    icon: Icons.delete_outline_rounded,
                    label: 'Delete',
                    color: Colors.redAccent,
                    onTap: () {
                      final count = _selectedMemoryIds.length;
                      memoryProvider.bulkSoftDelete(
                        _selectedMemoryIds.toList(),
                      );
                      _exitSelectionMode();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Moved $count items to Trash')),
                      );
                    },
                  ),
                ],
              ),
            )
          : null,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header with Selection Mode or Default Header
              if (_isSelectionMode)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFF0F172A),
                        ),
                        onPressed: _exitSelectionMode,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_selectedMemoryIds.length} Selected',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => _selectAll(displayedMemories),
                        child: Text(
                          _selectedMemoryIds.length == displayedMemories.length
                              ? 'Deselect All'
                              : 'Select All',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'Good day, Vignesh',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              _buildSyncStatusBadge(memoryProvider),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Your Memory',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.folder_copy_rounded,
                            color: Color(0xFF0F172A),
                          ),
                          tooltip: 'Collections & Albums',
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const CollectionsScreen(),
                              ),
                            );
                          },
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
                          child: AnimatedBuilder(
                            animation: AuthService.instance,
                            builder: (context, _) {
                              final isAuth =
                                  AuthService.instance.isAuthenticated;
                              final name = AuthService.instance.userDisplayName;
                              final initials = isAuth
                                  ? (name.length >= 2
                                        ? name.substring(0, 2).toUpperCase()
                                        : (name.isNotEmpty
                                              ? name
                                                    .substring(0, 1)
                                                    .toUpperCase()
                                              : 'U'))
                                  : '?';
                              return Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AtlasColors.blue,
                                  shape: BoxShape.circle,
                                  boxShadow: [AtlasTheme.softShadow],
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    initials,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              const SizedBox(height: 24),

              // Search Trigger Bar
              // Search & Ask ATLAS Trigger Bar
              if (!_isSelectionMode)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [AtlasTheme.softShadow],
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const AskAtlasScreen(),
                              ),
                            );
                          },
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(28),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.auto_awesome_rounded,
                                  color: Color(0xFF9333EA),
                                  size: 20,
                                ),
                                const SizedBox(width: 14),
                                Text(
                                  'Ask ATLAS anything...',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF0F172A),
                          size: 22,
                        ),
                        tooltip: 'Keyword & OCR Search',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SearchScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 6),
                    ],
                  ),
                ),
              if (!_isSelectionMode) const SizedBox(height: 20),

              // Filter Chips Bar + Collections Shortcut
              if (!_isSelectionMode)
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length + 1,
                    itemBuilder: (context, idx) {
                      if (idx == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const CollectionsScreen(),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF0F172A,
                                ).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.folder_copy_rounded,
                                    size: 13,
                                    color: Color(0xFF0F172A),
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    'Collections',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      final cat = categories.elementAt(idx - 1);
                      final isSelected = _selectedFilter == cat;
                      final isFavTab = cat == 'Favorites';

                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedFilter = cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isFavTab
                                        ? AtlasColors.rose
                                        : AtlasColors.blue)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? (isFavTab
                                          ? AtlasColors.rose
                                          : AtlasColors.blue)
                                    : Colors.grey.shade200,
                              ),
                              boxShadow: isSelected
                                  ? [AtlasTheme.softShadow]
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isFavTab) ...[
                                  Icon(
                                    Icons.favorite_rounded,
                                    size: 13,
                                    color: isSelected
                                        ? Colors.white
                                        : AtlasColors.rose,
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
                                    color: isSelected
                                        ? Colors.white
                                        : AtlasColors.textPrimary,
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
              if (!_isSelectionMode) const SizedBox(height: 20),

              // Needs Clarification Triage Alert
              if (memoryProvider.triageItems.isNotEmpty && !_isSelectionMode)
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
                      border: Border.all(
                        color: AtlasColors.amber.withValues(alpha: 0.3),
                      ),
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
                                  color: AtlasColors.amberDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Review imported screenshots & voice notes needing context.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AtlasColors.amberDark.withValues(
                                    alpha: 0.8,
                                  ),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: AtlasColors.amber,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (memoryProvider.triageItems.isNotEmpty && !_isSelectionMode)
                const SizedBox(height: 24),

              // Memories List Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedFilter == 'Favorites'
                        ? 'Favorite Memories'
                        : (_selectedFilter == 'All'
                              ? 'Recently Saved'
                              : '$_selectedFilter Saves'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Row(
                    children: [
                      if (!_isSelectionMode)
                        InkWell(
                          onTap: () {
                            setState(() => _isSelectionMode = true);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.checklist_rounded,
                                  size: 14,
                                  color: Color(0xFF0F172A),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Select',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
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
                ],
              ),
              const SizedBox(height: 16),

              // Empty State
              if (displayedMemories.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 48,
                    horizontal: 24,
                  ),
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
                          color: Color(0xFF0F172A),
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
                // Memory Cards
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayedMemories.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final item = displayedMemories[index];
                    final isSelected = _selectedMemoryIds.contains(item.id);

                    return Dismissible(
                      key: Key('mem_${item.id}'),
                      direction: _isSelectionMode
                          ? DismissDirection.none
                          : DismissDirection.endToStart,
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
                            Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                      onDismissed: (_) {
                        final deletedItem = item;
                        memoryProvider.softDeleteMemory(item.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Moved "${deletedItem.title}" to Trash',
                            ),
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
                        onLongPress: () => _toggleSelection(item.id),
                        onTap: () {
                          if (_isSelectionMode) {
                            _toggleSelection(item.id);
                          } else {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    DetailScreen(memory: item),
                              ),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [AtlasTheme.softShadow],
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF2563EB)
                                  : Colors.grey.shade100,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              if (_isSelectionMode) ...[
                                Icon(
                                  isSelected
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  color: isSelected
                                      ? const Color(0xFF2563EB)
                                      : Colors.grey.shade400,
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                              ],
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
                                      ? Image.memory(
                                          item.imageBytes!,
                                          fit: BoxFit.cover,
                                        )
                                      : (item.imagePath != null &&
                                                item.imagePath!.isNotEmpty
                                            ? (item.imagePath!.startsWith(
                                                    'http',
                                                  )
                                                  ? Image.network(
                                                      item.imagePath!,
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (
                                                            ctx,
                                                            err,
                                                            stack,
                                                          ) => Center(
                                                            child: Icon(
                                                              item.iconData,
                                                              color:
                                                                  const Color(
                                                                    0xFF0F172A,
                                                                  ),
                                                              size: 24,
                                                            ),
                                                          ),
                                                    )
                                                  : Image.file(
                                                      File(item.imagePath!),
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (
                                                            ctx,
                                                            err,
                                                            stack,
                                                          ) => Center(
                                                            child: Icon(
                                                              item.iconData,
                                                              color:
                                                                  const Color(
                                                                    0xFF0F172A,
                                                                  ),
                                                              size: 24,
                                                            ),
                                                          ),
                                                    ))
                                            : Center(
                                                child: Icon(
                                                  item.iconData,
                                                  color: const Color(
                                                    0xFF0F172A,
                                                  ),
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
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        if (item.isFavorite) ...[
                                          const SizedBox(width: 6),
                                          const Icon(
                                            Icons.favorite_rounded,
                                            color: AtlasColors.rose,
                                            size: 12,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
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

  Widget _bulkActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncStatusBadge(MemoryProvider memoryProvider) {
    switch (memoryProvider.syncState) {
      case CloudSyncState.synced:
        return Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AtlasColors.emerald,
            shape: BoxShape.circle,
          ),
        );
      case CloudSyncState.syncing:
        return const SizedBox(
          width: 8,
          height: 8,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            valueColor: AlwaysStoppedAnimation<Color>(AtlasColors.blue),
          ),
        );
      case CloudSyncState.pending:
        return Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AtlasColors.amber,
            shape: BoxShape.circle,
          ),
        );
      case CloudSyncState.error:
        return Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AtlasColors.rose,
            shape: BoxShape.circle,
          ),
        );
      case CloudSyncState.offline:
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey.shade400,
            shape: BoxShape.circle,
          ),
        );
    }
  }
}
