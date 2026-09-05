import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/collection_item.dart';
import '../models/memory_item.dart';
import '../services/ai_intelligence_service.dart';
import '../services/firebase_sync_service.dart';
import '../services/local_database_service.dart';
import '../services/ocr_service.dart';
import '../services/url_metadata_service.dart';

class MemoryProvider extends ChangeNotifier {
  bool _hasPhotoPermission = true;
  List<String> _permittedScreenshotIds = [];
  bool _isProcessingShare = false;
  String _processingTitle = "Understanding this...";
  String _processingSubtitle = "Extracting context and meaning.";
  bool _processingCompleted = false;

  List<SharedMediaFile> _pendingFiles = [];
  String _pendingQuickNote = '';

  // Real Device Screenshots from photo_manager
  List<AssetEntity> _deviceScreenshots = [];
  bool _isLoadingScreenshots = false;

  List<MemoryItem> _memories = [];
  List<MemoryItem> _favoriteMemories = [];
  List<MemoryItem> _archivedMemories = [];
  List<MemoryItem> _trashMemories = [];
  List<MemoryItem> _triageItems = [];
  List<MemoryCollection> _collections = [];

  CloudSyncState _syncState = CloudSyncState.offline;
  StreamSubscription? _syncStateSub;

  final List<MemoryItem> _defaultSeedMemories = [
    MemoryItem(
      id: 'seed_1',
      title: 'Linear Design System',
      subtitle: 'linear.app/docs',
      sourceApp: 'Arc Browser',
      type: MemoryType.link,
      savedAt: DateTime.now().subtract(const Duration(hours: 2)),
      aiSummary:
          'A comprehensive guide to Linear\'s minimalist interaction design. Focuses on high contrast typography, keyboard-first navigation, and using deep navy accents to guide user attention.',
      category: 'Design Systems',
      url: 'https://linear.app/docs',
      extractedText:
          'Linear Design System documentation and token reference. Color tokens: Primary #0B192C, Accent #8B5CF6.',
      structuredEntities: {
        'type': 'design',
        'palette': ['#0B192C', '#8B5CF6', '#10B981', '#F8FAFC'],
        'typography': 'Outfit, Inter',
      },
      tags: ['design', 'linear', 'ui', 'tokens'],
      iconBgColor: const Color(0xFFEFF6FF),
      iconData: Icons.link_rounded,
    ),
    MemoryItem(
      id: 'seed_2',
      title: 'Recipe: Paneer Tikka',
      subtitle: 'Screenshot • Instagram',
      sourceApp: 'Instagram',
      type: MemoryType.screenshot,
      savedAt: DateTime.now().subtract(const Duration(days: 1)),
      aiSummary:
          'Authentic paneer tikka recipe card. Key ingredients include paneer cubes, thick yogurt, Kashmiri red chili, and lemon juice.',
      category: 'Recipes',
      snippet: '...marinate paneer cubes in yogurt...',
      extractedText:
          'Recipe: Authentic Paneer Tikka\nPrep Time: 20 mins | Cook Time: 15 mins | Servings: 4\nIngredients:\n• 250g Fresh Paneer cubes\n• 1/2 cup Greek yogurt\n• 1 tbsp Kashmiri red chili\n• 1 tbsp Ginger-garlic paste\n• 1 tsp Garam masala\nInstructions: Coat paneer cubes and marinate for 30 minutes. Grill or air-fry at 200°C for 15 minutes.',
      structuredEntities: {
        'type': 'recipe',
        'recipeTitle': 'Authentic Paneer Tikka',
        'prepTime': '20 mins',
        'cookTime': '15 mins',
        'servings': '4',
        'ingredients': [
          '250g Fresh Paneer cubes',
          '1/2 cup Greek yogurt (hung curd)',
          '1 tbsp Kashmiri red chili powder',
          '1 tbsp Ginger-garlic paste',
          '1 tsp Garam masala & Kasuri methi',
          '1 tbsp Mustard oil & Lemon juice',
        ],
        'instructions': [
          'Whisk yogurt with spices and garlic paste.',
          'Coat paneer cubes generously and marinate for 30 minutes.',
          'Grill or air-fry at 200°C for 12-15 minutes until charred.',
        ],
      },
      tags: ['recipes', 'food', 'cooking', 'paneer_tikka'],
      iconBgColor: const Color(0xFFECFDF5),
      iconData: Icons.restaurant_rounded,
    ),
    MemoryItem(
      id: 'seed_3',
      title: 'Tokyo Travel Flight Ideas',
      subtitle: 'Notes • Safari',
      sourceApp: 'Safari Browser',
      type: MemoryType.note,
      savedAt: DateTime.now().subtract(const Duration(days: 3)),
      aiSummary:
          'Flight options and itinerary ideas for Tokyo trip in Autumn. Highlights Narita vs Haneda routes and bullet train passes.',
      category: 'Travel',
      extractedText:
          'Flight: 6E-2042 (IndiGo)\nRoute: DEL ➔ HND\nPNR: G7XP9Q\nTravel Date: 15 Oct 2026\nSeat: 12F',
      structuredEntities: {
        'type': 'travel',
        'flightNumber': '6E-2042',
        'airline': 'IndiGo',
        'route': 'DEL ➔ HND (Tokyo)',
        'departureAirport': 'DEL (Delhi)',
        'arrivalAirport': 'HND (Haneda Tokyo)',
        'bookingRef': 'G7XP9Q',
        'travelDate': '15 Oct 2026',
        'seat': '12F',
      },
      tags: ['travel', 'flight', 'tokyo', 'japan'],
      iconBgColor: const Color(0xFFFFFBEB),
      iconData: Icons.flight_takeoff_rounded,
    ),
    MemoryItem(
      id: 'seed_4',
      title: 'Nike Air Max Wishlist',
      subtitle: 'Shoes under ₹3000 • Chrome',
      sourceApp: 'Chrome Browser',
      type: MemoryType.link,
      savedAt: DateTime.now().subtract(const Duration(days: 4)),
      aiSummary:
          'Sneakers wishlist with price tracking alert set for seasonal sale discount.',
      category: 'Shopping',
      extractedText:
          'Nike Air Max Sneakers. Discounted price: ₹2,999 on Nike Official Store.',
      structuredEntities: {
        'type': 'shopping',
        'product': 'Nike Air Max Sneakers',
        'price': '₹2,999',
        'store': 'Nike Store',
      },
      tags: ['shopping', 'wishlist', 'nike'],
      iconBgColor: const Color(0xFFFFF1F2),
      iconData: Icons.shopping_bag_rounded,
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
    _initDatabaseAndServices();
    _loadPreferences();
    loadDeviceScreenshots();
  }

  bool get hasPhotoPermission => _hasPhotoPermission;
  List<MemoryItem> get memories => _memories;
  List<MemoryItem> get favoriteMemories => _favoriteMemories;
  List<MemoryItem> get archivedMemories => _archivedMemories;
  List<MemoryItem> get trashMemories => _trashMemories;
  List<MemoryItem> get triageItems => _triageItems;
  List<MemoryCollection> get collections => _collections;
  List<Map<String, dynamic>> get availableScreenshots => _availableScreenshots
      .where((s) => !_permittedScreenshotIds.contains(s['id']))
      .toList();
  List<AssetEntity> get deviceScreenshots => _deviceScreenshots
      .where((e) => !_permittedScreenshotIds.contains(e.id))
      .toList();
  bool get isLoadingScreenshots => _isLoadingScreenshots;
  List<String> get permittedScreenshotIds => _permittedScreenshotIds;
  bool get isProcessingShare => _isProcessingShare;
  String get processingTitle => _processingTitle;
  String get processingSubtitle => _processingSubtitle;
  bool get processingCompleted => _processingCompleted;
  CloudSyncState get syncState => _syncState;
  DateTime? get lastSyncedAt => FirebaseSyncService.instance.lastSyncedAt;

  final List<MemoryCollection> _defaultSeedCollections = [
    MemoryCollection(
      id: 'col_japan_2026',
      title: 'Japan Trip 2026',
      description:
          'Flight tickets, JR pass, hotel bookings, and travel itinerary.',
      color: const Color(0xFF2563EB),
      icon: Icons.flight_takeoff_rounded,
      itemIds: ['seed_3'],
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    MemoryCollection(
      id: 'col_startup',
      title: 'Startup & Tech Architecture',
      description: 'System whitepapers, UI design systems, and code notes.',
      color: const Color(0xFF0F172A),
      icon: Icons.lightbulb_rounded,
      itemIds: ['seed_1'],
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    MemoryCollection(
      id: 'smart_voice',
      title: 'Voice Notes & Audio',
      description: 'Dynamic smart album containing all voice recordings.',
      color: const Color(0xFF475569),
      icon: Icons.mic_rounded,
      isSmart: true,
      smartRule: 'type:audio',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    MemoryCollection(
      id: 'smart_receipts',
      title: 'Finance & Bills',
      description:
          'Auto-aggregates payment receipts, cafe bills, and invoices.',
      color: const Color(0xFF10B981),
      icon: Icons.receipt_long_rounded,
      isSmart: true,
      smartRule: 'category:Finance',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    MemoryCollection(
      id: 'smart_recipes',
      title: 'Culinary Recipes',
      description: 'Smart album gathering ingredient checklists and recipes.',
      color: const Color(0xFFF59E0B),
      icon: Icons.restaurant_menu_rounded,
      isSmart: true,
      smartRule: 'category:Recipes',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
  ];

  Future<void> _initDatabaseAndServices() async {
    final db = LocalDatabaseService.instance;
    await db.seedInitialDataIfEmpty(_defaultSeedMemories);
    await db.seedDefaultCollectionsIfEmpty(_defaultSeedCollections);
    await reloadMemoriesFromDb();

    // Init triage items
    _triageItems = [
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
        aiSummary:
            'Comparison breakdown highlighting performance and UI fidelity differences.',
        category: 'Uncategorized',
        iconBgColor: const Color(0xFFF5F3FF),
        iconData: Icons.description_rounded,
      ),
    ];

    // Initialize Firebase
    final fb = FirebaseSyncService.instance;
    _syncState = fb.syncState;
    _syncStateSub = fb.syncStateStream.listen((state) {
      _syncState = state;
      notifyListeners();
    });

    await fb.initialize();
    fb.startRealtimeSync(
      onLocalDataChanged: (updated) {
        _memories = updated;
        _reloadAuxiliaryLists();
        notifyListeners();
      },
    );

    // Initial background sync
    syncNow();
  }

  Future<void> reloadMemoriesFromDb() async {
    final db = LocalDatabaseService.instance;
    _memories = await db.getActiveMemories();
    _favoriteMemories = await db.getFavoriteMemories();
    _archivedMemories = await db.getArchivedMemories();
    _trashMemories = await db.getTrashMemories();
    _collections = await db.getAllCollections();
    notifyListeners();
  }

  Future<void> _reloadAuxiliaryLists() async {
    final db = LocalDatabaseService.instance;
    _favoriteMemories = await db.getFavoriteMemories();
    _archivedMemories = await db.getArchivedMemories();
    _trashMemories = await db.getTrashMemories();
  }

  Future<void> syncNow() async {
    await FirebaseSyncService.instance.syncWithCloud(
      onLocalDataChanged: (updated) {
        _memories = updated;
        _reloadAuxiliaryLists();
        notifyListeners();
      },
    );
  }

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
      _permittedScreenshotIds =
          prefs.getStringList('permittedScreenshotIds') ?? [];
    } catch (e) {
      debugPrint("Error restoring preferences: $e");
    }
    notifyListeners();
  }

  void _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasPhotoPermission', _hasPhotoPermission);
      await prefs.setStringList(
        'permittedScreenshotIds',
        _permittedScreenshotIds,
      );
    } catch (e) {
      debugPrint("Error saving preferences: $e");
    }
  }

  // --- CRUD Engine Operations ---

  Future<void> addMemoryManually({
    required String content,
    String? url,
    String category = 'Uncategorized',
    List<String> tags = const [],
  }) async {
    final trimmed = content.trim();
    final trimmedUrl = url?.trim() ?? '';
    final isLink = trimmedUrl.isNotEmpty;

    UrlMetadata? urlMeta;
    if (isLink) {
      urlMeta = await UrlMetadataService.instance.fetchMetadata(trimmedUrl);
    }

    // Run AI Semantic Intelligence on the content & OpenGraph metadata
    final combinedForAi = isLink
        ? '${urlMeta?.title ?? ''} ${urlMeta?.description ?? ''} $trimmed'
        : trimmed;

    final aiResult = await AiIntelligenceService.instance.analyzeContent(
      text: combinedForAi,
      url: isLink ? trimmedUrl : null,
      type: isLink ? MemoryType.link : MemoryType.note,
    );

    final resolvedCategory = category != 'Uncategorized'
        ? category
        : aiResult.category;
    final resolvedTags = tags.isNotEmpty ? tags : aiResult.tags;

    final resolvedTitle = isLink
        ? (urlMeta?.title.isNotEmpty == true
              ? urlMeta!.title
              : _linkTitle(trimmedUrl))
        : (trimmed.isNotEmpty ? _textTitle(trimmed) : aiResult.suggestedTitle);

    final item = MemoryItem(
      id: 'manual_${DateTime.now().microsecondsSinceEpoch}',
      title: resolvedTitle,
      subtitle: isLink ? (urlMeta?.siteName ?? trimmedUrl) : 'Note • Just Now',
      sourceApp: isLink ? (urlMeta?.siteName ?? 'Web') : 'Atlas',
      type: isLink ? MemoryType.link : MemoryType.note,
      savedAt: DateTime.now(),
      aiSummary: aiResult.aiSummary,
      category: resolvedCategory,
      url: isLink ? trimmedUrl : null,
      imagePath: urlMeta?.imageUrl,
      snippet: isLink
          ? (urlMeta?.description.isNotEmpty == true
                ? urlMeta!.description
                : trimmed)
          : null,
      content: urlMeta?.articleBody ?? trimmed,
      extractedText: trimmed.isNotEmpty ? trimmed : null,
      structuredEntities: aiResult.structuredEntities,
      tags: resolvedTags,
      syncStatus: SyncStatus.pendingUpload,
      iconBgColor: aiResult.iconBgColor,
      iconData: aiResult.iconData,
    );

    await LocalDatabaseService.instance.insertMemory(item);
    await reloadMemoriesFromDb();
    syncNow();
  }

  Future<void> addVoiceMemory({
    required String transcript,
    required Duration duration,
    String? title,
    String? audioPath,
    String category = 'Uncategorized',
    List<String> tags = const [],
  }) async {
    final cleanTranscript = transcript.trim();
    final aiResult = await AiIntelligenceService.instance.analyzeContent(
      text: cleanTranscript,
      title: title,
      type: MemoryType.audio,
    );

    final durationSec = duration.inSeconds;
    final minutes = durationSec ~/ 60;
    final seconds = durationSec % 60;
    final durationStr =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    final resolvedCategory = category != 'Uncategorized'
        ? category
        : aiResult.category;
    final resolvedTags = tags.isNotEmpty ? tags : aiResult.tags;
    final resolvedTitle = title != null && title.trim().isNotEmpty
        ? title.trim()
        : aiResult.suggestedTitle;

    final resolvedSubtitle = cleanTranscript.isNotEmpty
        ? 'Voice Note ($durationStr) • ${cleanTranscript.length > 50 ? "${cleanTranscript.substring(0, 47)}..." : cleanTranscript}'
        : 'Voice Note ($durationStr) • Just Now';

    final resolvedAiSummary = aiResult.aiSummary.isNotEmpty
        ? aiResult.aiSummary
        : cleanTranscript;

    final item = MemoryItem(
      id: 'voice_${DateTime.now().microsecondsSinceEpoch}',
      title: resolvedTitle,
      subtitle: resolvedSubtitle,
      sourceApp: 'Voice Recorder',
      type: MemoryType.audio,
      savedAt: DateTime.now(),
      aiSummary: resolvedAiSummary,
      category: resolvedCategory,
      imagePath: audioPath,
      snippet: cleanTranscript,
      content: cleanTranscript,
      extractedText: cleanTranscript,
      structuredEntities: {
        'audioDurationSeconds': durationSec,
        'audioDurationFormatted': durationStr,
        if (audioPath != null) ...{'audioPath': audioPath},
        ...?aiResult.structuredEntities,
      },
      tags: resolvedTags,
      syncStatus: SyncStatus.pendingUpload,
      iconBgColor: aiResult.iconBgColor,
      iconData: aiResult.iconData,
    );

    await LocalDatabaseService.instance.insertMemory(item);
    await reloadMemoriesFromDb();
    syncNow();
  }

  Future<void> addDocumentMemory({
    required String title,
    required String content,
    required String fileName,
    int pageCount = 1,
    String category = 'Uncategorized',
    List<String> tags = const [],
  }) async {
    final cleanContent = content.trim();
    final aiResult = await AiIntelligenceService.instance.analyzeContent(
      text: cleanContent,
      title: title,
      type: MemoryType.pdf,
    );

    final resolvedCategory = category != 'Uncategorized'
        ? category
        : aiResult.category;
    final resolvedTags = tags.isNotEmpty ? tags : aiResult.tags;
    final resolvedTitle = title.trim().isNotEmpty
        ? title.trim()
        : aiResult.suggestedTitle;

    final item = MemoryItem(
      id: 'doc_${DateTime.now().microsecondsSinceEpoch}',
      title: resolvedTitle,
      subtitle: 'PDF Document ($pageCount pgs) • Just Now',
      sourceApp: 'Files',
      type: MemoryType.pdf,
      savedAt: DateTime.now(),
      aiSummary: aiResult.aiSummary,
      category: resolvedCategory,
      snippet: cleanContent.length > 150
          ? '${cleanContent.substring(0, 147)}...'
          : cleanContent,
      content: cleanContent,
      extractedText: cleanContent,
      structuredEntities: {
        'fileName': fileName,
        'pageCount': pageCount,
        ...?aiResult.structuredEntities,
      },
      tags: resolvedTags,
      syncStatus: SyncStatus.pendingUpload,
      iconBgColor: aiResult.iconBgColor,
      iconData: aiResult.iconData,
    );

    await LocalDatabaseService.instance.insertMemory(item);
    await reloadMemoriesFromDb();
    syncNow();
  }

  Future<void> updateMemory(MemoryItem updatedItem) async {
    await LocalDatabaseService.instance.updateMemory(updatedItem);
    await reloadMemoriesFromDb();
    syncNow();
  }

  Future<void> softDeleteMemory(String id) async {
    await LocalDatabaseService.instance.softDeleteMemory(id);
    await reloadMemoriesFromDb();
    syncNow();
  }

  Future<void> restoreMemory(String id) async {
    await LocalDatabaseService.instance.restoreMemory(id);
    await reloadMemoriesFromDb();
    syncNow();
  }

  Future<void> permanentDeleteMemory(String id) async {
    await LocalDatabaseService.instance.permanentDeleteMemory(id);
    await reloadMemoriesFromDb();
    syncNow();
  }

  Future<void> toggleFavorite(String id) async {
    final itemIndex = _memories.indexWhere((m) => m.id == id);
    bool currentFav = false;
    if (itemIndex != -1) {
      currentFav = _memories[itemIndex].isFavorite;
    } else {
      final favIndex = _favoriteMemories.indexWhere((m) => m.id == id);
      if (favIndex != -1) currentFav = true;
    }

    await LocalDatabaseService.instance.toggleFavorite(id, !currentFav);
    await reloadMemoriesFromDb();
    syncNow();
  }

  Future<void> toggleArchive(String id) async {
    final itemIndex = _memories.indexWhere((m) => m.id == id);
    bool currentArch = false;
    if (itemIndex != -1) {
      currentArch = _memories[itemIndex].isArchived;
    } else {
      final archIndex = _archivedMemories.indexWhere((m) => m.id == id);
      if (archIndex != -1) currentArch = true;
    }

    await LocalDatabaseService.instance.toggleArchive(id, !currentArch);
    await reloadMemoriesFromDb();
    syncNow();
  }

  Future<void> emptyTrash() async {
    await LocalDatabaseService.instance.emptyTrash();
    await reloadMemoriesFromDb();
    syncNow();
  }

  // --- Collections Engine ---

  Future<void> createCollection({
    required String title,
    required String description,
    Color color = const Color(0xFF0F172A),
    IconData icon = Icons.folder_rounded,
  }) async {
    final collection = MemoryCollection(
      id: 'col_${DateTime.now().millisecondsSinceEpoch}',
      title: title.trim(),
      description: description.trim(),
      color: color,
      icon: icon,
      itemIds: [],
      createdAt: DateTime.now(),
    );
    await LocalDatabaseService.instance.insertCollection(collection);
    _collections = await LocalDatabaseService.instance.getAllCollections();
    notifyListeners();
  }

  Future<void> deleteCollection(String collectionId) async {
    await LocalDatabaseService.instance.deleteCollection(collectionId);
    _collections = await LocalDatabaseService.instance.getAllCollections();
    notifyListeners();
  }

  Future<void> addMemoryToCollection(
    String memoryId,
    String collectionId,
  ) async {
    final index = _collections.indexWhere((c) => c.id == collectionId);
    if (index != -1) {
      final col = _collections[index];
      if (!col.itemIds.contains(memoryId)) {
        final updatedList = List<String>.from(col.itemIds)..add(memoryId);
        final updatedCol = col.copyWith(itemIds: updatedList);
        await LocalDatabaseService.instance.updateCollection(updatedCol);
        _collections = await LocalDatabaseService.instance.getAllCollections();
        notifyListeners();
      }
    }
  }

  Future<void> removeMemoryFromCollection(
    String memoryId,
    String collectionId,
  ) async {
    final index = _collections.indexWhere((c) => c.id == collectionId);
    if (index != -1) {
      final col = _collections[index];
      if (col.itemIds.contains(memoryId)) {
        final updatedList = List<String>.from(col.itemIds)..remove(memoryId);
        final updatedCol = col.copyWith(itemIds: updatedList);
        await LocalDatabaseService.instance.updateCollection(updatedCol);
        _collections = await LocalDatabaseService.instance.getAllCollections();
        notifyListeners();
      }
    }
  }

  List<MemoryItem> getMemoriesForCollection(MemoryCollection collection) {
    if (collection.isSmart && collection.smartRule != null) {
      final rule = collection.smartRule!;
      if (rule.startsWith('type:')) {
        final typeStr = rule.replaceFirst('type:', '');
        return _memories.where((m) => m.type.name == typeStr).toList();
      } else if (rule.startsWith('category:')) {
        final cat = rule.replaceFirst('category:', '');
        return _memories.where((m) => m.category == cat).toList();
      } else if (rule == 'isFavorite:true') {
        return _favoriteMemories;
      }
    }
    return _memories.where((m) => collection.itemIds.contains(m.id)).toList();
  }

  // --- Bulk Operations Engine ---

  Future<void> bulkSoftDelete(List<String> memoryIds) async {
    final db = LocalDatabaseService.instance;
    for (final id in memoryIds) {
      await db.softDeleteMemory(id);
    }
    await reloadMemoriesFromDb();
    syncNow();
  }

  Future<void> bulkToggleFavorite(
    List<String> memoryIds,
    bool isFavorite,
  ) async {
    final db = LocalDatabaseService.instance;
    for (final id in memoryIds) {
      await db.toggleFavorite(id, isFavorite);
    }
    await reloadMemoriesFromDb();
    syncNow();
  }

  Future<void> bulkToggleArchive(
    List<String> memoryIds,
    bool isArchived,
  ) async {
    final db = LocalDatabaseService.instance;
    for (final id in memoryIds) {
      await db.toggleArchive(id, isArchived);
    }
    await reloadMemoriesFromDb();
    syncNow();
  }

  Future<void> bulkAssignCategory(
    List<String> memoryIds,
    String category,
  ) async {
    final db = LocalDatabaseService.instance;
    for (final id in memoryIds) {
      final memoryIndex = _memories.indexWhere((m) => m.id == id);
      if (memoryIndex != -1) {
        final updated = _memories[memoryIndex].copyWith(category: category);
        await db.updateMemory(updated);
      }
    }
    await reloadMemoriesFromDb();
    syncNow();
  }

  Future<void> bulkAddToCollection(
    List<String> memoryIds,
    String collectionId,
  ) async {
    final index = _collections.indexWhere((c) => c.id == collectionId);
    if (index != -1) {
      final col = _collections[index];
      final currentSet = Set<String>.from(col.itemIds);
      currentSet.addAll(memoryIds);
      final updatedCol = col.copyWith(itemIds: currentSet.toList());
      await LocalDatabaseService.instance.updateCollection(updatedCol);
      _collections = await LocalDatabaseService.instance.getAllCollections();
      notifyListeners();
    }
  }

  // --- Triage Management ---

  void resolveTriageItem(String id, String category) async {
    final index = _triageItems.indexWhere((item) => item.id == id);
    if (index != -1) {
      final item = _triageItems.removeAt(index);
      final tagsList = List<String>.from(item.tags);
      if (!tagsList.contains(category.toLowerCase())) {
        tagsList.add(category.toLowerCase());
      }
      final resolved = MemoryItem(
        id: item.id,
        title: item.title,
        subtitle: '${item.sourceApp} • $category',
        sourceApp: item.sourceApp,
        type: item.type,
        savedAt: item.savedAt,
        aiSummary: item.aiSummary,
        category: category,
        url: item.url,
        imagePath: item.imagePath,
        imageBytes: item.imageBytes,
        extractedText: item.extractedText,
        structuredEntities: item.structuredEntities,
        tags: tagsList,
        syncStatus: SyncStatus.pendingUpload,
        iconBgColor: item.iconBgColor,
        iconData: item.iconData,
      );

      await LocalDatabaseService.instance.insertMemory(resolved);
      await reloadMemoriesFromDb();
      notifyListeners();
      syncNow();
    }
  }

  // --- Re-analyze with AI ---

  Future<void> reanalyzeMemoryWithAi(String id) async {
    final existingIndex = _memories.indexWhere((m) => m.id == id);
    if (existingIndex == -1) return;
    final item = _memories[existingIndex];

    String textToAnalyze = item.extractedText ?? item.content;
    if (textToAnalyze.isEmpty && item.imagePath != null) {
      textToAnalyze = await OcrService.instance.recognizeTextFromPath(
        item.imagePath!,
      );
    }

    final aiResult = await AiIntelligenceService.instance.analyzeContent(
      text: textToAnalyze.isNotEmpty ? textToAnalyze : item.title,
      title: item.title,
      sourceApp: item.sourceApp,
      type: item.type,
      url: item.url,
    );

    final updated = item.copyWith(
      title: aiResult.suggestedTitle,
      category: aiResult.category,
      aiSummary: aiResult.aiSummary,
      extractedText: textToAnalyze.isNotEmpty
          ? textToAnalyze
          : item.extractedText,
      structuredEntities: aiResult.structuredEntities,
      tags: aiResult.tags,
      iconBgColor: aiResult.iconBgColor,
      iconData: aiResult.iconData,
    );

    await updateMemory(updated);
  }

  // --- Screenshot Scanner & Importer ---

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

          final List<AssetEntity> entities = await targetAlbum
              .getAssetListPaged(page: 0, size: 40);

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

  Future<void> grantRealScreenshotAccess(
    List<AssetEntity> selectedEntities,
  ) async {
    for (AssetEntity entity in selectedEntities) {
      try {
        if (!_permittedScreenshotIds.contains(entity.id)) {
          _permittedScreenshotIds.add(entity.id);

          final file = await entity.file;
          final filePath = file?.path;

          // 1. Run On-Device OCR Text Extraction
          String extractedText = '';
          if (filePath != null) {
            extractedText = await OcrService.instance.recognizeTextFromPath(
              filePath,
            );
          }

          // 2. Run AI Semantic Intelligence on Extracted Text
          final dateStr =
              '${entity.createDateTime.day}/${entity.createDateTime.month}/${entity.createDateTime.year}';
          final rawTitle = 'Screenshot ($dateStr)';
          final aiResult = await AiIntelligenceService.instance.analyzeContent(
            text: extractedText.isNotEmpty
                ? extractedText
                : 'Visual screenshot capture $dateStr',
            title: rawTitle,
            sourceApp: 'Photos',
            type: MemoryType.screenshot,
          );

          final item = MemoryItem(
            id: 'real_shot_${entity.id}',
            title: aiResult.suggestedTitle,
            subtitle: 'Device Gallery • ${aiResult.category}',
            sourceApp: 'Photos',
            type: MemoryType.screenshot,
            savedAt: entity.createDateTime,
            aiSummary: aiResult.aiSummary,
            category: aiResult.category,
            imagePath: filePath,
            extractedText: extractedText.isNotEmpty ? extractedText : null,
            structuredEntities: aiResult.structuredEntities,
            tags: aiResult.tags,
            syncStatus: SyncStatus.pendingUpload,
            iconBgColor: aiResult.iconBgColor,
            iconData: aiResult.iconData,
          );

          final bool needsClarification =
              aiResult.confidence < 0.90 ||
              aiResult.category == 'Uncategorized' ||
              aiResult.category == 'Screenshots';

          if (needsClarification) {
            _triageItems.add(item);
          } else {
            await LocalDatabaseService.instance.insertMemory(item);
          }
        }
      } catch (e) {
        debugPrint("Error processing entity ${entity.id}: $e");
      }
    }
    _savePreferences();
    await reloadMemoriesFromDb();
    notifyListeners();
    syncNow();
  }

  void grantScreenshotAccess(List<String> selectedIds) async {
    for (String id in selectedIds) {
      try {
        if (!_permittedScreenshotIds.contains(id)) {
          _permittedScreenshotIds.add(id);

          final shot = _availableScreenshots.firstWhere(
            (element) => element['id'] == id,
            orElse: () => {'title': 'Screenshot Memory', 'label': 'Reference'},
          );

          final String rawTitle =
              shot['title']?.toString() ?? 'Screenshot Memory';
          String ocrMockText = '';

          if (id == 'shot_1' ||
              rawTitle.contains('Bill') ||
              rawTitle.contains('Receipt')) {
            ocrMockText = '''INVOICE / RECEIPT
Merchant: Cafe Blue Sea
Date: 02 Sep 2026, 14:30
Item 1: Cold Brew Coffee x 2 - INR 480.00
Item 2: Avocado Toast x 1 - INR 350.00
Subtotal: INR 830.00
Taxes (GST 5%): INR 41.50
Total Paid: ₹871.50 via UPI''';
          } else if (id == 'shot_2' ||
              rawTitle.contains('Palette') ||
              rawTitle.contains('Design')) {
            ocrMockText = '''Design System Palette:
Primary Blue: #0B192C
Emerald Accent: #10B981
Purple AI Glow: #8B5CF6
Surface Background: #F8FAFC
Font Family: Outfit, -apple-system, Inter''';
          } else if (id == 'shot_3' ||
              rawTitle.contains('Flight') ||
              rawTitle.contains('Ticket')) {
            ocrMockText = '''BOARDING PASS / FLIGHT CONFIRMATION
Passenger: Vignesh Hegde
Flight: 6E-2042 (IndiGo)
Route: DEL (Delhi) ➔ GOI (Goa)
Departure: 08:45 AM | Gate: 4B | Seat: 12F
PNR / Booking Reference: G7XP9Q
Date: 15 Oct 2026''';
          } else if (id == 'shot_4' ||
              rawTitle.contains('Code') ||
              rawTitle.contains('Python')) {
            ocrMockText = '''Language: Python
def calculate_semantic_similarity(embedding_a, embedding_b):
    """Compute cosine similarity between two vector embeddings."""
    dot_product = np.dot(embedding_a, embedding_b)
    norm_a = np.linalg.norm(embedding_a)
    norm_b = np.linalg.norm(embedding_b)
    return dot_product / (norm_a * norm_b)''';
          } else {
            ocrMockText = '$rawTitle captured from device screen.';
          }

          final aiResult = await AiIntelligenceService.instance.analyzeContent(
            text: ocrMockText,
            title: rawTitle,
            sourceApp: 'Photos',
            type: MemoryType.screenshot,
          );

          final item = MemoryItem(
            id: 'shot_mem_${DateTime.now().millisecondsSinceEpoch}_$id',
            title: aiResult.suggestedTitle,
            subtitle: 'Screenshot • ${aiResult.category}',
            sourceApp: 'Photos',
            type: MemoryType.screenshot,
            savedAt: DateTime.now(),
            aiSummary: aiResult.aiSummary,
            category: aiResult.category,
            extractedText: ocrMockText,
            structuredEntities: aiResult.structuredEntities,
            tags: aiResult.tags,
            syncStatus: SyncStatus.pendingUpload,
            iconBgColor: aiResult.iconBgColor,
            iconData: aiResult.iconData,
          );

          final bool needsClarification =
              aiResult.confidence < 0.90 ||
              aiResult.category == 'Uncategorized';

          if (needsClarification) {
            _triageItems.add(item);
          } else {
            await LocalDatabaseService.instance.insertMemory(item);
          }
        }
      } catch (e) {
        debugPrint("Error processing mock screenshot $id: $e");
      }
    }
    _savePreferences();
    await reloadMemoriesFromDb();
    notifyListeners();
    syncNow();
  }

  // --- External Share Sheet Handler ---

  void startSharedContentProcessing(List<SharedMediaFile> files) {
    _pendingFiles = List.of(files);
    _pendingQuickNote = '';
    _runShareProcessing();
  }

  void startQuickSaveProcessing(String note) {
    _pendingFiles = [];
    _pendingQuickNote = note;
    _runShareProcessing();
  }

  Future<void> _runShareProcessing() async {
    if (_isProcessingShare) return;
    _isProcessingShare = true;
    _processingCompleted = false;
    _processingTitle = "Understanding this...";
    _processingSubtitle = "Extracting context and meaning.";
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 1200));
    if (_pendingFiles.isNotEmpty || _pendingQuickNote.isNotEmpty) {
      _processingTitle = "Finding what matters...";
      _processingSubtitle = "Connecting to your knowledge graph.";
      notifyListeners();
    }

