import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/memory_item.dart';
import '../providers/memory_provider.dart';
import '../theme/app_theme.dart';
import 'detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchResultMatch {
  final MemoryItem item;
  final String matchReason;
  final String matchedSnippet;

  _SearchResultMatch({
    required this.item,
    required this.matchReason,
    required this.matchedSnippet,
  });
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _queryText = '';

  // Multi-dimensional filter states
  String _selectedType =
      'All'; // 'All', 'Screenshots', 'Links', 'Notes', 'PDFs'
  String _selectedCategory =
      'All'; // 'All', 'Finance', 'Recipes', 'Travel', etc.
  String _selectedDateRange =
      'All Time'; // 'All Time', 'Today', 'This Week', 'Past Month'
  bool _favoritesOnly = false;

  List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _recentSearches =
            prefs.getStringList('atlas_recent_searches') ??
            [
              'Recipe with paneer',
              'Coffee receipt',
              'Flight to Goa',
              'Flutter code',
              'UI palette',
            ];
      });
    } catch (_) {}
  }

  Future<void> _saveRecentSearch(String query) async {
    final clean = query.trim();
    if (clean.length < 2) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final updated = List<String>.from(_recentSearches);
      updated.remove(clean);
      updated.insert(0, clean);
      if (updated.length > 8) updated.removeLast();
      await prefs.setStringList('atlas_recent_searches', updated);
      setState(() {
        _recentSearches = updated;
      });
    } catch (_) {}
  }

  Future<void> _clearRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('atlas_recent_searches');
      setState(() {
        _recentSearches = [];
      });
    } catch (_) {}
  }

  void _onSearchChanged(String val) {
    setState(() {
      _queryText = val;
    });
  }

  void _submitSearch(String val) {
    _onSearchChanged(val);
    if (val.trim().length >= 2) {
      _saveRecentSearch(val.trim());
    }
  }

  void _openVoiceSearchDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetCtx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 28),

              // Animated Soundwave Visualizer Circle
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AtlasColors.purple, Colors.blueAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AtlasColors.purple.withValues(alpha: 0.35),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.mic_rounded, color: Colors.white, size: 38),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Listening to your voice...',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AtlasColors.blue,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Speak in natural language or tap a suggested voice prompt below.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 24),

              // Voice Sample Prompts
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _buildVoiceSampleChip(
                    bottomSheetCtx,
                    'Show coffee receipt from this week',
                  ),
                  _buildVoiceSampleChip(
                    bottomSheetCtx,
                    'Paneer tikka recipe ingredients',
                  ),
                  _buildVoiceSampleChip(
                    bottomSheetCtx,
                    'Flight booking to Goa',
                  ),
                  _buildVoiceSampleChip(
                    bottomSheetCtx,
                    'Flutter AnimatedContainer code',
                  ),
                  _buildVoiceSampleChip(
                    bottomSheetCtx,
                    'UI Design system color tokens',
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVoiceSampleChip(BuildContext ctx, String sampleQuery) {
    return InkWell(
      onTap: () {
        Navigator.of(ctx).pop();
        _searchController.text = sampleQuery;
        _submitSearch(sampleQuery);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AtlasColors.purple.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AtlasColors.purple.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              size: 14,
              color: AtlasColors.purple,
            ),
            const SizedBox(width: 6),
            Text(
              sampleQuery,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AtlasColors.purple,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_SearchResultMatch> _performSearch(
    List<MemoryItem> allMemories,
    String query,
  ) {
    final cleanQuery = query.trim().toLowerCase();
    final terms = cleanQuery
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();

    final now = DateTime.now();
    final List<_SearchResultMatch> matches = [];

    for (final item in allMemories) {
      if (item.isDeleted) continue;

      // 1. Type Filter
      if (_selectedType != 'All') {
        if (_selectedType == 'Screenshots' &&
            item.type != MemoryType.screenshot) {
          continue;
        }
        if (_selectedType == 'Links' && item.type != MemoryType.link) continue;
        if (_selectedType == 'Notes' && item.type != MemoryType.note) continue;
        if (_selectedType == 'PDFs' && item.type != MemoryType.pdf) continue;
        if (_selectedType == 'Voice' && item.type != MemoryType.audio) continue;
      }

      // 2. Category Filter
      if (_selectedCategory != 'All') {
        if (item.category.toLowerCase() != _selectedCategory.toLowerCase()) {
          continue;
        }
      }

      // 3. Favorites Only Filter
      if (_favoritesOnly && !item.isFavorite) continue;

      // 4. Date Range Filter
      if (_selectedDateRange != 'All Time') {
        final diff = now.difference(item.savedAt);
        if (_selectedDateRange == 'Today' && diff.inDays > 1) continue;
        if (_selectedDateRange == 'This Week' && diff.inDays > 7) continue;
        if (_selectedDateRange == 'Past Month' && diff.inDays > 30) continue;
      }

      // If query is empty but filters are active, include as a filter match!
      if (terms.isEmpty) {
        if (_selectedType != 'All' ||
            _selectedCategory != 'All' ||
            _favoritesOnly ||
            _selectedDateRange != 'All Time') {
          matches.add(
            _SearchResultMatch(
              item: item,
              matchReason: 'FILTERED MEMORY',
              matchedSnippet: item.aiSummary.isNotEmpty
                  ? item.aiSummary
                  : item.subtitle,
            ),
          );
        }
        continue;
      }

      // Text Fields
      final title = item.title.toLowerCase();
      final summary = item.aiSummary.toLowerCase();
      final ocrText = (item.extractedText ?? '').toLowerCase();
      final content = item.content.toLowerCase();
      final category = item.category.toLowerCase();
      final tags = item.tags.map((t) => t.toLowerCase()).join(' ');
      final entitiesStr = item.structuredEntities != null
          ? item.structuredEntities.toString().toLowerCase()
          : '';

      bool allTermsMatch(String field) =>
          terms.every((term) => field.contains(term));
      bool anyTermMatch(String field) =>
          terms.any((term) => field.contains(term));

      if (allTermsMatch(ocrText) || anyTermMatch(ocrText)) {
        String snippet = item.extractedText ?? '';
        if (snippet.length > 130) snippet = '${snippet.substring(0, 127)}...';
        matches.add(
          _SearchResultMatch(
            item: item,
            matchReason: 'OCR IMAGE TEXT',
            matchedSnippet: 'Found in screenshot OCR: "$snippet"',
          ),
        );
      } else if (allTermsMatch(summary) || anyTermMatch(summary)) {
        matches.add(
          _SearchResultMatch(
            item: item,
            matchReason: 'AI UNDERSTANDING',
            matchedSnippet: item.aiSummary,
          ),
        );
      } else if (allTermsMatch(entitiesStr) || anyTermMatch(entitiesStr)) {
        matches.add(
          _SearchResultMatch(
            item: item,
            matchReason: 'STRUCTURED ENTITY',
            matchedSnippet: item.subtitle,
          ),
        );
      } else if (allTermsMatch(title) ||
          anyTermMatch(title) ||
          allTermsMatch(tags) ||
          anyTermMatch(tags)) {
        matches.add(
          _SearchResultMatch(
            item: item,
            matchReason: 'TITLE & TAGS',
            matchedSnippet: item.tags.isNotEmpty
                ? 'Tags: #${item.tags.join(' #')}'
                : (item.content.isNotEmpty ? item.content : item.aiSummary),
          ),
        );
      } else if (allTermsMatch(category) || anyTermMatch(category)) {
        matches.add(
          _SearchResultMatch(
            item: item,
            matchReason: 'CATEGORY MATCH',
            matchedSnippet: 'Category: ${item.category} • ${item.aiSummary}',
          ),
        );
      } else if (allTermsMatch(content) || anyTermMatch(content)) {
        matches.add(
          _SearchResultMatch(
            item: item,
            matchReason: 'NOTE CONTENT',
            matchedSnippet: item.content,
          ),
        );
      }
    }

    return matches;
  }

  @override
  Widget build(BuildContext context) {
    final memoryProvider = Provider.of<MemoryProvider>(context);
    final results = _performSearch(memoryProvider.memories, _queryText);
    final bool hasQuery = _queryText.trim().length >= 2;
    final bool hasActiveFilters =
        _selectedType != 'All' ||
        _selectedCategory != 'All' ||
        _selectedDateRange != 'All Time' ||
        _favoritesOnly;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          onChanged: _onSearchChanged,
          onSubmitted: _submitSearch,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AtlasColors.textPrimary,
          ),
          decoration: const InputDecoration(
            hintText: 'Ask ATLAS or search anything...',
            hintStyle: TextStyle(
              color: Colors.black26,
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),
            border: InputBorder.none,
          ),
        ),
        actions: [
          if (_queryText.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_rounded, size: 18),
              onPressed: () {
                _searchController.clear();
                _onSearchChanged('');
              },
            ),
          IconButton(
            icon: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AtlasColors.purple, Colors.blueAccent],
              ).createShader(bounds),
              child: const Icon(
                Icons.mic_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            tooltip: 'Voice Search',
            onPressed: _openVoiceSearchDialog,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          // Multi-Dimensional Filter Bar
          _buildFilterScroll(),
          const Divider(height: 1, color: Colors.black12),

          Expanded(
            child: (!hasQuery && !hasActiveFilters)
                ? _buildEmptySearchState()
                : results.isEmpty
                ? _buildNoResultsState()
                : _buildSearchResultsList(results),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterScroll() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // 1. Type Pills
          _buildTypePill('All'),
          _buildTypePill('Screenshots', icon: Icons.image_rounded),
          _buildTypePill('Links', icon: Icons.link_rounded),
          _buildTypePill('Notes', icon: Icons.notes_rounded),
          _buildTypePill('PDFs', icon: Icons.picture_as_pdf_rounded),
          _buildTypePill('Voice', icon: Icons.mic_rounded),

          Container(
            width: 1,
            height: 20,
            color: Colors.grey.shade300,
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),

          // 2. Favorites Toggle
          _buildFavoritesPill(),

          Container(
            width: 1,
            height: 20,
            color: Colors.grey.shade300,
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),

          // 3. Date Range Filter
          _buildDateRangePill(),

          Container(
            width: 1,
            height: 20,
            color: Colors.grey.shade300,
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),

          // 4. Category Pills
          _buildCategoryPill('All'),
          _buildCategoryPill('Finance'),
          _buildCategoryPill('Recipes'),
          _buildCategoryPill('Travel'),
          _buildCategoryPill('Development'),
          _buildCategoryPill('Design Systems'),
          _buildCategoryPill('Shopping'),
          _buildCategoryPill('Work'),
          _buildCategoryPill('Reference'),
        ],
      ),
    );
  }

  Widget _buildTypePill(String type, {IconData? icon}) {
    final isSelected = _selectedType == type;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AtlasColors.blue : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 13,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                type,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFavoritesPill() {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => setState(() => _favoritesOnly = !_favoritesOnly),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _favoritesOnly ? AtlasColors.rose : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.favorite_rounded,
                size: 13,
                color: _favoritesOnly ? Colors.white : AtlasColors.rose,
              ),
              const SizedBox(width: 4),
              Text(
                'Favorites',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _favoritesOnly ? Colors.white : Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateRangePill() {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: PopupMenuButton<String>(
        onSelected: (val) => setState(() => _selectedDateRange = val),
        itemBuilder: (ctx) => [
          const PopupMenuItem(value: 'All Time', child: Text('All Time')),
          const PopupMenuItem(value: 'Today', child: Text('Today')),
          const PopupMenuItem(value: 'This Week', child: Text('This Week')),
          const PopupMenuItem(value: 'Past Month', child: Text('Past Month')),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _selectedDateRange != 'All Time'
                ? AtlasColors.purple
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 12,
                color: _selectedDateRange != 'All Time'
                    ? Colors.white
                    : Colors.grey.shade700,
              ),
              const SizedBox(width: 4),
              Text(
                _selectedDateRange,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _selectedDateRange != 'All Time'
                      ? Colors.white
                      : Colors.grey.shade800,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.arrow_drop_down_rounded,
                size: 16,
                color: _selectedDateRange != 'All Time'
                    ? Colors.white
                    : Colors.grey.shade700,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryPill(String cat) {
    final isSelected = _selectedCategory == cat;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => setState(() => _selectedCategory = cat),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AtlasColors.blueLight : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            cat,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : Colors.grey.shade800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySearchState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent Searches Section
          if (_recentSearches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Searches',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AtlasColors.blue,
                  ),
                ),
                TextButton(
                  onPressed: _clearRecentSearches,
                  child: const Text(
                    'Clear',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recentSearches.map((query) {
                return InkWell(
                  onTap: () {
                    _searchController.text = query;
                    _submitSearch(query);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          query,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
          ],

          // Semantic Suggestions Section
          const Text(
            'Suggested Searches',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AtlasColors.blue,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSuggestionChip('Recipe with paneer'),
              _buildSuggestionChip('Coffee bill receipt'),
              _buildSuggestionChip('Tokyo flight tickets'),
              _buildSuggestionChip('Flutter code snippet'),
              _buildSuggestionChip('UI color palette tokens'),
              _buildSuggestionChip('Wishlist shoes ₹2999'),
            ],
          ),
          const SizedBox(height: 32),

          // Overview Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AtlasColors.purple.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AtlasColors.purple.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AtlasColors.purple.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: AtlasColors.purple,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Full-Text & Semantic Intelligence',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AtlasColors.blue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Searches through screenshots, OCR text, notes, and AI summaries instantly.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                          height: 1.3,
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
    );
  }

  Widget _buildSuggestionChip(String query) {
    return InkWell(
      onTap: () {
        _searchController.text = query;
        _submitSearch(query);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AtlasColors.blue.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AtlasColors.blue.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_rounded, size: 14, color: AtlasColors.blue),
            const SizedBox(width: 6),
            Text(
              query,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AtlasColors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 52, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No memories matched "$_queryText"',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AtlasColors.blue,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try adjusting your filters, searching by category, or using natural language.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultsList(List<_SearchResultMatch> results) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Natural Language Search Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AtlasColors.purple, Colors.blueAccent],
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AtlasColors.surface,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text.rich(
                    TextSpan(
                      text: 'Found ${results.length} saved item(s) matching ',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AtlasColors.textPrimary,
                      ),
                      children: [
                        TextSpan(
                          text: _queryText.isNotEmpty
                              ? '"$_queryText"'
                              : 'active filters',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AtlasColors.blue,
                          ),
                        ),
                        const TextSpan(
                          text:
                              ' across AI summaries, extracted OCR text, and notes.',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Search Match Cards
          ...results.map((match) {
            final item = match.item;

            return Padding(
              padding: const EdgeInsets.only(bottom: 14.0),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AtlasColors.purple.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              match.matchReason,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AtlasColors.purple,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '• ${item.category}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
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
                                  : (item.imagePath != null &&
                                            item.imagePath!.isNotEmpty
                                        ? (item.imagePath!.startsWith('http')
                                              ? Image.network(
                                                  item.imagePath!,
                                                  fit: BoxFit.cover,
                                                )
                                              : Image.file(
                                                  File(item.imagePath!),
                                                  fit: BoxFit.cover,
                                                ))
                                        : Center(
                                            child: Icon(
                                              item.iconData,
                                              color: AtlasColors.blue,
                                              size: 22,
                                            ),
                                          )),
                            ),
                          ),
                          const SizedBox(width: 14),
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
                      if (match.matchedSnippet.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          child: Text(
                            match.matchedSnippet,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
