import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/memory_item.dart';

class MemoryProvider extends ChangeNotifier {
  bool _hasPhotoPermission = true;
  List<String> _permittedScreenshotIds = [];
  bool _isProcessingShare = false;
  String _processingTitle = "Understanding this...";
  String _processingSubtitle = "Extracting context and meaning.";
  bool _processingCompleted = false;

  // Real Device Screenshots from photo_manager
  List<AssetEntity> _deviceScreenshots = [];
  bool _isLoadingScreenshots = false;

  final List<MemoryItem> _memories = [
    MemoryItem(
      id: '1',
      title: 'Linear Design System',
      subtitle: 'linear.app/docs',
      sourceApp: 'Arc Browser',
      type: MemoryType.link,
      savedAt: DateTime.now().subtract(const Duration(hours: 2)),
      aiSummary: 'A comprehensive guide to Linear\'s minimalist interaction design. Focuses on high contrast typography, keyboard-first navigation, and using deep navy accents to guide user attention.',
      category: 'Design Systems',
      url: 'https://linear.app/docs',
      iconBgColor: const Color(0xFFEFF6FF),
      iconData: Icons.link_rounded,
    ),
    MemoryItem(
      id: '2',
      title: 'Recipe: Paneer Tikka',
      subtitle: 'Screenshot • Instagram',
      sourceApp: 'Instagram',
      type: MemoryType.screenshot,
      savedAt: DateTime.now().subtract(const Duration(days: 1)),
      aiSummary: 'Authentic paneer tikka recipe card. Key ingredients include paneer cubes, thick yogurt, Kashmiri red chili, and lemon juice.',
      category: 'Recipes',
      snippet: '...marinate paneer cubes in yogurt...',
      iconBgColor: const Color(0xFFECFDF5),
      iconData: Icons.restaurant_rounded,
    ),
    MemoryItem(
      id: '3',
      title: 'Tokyo Travel Flight Ideas',
      subtitle: 'Notes • Safari',
      sourceApp: 'Safari Browser',
      type: MemoryType.note,
      savedAt: DateTime.now().subtract(const Duration(days: 3)),
      aiSummary: 'Flight options and itinerary ideas for Tokyo trip in Autumn. Highlights Narita vs Haneda routes and bullet train passes.',
      category: 'Travel',
      iconBgColor: const Color(0xFFFFFBEB),
      iconData: Icons.flight_takeoff_rounded,
    ),
    MemoryItem(
      id: '4',
      title: 'Nike Air Max Wishlist',
      subtitle: 'Shoes under ₹3000 • Chrome',
      sourceApp: 'Chrome Browser',
      type: MemoryType.link,
      savedAt: DateTime.now().subtract(const Duration(days: 4)),
      aiSummary: 'Sneakers wishlist with price tracking alert set for seasonal sale discount.',
      category: 'Shopping',
      iconBgColor: const Color(0xFFFFF1F2),
      iconData: Icons.shopping_bag_rounded,
    ),
  ];

  final List<MemoryItem> _triageItems = [
    MemoryItem(
      id: 't1',
      title: 'Airbnb Booking Receipt.pdf',
      subtitle: 'Added from Downloads',
      sourceApp: 'Files',
      type: MemoryType.pdf,
      savedAt: DateTime.now().subtract(const Duration(hours: 5)),
      aiSummary: 'Booking confirmation document for stay in Goa.',
      category: 'Uncategorized',
      iconBgColor: const Color(0xFFF3F4F6),
      iconData: Icons.picture_as_pdf_rounded,
    ),
    MemoryItem(
      id: 't2',
      title: 'React Native vs Flutter Comparison',
      subtitle: 'Copied Text • Medium',
      sourceApp: 'Medium',
      type: MemoryType.note,
      savedAt: DateTime.now().subtract(const Duration(hours: 12)),
      aiSummary: 'Comparison breakdown highlighting performance and UI fidelity differences.',
      category: 'Uncategorized',
      iconBgColor: const Color(0xFFF5F3FF),
      iconData: Icons.description_rounded,
    ),
  ];

