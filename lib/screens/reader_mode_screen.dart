import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/memory_item.dart';
import '../providers/memory_provider.dart';
import '../services/url_metadata_service.dart';
import '../theme/app_theme.dart';

enum ReaderThemeMode { light, sepia, dark }

class ReaderModeScreen extends StatefulWidget {
  final MemoryItem memory;

  const ReaderModeScreen({super.key, required this.memory});

  @override
  State<ReaderModeScreen> createState() => _ReaderModeScreenState();
}

class _ReaderModeScreenState extends State<ReaderModeScreen> {
  final ScrollController _scrollController = ScrollController();
  double _scrollProgress = 0.0;
  double _fontSize = 17.0;
  ReaderThemeMode _themeMode = ReaderThemeMode.light;

  UrlMetadata? _metadata;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateProgress);
    _loadArticleContent();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateProgress);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateProgress() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.offset;
    if (maxScroll > 0) {
      setState(() {
        _scrollProgress = (current / maxScroll).clamp(0.0, 1.0);
      });
    }
  }

  void _loadArticleContent() async {
    final url = widget.memory.url;
    if (url != null && url.isNotEmpty) {
      final data = await UrlMetadataService.instance.fetchMetadata(url);
      if (mounted) {
        setState(() {
          _metadata = data;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Color get _bgColor {
    switch (_themeMode) {
      case ReaderThemeMode.light:
        return const Color(0xFFFAFAFA);
      case ReaderThemeMode.sepia:
        return const Color(0xFFFBF0D9);
      case ReaderThemeMode.dark:
        return const Color(0xFF18181B);
    }
  }

  Color get _textColor {
    switch (_themeMode) {
      case ReaderThemeMode.light:
        return const Color(0xFF1E293B);
      case ReaderThemeMode.sepia:
        return const Color(0xFF451A03);
      case ReaderThemeMode.dark:
        return const Color(0xFFF1F5F9);
    }
  }

  Color get _subtextColor {
    switch (_themeMode) {
      case ReaderThemeMode.light:
        return Colors.grey.shade600;
      case ReaderThemeMode.sepia:
        return const Color(0xFF92400E);
      case ReaderThemeMode.dark:
        return const Color(0xFF94A3B8);
    }
  }

  Color get _headerBgColor {
    switch (_themeMode) {
      case ReaderThemeMode.light:
        return Colors.white;
      case ReaderThemeMode.sepia:
        return const Color(0xFFF4E5C4);
      case ReaderThemeMode.dark:
        return const Color(0xFF09090B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MemoryProvider>(context);
    final memory = widget.memory;

    final String title = _metadata?.title ?? memory.title;
    final String siteName = _metadata?.siteName ?? memory.sourceApp;
    final String content = _metadata?.articleBody ??
        (memory.content.isNotEmpty ? memory.content : memory.aiSummary);
    final int readingTime = _metadata?.readingTimeMinutes ?? 3;
    final String? bannerImage = _metadata?.imageUrl ?? memory.imagePath;

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _headerBgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: _textColor, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          siteName.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: _subtextColor,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        actions: [
          // Font size adjuster
          PopupMenuButton<double>(
            icon: Icon(Icons.format_size_rounded, color: _textColor, size: 20),
            onSelected: (size) => setState(() => _fontSize = size),
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 15.0, child: Text('Small (15pt)')),
              const PopupMenuItem(value: 17.0, child: Text('Default (17pt)')),
              const PopupMenuItem(value: 19.0, child: Text('Large (19pt)')),
              const PopupMenuItem(value: 22.0, child: Text('Extra Large (22pt)')),
            ],
          ),

          // Theme switcher
          PopupMenuButton<ReaderThemeMode>(
            icon: Icon(Icons.palette_outlined, color: _textColor, size: 20),
            onSelected: (mode) => setState(() => _themeMode = mode),
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: ReaderThemeMode.light,
                child: Row(
                  children: [
                    Icon(Icons.light_mode_rounded, size: 16, color: Colors.amber),
                    SizedBox(width: 8),
                    Text('Light Theme'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: ReaderThemeMode.sepia,
                child: Row(
                  children: [
                    Icon(Icons.menu_book_rounded, size: 16, color: Color(0xFFD97706)),
                    SizedBox(width: 8),
                    Text('Warm Sepia'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: ReaderThemeMode.dark,
                child: Row(
                  children: [
                    Icon(Icons.dark_mode_rounded, size: 16, color: Colors.indigoAccent),
                    SizedBox(width: 8),
                    Text('Dark Slate'),
                  ],
                ),
              ),
            ],
          ),

          // Favorite button
          IconButton(
            icon: Icon(
              memory.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: memory.isFavorite ? AtlasColors.rose : _textColor,
              size: 20,
            ),
            onPressed: () => provider.toggleFavorite(memory.id),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3.0),
          child: LinearProgressIndicator(
            value: _scrollProgress,
            backgroundColor: Colors.transparent,
            valueColor: const AlwaysStoppedAnimation<Color>(AtlasColors.blue),
            minHeight: 3.0,
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AtlasColors.blue),
                  const SizedBox(height: 16),
                  Text(
                    'Extracting clean article content...',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _subtextColor,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Site & Reading Time Pill
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AtlasColors.blue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          siteName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AtlasColors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•  $readingTime min read',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _subtextColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Article Title
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: _fontSize + 8,
                      fontWeight: FontWeight.w900,
                      color: _textColor,
                      height: 1.25,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // AI Brief Summary Highlight
                  if (memory.aiSummary.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AtlasColors.purple.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AtlasColors.purple.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            size: 18,
                            color: AtlasColors.purple,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              memory.aiSummary,
                              style: TextStyle(
                                fontSize: _fontSize - 2,
                                fontWeight: FontWeight.w600,
                                color: _textColor,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Optional Banner Image
                  if (bannerImage != null && bannerImage.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: bannerImage.startsWith('http')
                          ? Image.network(
                              bannerImage,
                              width: double.infinity,
                              height: 220,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                            )
                          : Image.file(
                              File(bannerImage),
                              width: double.infinity,
                              height: 220,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                            ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Formatted Article Body
                  SelectableText(
                    content,
                    style: TextStyle(
                      fontSize: _fontSize,
                      fontWeight: FontWeight.w400,
                      color: _textColor,
                      height: 1.75,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Bottom Action Bar
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _headerBgColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: content));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Article content copied to clipboard!')),
                              );
                            },
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            label: const Text('Copy Text'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade100,
                              foregroundColor: AtlasColors.blue,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        if (memory.url != null && memory.url!.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Opening ${memory.url}...')),
                                );
                              },
                              icon: const Icon(Icons.open_in_browser_rounded, size: 16),
                              label: const Text('Open Web'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AtlasColors.blue,
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}
