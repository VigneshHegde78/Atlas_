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
      Provider.of<MemoryProvider>(context, listen: false).loadDeviceScreenshots();
    });
  }

  @override
  Widget build(BuildContext context) {
    final memoryProvider = Provider.of<MemoryProvider>(context);
    final realScreenshots = memoryProvider.deviceScreenshots;
    final mockScreenshots = memoryProvider.availableScreenshots;
    final bool hasReal = realScreenshots.isNotEmpty;
    final int totalCount = hasReal ? realScreenshots.length : mockScreenshots.length;

    return Scaffold(
      backgroundColor: AtlasColors.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: Center(
              child: Text(
                hasReal ? 'DEVICE GALLERY' : 'CAMERA ROLL',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey.shade400,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$totalCount screenshots available',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AtlasColors.blue,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Select what you want ATLAS to remember. Once selected, access is remembered & you won\'t be asked again.',
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
            const SizedBox(height: 16),

            if (memoryProvider.isLoadingScreenshots)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: AtlasColors.blue),
                ),
              )
            else
              Expanded(
                child: hasReal
                    ? GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 4 / 5,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: realScreenshots.length,
                        itemBuilder: (context, index) {
                          final AssetEntity entity = realScreenshots[index];
                          final bool isAlreadyPermitted = memoryProvider.permittedScreenshotIds.contains(entity.id);
                          final bool isSelected = _selectedRealEntities.contains(entity) || isAlreadyPermitted;

                          return InkWell(
                            onTap: isAlreadyPermitted || _isSaving
                                ? null
                                : () {
                                    setState(() {
                                      if (_selectedRealEntities.contains(entity)) {
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
                                      color: isSelected ? AtlasColors.emerald : Colors.grey.shade200,
                                      width: isSelected ? 3 : 1,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(22),
                                    child: FutureBuilder<Uint8List?>(
                                      future: entity.thumbnailDataWithSize(const ThumbnailSize(300, 300)),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                                          return Image.memory(
                                            snapshot.data!,
                                            width: double.infinity,
                                            height: double.infinity,
                                            fit: BoxFit.cover,
                                          );
                                        }
                                        return const Center(
                                          child: Icon(Icons.image_rounded, color: Colors.grey, size: 36),
                                        );
                                      },
                                    ),
                                  ),
                                ),

                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AtlasColors.emerald
                                          : Colors.black.withOpacity(0.3),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
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

                                if (isAlreadyPermitted)
                                  Positioned(
                                    bottom: 12,
                                    left: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AtlasColors.emerald.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        'SAVED',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 4 / 5,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: mockScreenshots.length,
                        itemBuilder: (context, index) {
                          final shot = mockScreenshots[index];
                          final String id = shot['id'];
                          final bool isAlreadyPermitted = memoryProvider.permittedScreenshotIds.contains(id);
                          final bool isSelected = _selectedMockIds.contains(id) || isAlreadyPermitted;

                          return InkWell(
                            onTap: isAlreadyPermitted || _isSaving
                                ? null
                                : () {
                                    setState(() {
                                      if (_selectedMockIds.contains(id)) {
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
                                    color: Color(shot['color']).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: isSelected ? AtlasColors.emerald : Colors.grey.shade200,
                                      width: isSelected ? 2.5 : 1,
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
                                        Text(
                                          shot['title'],
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AtlasColors.textPrimary,
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
                                    duration: const Duration(milliseconds: 200),
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AtlasColors.emerald
                                          : Colors.black.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
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

                                if (isAlreadyPermitted)
                                  Positioned(
                                    bottom: 12,
                                    left: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AtlasColors.emerald.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        'SAVED',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: (_isSaving || (hasReal ? _selectedRealEntities.isEmpty : _selectedMockIds.isEmpty))
                      ? null
                      : () async {
                          setState(() {
                            _isSaving = true;
                          });
                          try {
                            if (hasReal) {
                              await memoryProvider.grantRealScreenshotAccess(_selectedRealEntities.toList());
                            } else {
                              memoryProvider.grantScreenshotAccess(_selectedMockIds.toList());
                            }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${hasReal ? _selectedRealEntities.length : _selectedMockIds.length} screenshot(s) saved to Memory Space permanently!',
                                  ),
                                ),
                              );
                              Navigator.of(context).pop();
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
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AtlasColors.blue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 4,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          (hasReal ? _selectedRealEntities.isEmpty : _selectedMockIds.isEmpty)
                              ? 'Select Screenshots to Save'
                              : 'Save Selected (${hasReal ? _selectedRealEntities.length : _selectedMockIds.length})',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