  final List<Map<String, dynamic>> _availableScreenshots = [
    {
      'id': 'shot_1',
      'title': 'Restaurant Bill Receipt',
      'label': 'Finance',
      'date': 'Today, 2:30 PM',
      'color': 0xFF3B82F6,
    },
    {
      'id': 'shot_2',
      'title': 'Design System Color Palette',
      'label': 'Design Systems',
      'date': 'Today, 11:15 AM',
      'color': 0xFF9333EA,
    },
    {
      'id': 'shot_3',
      'title': 'Flight Ticket Confirmation',
      'label': 'Travel',
      'date': 'Yesterday, 9:00 PM',
      'color': 0xFFF59E0B,
    },
    {
      'id': 'shot_4',
      'title': 'Python Code Snippet',
      'label': 'Development',
      'date': 'Yesterday, 4:20 PM',
      'color': 0xFF6366F1,
    },
  ];

  MemoryProvider() {
    _loadPreferences();
    loadDeviceScreenshots();
  }

  bool get hasPhotoPermission => _hasPhotoPermission;
  List<MemoryItem> get memories => _memories;
  List<MemoryItem> get triageItems => _triageItems;
  List<Map<String, dynamic>> get availableScreenshots => _availableScreenshots;
  List<AssetEntity> get deviceScreenshots => _deviceScreenshots;
  bool get isLoadingScreenshots => _isLoadingScreenshots;
  List<String> get permittedScreenshotIds => _permittedScreenshotIds;
  bool get isProcessingShare => _isProcessingShare;
  String get processingTitle => _processingTitle;
  String get processingSubtitle => _processingSubtitle;
  bool get processingCompleted => _processingCompleted;

  void togglePhotoPermission(bool value) {
    _hasPhotoPermission = value;
    _savePreferences();
    if (value) {
      loadDeviceScreenshots();
    }
    notifyListeners();
  }

  void _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hasPhotoPermission = prefs.getBool('hasPhotoPermission') ?? true;
      _permittedScreenshotIds = prefs.getStringList('permittedScreenshotIds') ?? [];
      