    await Future.delayed(const Duration(milliseconds: 1200));
    await _saveIncomingContent();

    _processingTitle = "Saved.";
    _processingSubtitle = "You'll always find it later in ATLAS.";
    _processingCompleted = true;
    notifyListeners();
  }

  Future<void> _saveIncomingContent() async {
    if (_pendingFiles.isNotEmpty) {
      for (final file in _pendingFiles) {
        final item = await _buildSharedMemory(file);
        await LocalDatabaseService.instance.insertMemory(item);
      }
    } else if (_pendingQuickNote.isNotEmpty) {
      final note = _pendingQuickNote;
      final aiResult = await AiIntelligenceService.instance.analyzeContent(
        text: note,
        type: MemoryType.note,
      );

      final item = MemoryItem(
        id: 'shared_${DateTime.now().microsecondsSinceEpoch}',
        title: _textTitle(note),
        subtitle: 'Quick Note • Just Now',
        sourceApp: 'Atlas',
        type: MemoryType.note,
        savedAt: DateTime.now(),
        aiSummary: aiResult.aiSummary,
        category: aiResult.category,
        snippet: note,
        content: note,
        extractedText: note,
        structuredEntities: aiResult.structuredEntities,
        tags: aiResult.tags,
        syncStatus: SyncStatus.pendingUpload,
        iconBgColor: aiResult.iconBgColor,
        iconData: aiResult.iconData,
      );
      await LocalDatabaseService.instance.insertMemory(item);
    }
    _pendingFiles = [];
    _pendingQuickNote = '';
    await reloadMemoriesFromDb();
    syncNow();
  }

  Future<MemoryItem> _buildSharedMemory(SharedMediaFile file) async {
    final savedAt = DateTime.now();
    final rawPath = file.path.trim();

    if (file.type == SharedMediaType.url || file.type == SharedMediaType.text) {
      final url = _extractUrl(rawPath);
      final isLink = url != null;

      UrlMetadata? urlMeta;
      if (isLink) {
        urlMeta = await UrlMetadataService.instance.fetchMetadata(url);
      }

      final combinedForAi = isLink
          ? '${urlMeta?.title ?? ''} ${urlMeta?.description ?? ''} $rawPath'
          : rawPath;

      final aiResult = await AiIntelligenceService.instance.analyzeContent(
        text: combinedForAi,
        url: url,
        type: isLink ? MemoryType.link : MemoryType.note,
      );

      if (isLink) {
        return MemoryItem(
          id: 'shared_${DateTime.now().microsecondsSinceEpoch}',
          title: urlMeta?.title.isNotEmpty == true
              ? urlMeta!.title
              : _linkTitle(url),
          subtitle: urlMeta?.siteName ?? url,
          sourceApp: urlMeta?.siteName ?? 'Shared Link',
          type: MemoryType.link,
          savedAt: savedAt,
          aiSummary: aiResult.aiSummary,
          category: aiResult.category,
          url: url,
          imagePath: urlMeta?.imageUrl,
          snippet: urlMeta?.description.isNotEmpty == true
              ? urlMeta!.description
              : rawPath,
          content: urlMeta?.articleBody ?? rawPath,
          extractedText: rawPath,
          structuredEntities: aiResult.structuredEntities,
          tags: aiResult.tags,
          syncStatus: SyncStatus.pendingUpload,
          iconBgColor: aiResult.iconBgColor,
          iconData: aiResult.iconData,
        );
      }
      return MemoryItem(
        id: 'shared_${DateTime.now().microsecondsSinceEpoch}',
        title: _textTitle(rawPath),
        subtitle: 'Text • Shared',
        sourceApp: 'Shared Text',
        type: MemoryType.note,
        savedAt: savedAt,
        aiSummary: aiResult.aiSummary,
        category: aiResult.category,
        snippet: rawPath,
        content: rawPath,
        extractedText: rawPath,
        structuredEntities: aiResult.structuredEntities,
        tags: aiResult.tags,
        syncStatus: SyncStatus.pendingUpload,
        iconBgColor: aiResult.iconBgColor,
        iconData: aiResult.iconData,
      );
    }

    if (file.type == SharedMediaType.image ||
        file.type == SharedMediaType.video) {
      final savedPath = await _copySharedFileToStorage(file.path);
      String extractedText = '';
      if (savedPath != null && file.type == SharedMediaType.image) {
        extractedText = await OcrService.instance.recognizeTextFromPath(
          savedPath,
        );
      }

      final aiResult = await AiIntelligenceService.instance.analyzeContent(
        text: extractedText.isNotEmpty
            ? extractedText
            : (savedPath ?? 'Media File'),
        type: MemoryType.screenshot,
      );

      final category = aiResult.category == 'Notes'
          ? 'Screenshots'
          : aiResult.category;
      final iconData = aiResult.iconData == Icons.notes_rounded
          ? Icons.image_rounded
          : aiResult.iconData;

      return MemoryItem(
        id: 'shared_${DateTime.now().microsecondsSinceEpoch}',
        title: file.type == SharedMediaType.image
            ? aiResult.suggestedTitle
            : 'Shared Video',
        subtitle: 'Media • $category',
        sourceApp: 'Photos',
        type: MemoryType.screenshot,
        savedAt: savedAt,
        aiSummary: aiResult.aiSummary,
        category: category,
        imagePath: savedPath,
        extractedText: extractedText.isNotEmpty ? extractedText : null,
        structuredEntities: aiResult.structuredEntities,
        tags: aiResult.tags,
        syncStatus: SyncStatus.pendingUpload,
        iconBgColor: aiResult.iconBgColor,
        iconData: iconData,
      );
    }

    final aiResult = await AiIntelligenceService.instance.analyzeContent(
      text: file.path,
      type: MemoryType.pdf,
    );

    return MemoryItem(
      id: 'shared_${DateTime.now().microsecondsSinceEpoch}',
      title: _fileNameFromPath(file.path),
      subtitle: 'File • Shared',
      sourceApp: 'Shared',
      type: MemoryType.pdf,
      savedAt: savedAt,
      aiSummary: aiResult.aiSummary,
      category: aiResult.category,
      snippet: file.path,
      structuredEntities: aiResult.structuredEntities,
      tags: aiResult.tags,
      syncStatus: SyncStatus.pendingUpload,
      iconBgColor: aiResult.iconBgColor,
      iconData: aiResult.iconData,
    );
  }

  String? _extractUrl(String text) {
    final match = RegExp(
      r'(https?://[^\s<>"()]+|www\.[^\s<>"()]+)',
    ).firstMatch(text);
    if (match == null) return null;
    var url = match.group(0)!.replaceAll(RegExp(r'[),.;!?]+$'), '');
    if (url.startsWith('www.')) url = 'https://$url';
    return url;
  }

  String _linkTitle(String url) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host.isEmpty ? url : uri.host;
      return host.startsWith('www.') ? host.substring(4) : host;
    } catch (_) {
      return url;
    }
  }

  String _textTitle(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 'Shared Text';
    var title = trimmed.split('\n').first.trim();
    if (title.length > 60) title = '${title.substring(0, 57)}...';
    return title.isEmpty ? 'Shared Text' : title;
  }

  String _fileNameFromPath(String? path) {
    if (path == null || path.isEmpty) return 'Shared File';
    final segments = path.split(RegExp(r'[/\\]'));
    final name = segments.last;
    return name.isEmpty ? 'Shared File' : name;
  }

  Future<String?> _copySharedFileToStorage(String? sourcePath) async {
    if (sourcePath == null || sourcePath.isEmpty) return sourcePath;
    try {
      final src = File(sourcePath);
      if (!src.existsSync()) return sourcePath;
      final dir = await getApplicationDocumentsDirectory();
      final savedDir = Directory('${dir.path}/shared_media');
      if (!savedDir.existsSync()) savedDir.createSync(recursive: true);
      final fileName =
          'shared_${DateTime.now().microsecondsSinceEpoch}_${src.uri.pathSegments.last}';
      final dest = File('${savedDir.path}/$fileName');
      await src.copy(dest.path);
      return dest.path;
    } catch (e) {
      debugPrint("Error copying shared file: $e");
      return sourcePath;
    }
  }

  void resetShareProcessing() {
    _isProcessingShare = false;
    _processingCompleted = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _syncStateSub?.cancel();
    super.dispose();
  }
}
