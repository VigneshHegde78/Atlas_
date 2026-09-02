import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import '../providers/memory_provider.dart';
import '../theme/app_theme.dart';

class ScreenshotReviewScreen extends StatefulWidget {
  const ScreenshotReviewScreen({super.key});

  @override
  State<ScreenshotReviewScreen> createState() => _ScreenshotReviewScreenState();
}

class _ScreenshotReviewScreenState extends State<ScreenshotReviewScreen> {
  final Set<String> _selectedMockIds = {};
  final Set<AssetEntity> _selectedRealEntities = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MemoryProvider>(
        context,
        listen: false,
      ).loadDeviceScreenshots();
    });
  }

  Future<void> _saveSelectedScreenshots(
    BuildContext context,
    MemoryProvider memoryProvider,
    bool hasReal,
  ) async {
    if (_isSaving) return;

    final count = hasReal ? _selectedRealEntities.length : _selectedMockIds.length;
    if (count == 0) return;

    setState(() {
      _isSaving = true;
    });

    try {
      if (hasReal) {
        await memoryProvider.grantRealScreenshotAccess(
          _selectedRealEntities.toList(),
        );
      } else {
        memoryProvider.grantScreenshotAccess(
          _selectedMockIds.toList(),
        );
      }

      if (mounted) {
        setState(() {
          _selectedRealEntities.clear();
          _selectedMockIds.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AtlasColors.blue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AtlasColors.emerald, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$count screenshot(s) analyzed with AI and saved to ATLAS!',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error saving selected screenshots: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final memoryProvider = Provider.of<MemoryProvider>(context);
    final realScreenshots = memoryProvider.deviceScreenshots;
    final mockScreenshots = memoryProvider.availableScreenshots;
    final bool hasReal = realScreenshots.isNotEmpty;
    final int totalCount = hasReal
        ? realScreenshots.length
        : mockScreenshots.length;
    final int selectedCount = hasReal
        ? _selectedRealEntities.length
        : _selectedMockIds.length;

    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: AtlasColors.surface,
      appBar: AppBar(
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.close_rounded, size: 22),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Text(
          hasReal ? 'DEVICE GALLERY' : 'SCREENSHOTS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade500,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: false,
        actions: [
          if (selectedCount > 0)
            TextButton(
              onPressed: _isSaving
                  ? null
                  : () {
                      setState(() {
                        _selectedRealEntities.clear();
                        _selectedMockIds.clear();
                      });
                    },
              child: const Text(
                'Deselect All',
                style: TextStyle(
                  color: AtlasColors.rose,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 8.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$totalCount available',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AtlasColors.blue,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Select items to index in ATLAS. Saved screenshots are categorized and searchable via OCR.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                if (memoryProvider.isLoadingScreenshots)
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(color: AtlasColors.blue),
                    ),
                  )
                else if (totalCount == 0)
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: AtlasColors.emerald.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.check_circle_rounded,
                                  color: AtlasColors.emerald,
                                  size: 44,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'All Caught Up!',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AtlasColors.blue,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'All screenshots in your gallery have been indexed into ATLAS Memory Space.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade500,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: hasReal
                        ? GridView.builder(
                            padding: EdgeInsets.fromLTRB(
                              24,
                              8,
                              24,
                              canPop ? 40 : 120,
                            ),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 4 / 5,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                            itemCount: realScreenshots.length,
                            itemBuilder: (context, index) {
                              final AssetEntity entity = realScreenshots[index];
                              final bool isSelected =
                                  _selectedRealEntities.contains(entity);

                              return InkWell(
                                onTap: _isSaving
                                    ? null
                                    : () {
                                        setState(() {
                                          if (isSelected) {
                                            _selectedRealEntities.remove(entity);
                                          } else {
                                            _selectedRealEntities.add(entity);
                                          }
                                        });
                                      },
                                borderRadius: BorderRadius.circular(24),
                                child: Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                          color: isSelected
                                              ? AtlasColors.emerald
                                              : Colors.grey.shade200,
                                          width: isSelected ? 3 : 1,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(22),
                                        child: FutureBuilder<Uint8List?>(
                                          future: entity.thumbnailDataWithSize(
                                            const ThumbnailSize(300, 300),
                                          ),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState ==
                                                    ConnectionState.done &&
                                                snapshot.data != null) {
                                              return Image.memory(
                                                snapshot.data!,
                                                width: double.infinity,
                                                height: double.infinity,
                                                fit: BoxFit.cover,
                                              );
                                            }
                                            return const Center(
                                              child: Icon(
                                                Icons.image_rounded,
                                                color: Colors.grey,
                                                size: 36,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),

                                    Positioned(
                                      top: 12,
                                      right: 12,
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AtlasColors.emerald
                                              : Colors.black.withValues(
                                                  alpha: 0.35,
                                                ),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: isSelected
                                            ? const Center(
                                                child: Icon(
                                                  Icons.check_rounded,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                              )
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          )
                        : GridView.builder(
                            padding: EdgeInsets.fromLTRB(
                              24,
                              8,
                              24,
                              canPop ? 40 : 120,
                            ),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 4 / 5,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                            itemCount: mockScreenshots.length,
                            itemBuilder: (context, index) {
                              final shot = mockScreenshots[index];
                              final String id = shot['id'];
                              final bool isSelected =
                                  _selectedMockIds.contains(id);

                              return InkWell(
                                onTap: _isSaving
                                    ? null
                                    : () {
                                        setState(() {
                                          if (isSelected) {
                                            _selectedMockIds.remove(id);
                                          } else {
                                            _selectedMockIds.add(id);
                                          }
                                        });
                                      },
                                borderRadius: BorderRadius.circular(24),
                                child: Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Color(
                                          shot['color'],
                                        ).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                          color: isSelected
                                              ? AtlasColors.emerald
                                              : Colors.grey.shade200,
                                          width: isSelected ? 3 : 1,
                                        ),
                                      ),
                                      child: Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.image_rounded,
                                              size: 40,
                                              color: Color(shot['color']),
                                            ),
                                            const SizedBox(height: 10),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12.0,
                                                  ),
                                              child: Text(
                                                shot['title'],
                                                textAlign: TextAlign.center,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: AtlasColors.textPrimary,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              shot['date'],
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.grey.shade500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    Positioned(
                                      top: 12,
                                      right: 12,
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AtlasColors.emerald
                                              : Colors.black.withValues(
                                                  alpha: 0.25,
                                                ),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: isSelected
                                            ? const Center(
                                                child: Icon(
                                                  Icons.check_rounded,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                              )
                                            : null,
                                      ),
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

          // Floating Bottom-Right Corner Action Button (Tick mark + Selected count badge)
          Positioned(
            right: 24,
            bottom: canPop ? 28 : 104,
            child: AnimatedScale(
              scale: selectedCount > 0 ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              child: GestureDetector(
                onTap: _isSaving
                    ? null
                    : () => _saveSelectedScreenshots(
                        context,
                        memoryProvider,
                        hasReal,
                      ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AtlasColors.blue, AtlasColors.blueLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [AtlasTheme.floatShadow],
                      ),
                      child: Center(
                        child: _isSaving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                      ),
                    ),
                    // Counter Badge on Top-Right of the Button
                    if (selectedCount > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AtlasColors.emerald,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 26,
                            minHeight: 26,
                          ),
                          child: Center(
                            child: Text(
                              '$selectedCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