      final savedMemoriesJson = prefs.getString('saved_custom_memories');
      if (savedMemoriesJson != null) {
        final List list = jsonDecode(savedMemoriesJson);
        for (var itemMap in list) {
          final String id = itemMap['id'] ?? '';
          if (!_memories.any((m) => m.id == id)) {
            _memories.insert(
              0,
              MemoryItem(
                id: id,
                title: itemMap['title'] ?? 'Saved Screenshot',
                subtitle: itemMap['subtitle'] ?? 'Screenshot • Gallery',
                sourceApp: itemMap['sourceApp'] ?? 'Photos',
                type: MemoryType.screenshot,
                savedAt: DateTime.tryParse(itemMap['savedAt'] ?? '') ?? DateTime.now(),
                aiSummary: itemMap['aiSummary'] ?? 'Saved screenshot in ATLAS Memory Space.',
                category: itemMap['category'] ?? 'Screenshots',
                imagePath: itemMap['imagePath'],
                iconBgColor: Color(itemMap['iconBgColor'] ?? 0xFFECFDF5),
                iconData: _getIconData(itemMap['iconDataCode']),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Error restoring saved memories: $e");
    }
    notifyListeners();
  }

  void _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasPhotoPermission', _hasPhotoPermission);
      await prefs.setStringList('permittedScreenshotIds', _permittedScreenshotIds);

      final customList = _memories
          .where((m) => m.id.startsWith('real_shot_') || m.id.startsWith('shot_mem_'))
          .map((m) => {
                'id': m.id,
                'title': m.title,
                'subtitle': m.subtitle,
                'sourceApp': m.sourceApp,
                'savedAt': m.savedAt.toIso8601String(),
                'aiSummary': m.aiSummary,
                'category': m.category,
                'imagePath': m.imagePath,
                'iconBgColor': m.iconBgColor.value,
                'iconDataCode': m.iconData.codePoint,
              })
          .toList();

      await prefs.setString('saved_custom_memories', jsonEncode(customList));
    } catch (e) {
      debugPrint("Error saving preferences: $e");
    }
  }

  IconData _getIconData(int? codePoint) {
    if (codePoint == Icons.receipt_long_rounded.codePoint) return Icons.receipt_long_rounded;
    if (codePoint == Icons.restaurant_rounded.codePoint) return Icons.restaurant_rounded;
    if (codePoint == Icons.flight_takeoff_rounded.codePoint) return Icons.flight_takeoff_rounded;
    if (codePoint == Icons.palette_rounded.codePoint) return Icons.palette_rounded;
    if (codePoint == Icons.code_rounded.codePoint) return Icons.code_rounded;
    return Icons.image_rounded;
  }

  Map<String, dynamic> _analyzeScreenshotContent(String rawTitle, String? filePath) {
    final text = (rawTitle + ' ' + (filePath ?? '')).toLowerCase();

    if (text.contains('bill') || text.contains('receipt') || text.contains('pay') || text.contains('bank') || text.contains('money') || text.contains('rupee') || text.contains('dollar')) {
      return {
        'category': 'Finance',
        'title': rawTitle.contains('Screenshot') ? 'Transaction Receipt' : rawTitle,
        'aiSummary': 'Parsed financial receipt and transaction details. Automatically indexed under Finance.',
        'iconData': Icons.receipt_long_rounded,
        'iconBgColor': const Color(0xFFEFF6FF),
      };
    } else if (text.contains('food') || text.contains('recipe') || text.contains('dish') || text.contains('cook') || text.contains('paneer') || text.contains('pizza') || text.contains('meal')) {
      return {
        'category': 'Recipes',
        'title': rawTitle.contains('Screenshot') ? 'Food & Cooking Recipe' : rawTitle,
        'aiSummary': 'Detected recipe ingredients and cooking steps. Automatically indexed under Recipes.',
        'iconData': Icons.restaurant_rounded,
        'iconBgColor': const Color(0xFFECFDF5),
      };
    } else if (text.contains('flight') || text.contains('ticket') || text.contains('hotel') || text.contains('airbnb') || text.contains('trip') || text.contains('goa') || text.contains('tokyo') || text.contains('travel')) {
      return {
        'category': 'Travel',
        'title': rawTitle.contains('Screenshot') ? 'Travel Pass & Itinerary' : rawTitle,
        'aiSummary': 'Identified travel booking itinerary and flight confirmation. Automatically indexed under Travel.',
        'iconData': Icons.flight_takeoff_rounded,
        'iconBgColor': const Color(0xFFFFFBEB),
      };
    } else if (text.contains('design') || text.contains('color') || text.contains('ui') || text.contains('figma') || text.contains('palette') || text.contains('font') || text.contains('logo')) {
      return {
        'category': 'Design Systems',
        'title': rawTitle.contains('Screenshot') ? 'UI Design Inspiration' : rawTitle,
        'aiSummary': 'Extracted UI components, color tokens, and layout ideas. Automatically indexed under Design Systems.',
        'iconData': Icons.palette_rounded,
        'iconBgColor': const Color(0xFFF3E8FF),
      };
    } else if (text.contains('code') || text.contains('python') || text.contains('flutter') || text.contains('dev') || text.contains('git') || text.contains('script') || text.contains('bug')) {
      return {
        'category': 'Development',
        'title': rawTitle.contains('Screenshot') ? 'Code & Tech Snippet' : rawTitle,
        'aiSummary': 'Extracted programming code snippet and technical reference notes. Automatically indexed under Development.',
        'iconData': Icons.code_rounded,
        'iconBgColor': const Color(0xFFEEF2FF),
      };
    } else {
      return {
        'category': 'Reference',
        'title': rawTitle,
        'aiSummary': 'Analyzed screenshot content. Automatically indexed and saved into ATLAS Memory Space.',
        'iconData': Icons.image_rounded,
        'iconBgColor': const Color(0xFFF8FAFC),
      };
    }
  }

  Future<void> loadDeviceScreenshots() async {
    _isLoadingScreenshots = true;
    notifyListeners();

    try {
      final PermissionState ps = await PhotoManager.requestPermissionExtend();
      if (ps.isAuth || ps.hasAccess) {
        _hasPhotoPermission = true;

        final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
          type: RequestType.image,
          hasAll: true,
        );

        if (paths.isNotEmpty) {
          AssetPathEntity targetAlbum = paths.firstWhere(
            (path) => path.name.toLowerCase().contains('screenshot'),
            orElse: () => paths.first,
          );

          final List<AssetEntity> entities = await targetAlbum.getAssetListPaged(
            page: 0,
            size: 40,
          );

          _deviceScreenshots = entities;
        }
      } else {
        _hasPhotoPermission = false;
      }
    } catch (e) {
      debugPrint("Error fetching real device screenshots: $e");
    }

    _isLoadingScreenshots = false;
    notifyListeners();
  }

  Future<void> grantRealScreenshotAccess(List<AssetEntity> selectedEntities) async {
    for (AssetEntity entity in selectedEntities) {
      try {
        if (!_permittedScreenshotIds.contains(entity.id)) {
          _permittedScreenshotIds.add(entity.id);

          final file = await entity.file;
          final filePath = file?.path;

          final rawTitle = 'Screenshot (${entity.createDateTime.day}/${entity.createDateTime.month})';
          final analysis = _analyzeScreenshotContent(rawTitle, filePath);

          _memories.insert(
            0,
            MemoryItem(
              id: 'real_shot_${entity.id}',
              title: analysis['title'],
              subtitle: 'Device Gallery • ${analysis['category']}',
              sourceApp: 'Photos',
              type: MemoryType.screenshot,
              savedAt: entity.createDateTime,
              aiSummary: analysis['aiSummary'],
              category: analysis['category'],
              imagePath: filePath,
              iconBgColor: analysis['iconBgColor'],
              iconData: analysis['iconData'],
            ),
          );
        }
      } catch (e) {
        debugPrint("Error processing entity ${entity.id}: $e");
      }
    }
    _savePreferences();
    notifyListeners();
  }

  void grantScreenshotAccess(List<String> selectedIds) {
    for (String id in selectedIds) {
      try {
        if (!_permittedScreenshotIds.contains(id)) {
          _permittedScreenshotIds.add(id);

          final shot = _availableScreenshots.firstWhere(
            (element) => element['id'] == id,
            orElse: () => {'title': 'Screenshot Memory', 'label': 'Reference'},
          );

          final String rawTitle = shot['title'];
          final analysis = _analyzeScreenshotContent(rawTitle, null);

          _memories.insert(
            0,
            MemoryItem(
              id: 'shot_mem_${DateTime.now().millisecondsSinceEpoch}',
              title: analysis['title'],
              subtitle: 'Screenshot • ${analysis['category']}',
              sourceApp: 'Photos',
              type: MemoryType.screenshot,
              savedAt: DateTime.now(),
              aiSummary: analysis['aiSummary'],
              category: analysis['category'],
              iconBgColor: analysis['iconBgColor'],
              iconData: analysis['iconData'],
            ),
          );
        }
      } catch (e) {
        debugPrint("Error processing mock screenshot $id: $e");
      }
    }
    _savePreferences();
    notifyListeners();
  }

  void resolveTriageItem(String id, String category) {
    final index = _triageItems.indexWhere((item) => item.id == id);
    if (index != -1) {
      final item = _triageItems.removeAt(index);
      _memories.insert(
        0,
        MemoryItem(
          id: item.id,
          title: item.title,
          subtitle: item.subtitle,
          sourceApp: item.sourceApp,
          type: item.type,
          savedAt: item.savedAt,
          aiSummary: item.aiSummary,
          category: category,
          url: item.url,
          iconBgColor: item.iconBgColor,
          iconData: item.iconData,
        ),
      );
      notifyListeners();
    }
  }

  void simulateShareProcessing({required String titleText, required VoidCallback onDone}) async {
    _isProcessingShare = true;
    _processingCompleted = false;
    _processingTitle = "Understanding this...";
    _processingSubtitle = "Extracting context and meaning.";
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 1500));
    _processingTitle = "Finding what matters...";
    _processingSubtitle = "Connecting to your knowledge graph.";
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 1500));
    _processingTitle = "Saved.";
    _processingSubtitle = "You'll always find it later in ATLAS.";
    _processingCompleted = true;

    _memories.insert(
      0,
      MemoryItem(
        id: 'shared_${DateTime.now().millisecondsSinceEpoch}',
        title: titleText.isNotEmpty ? titleText : 'Shared Content from External App',
        subtitle: 'Shared via Send To • Just Now',
        sourceApp: 'Shared Intent',
        type: MemoryType.link,
        savedAt: DateTime.now(),
        aiSummary: 'Content received via system Send To list. Extracted links and text content.',
        category: 'Shared',
        iconBgColor: const Color(0xFFEFF6FF),
        iconData: Icons.share_rounded,
      ),
    );

    notifyListeners();
  }

  void resetShareProcessing() {
    _isProcessingShare = false;
    _processingCompleted = false;
    notifyListeners();
  }
}
