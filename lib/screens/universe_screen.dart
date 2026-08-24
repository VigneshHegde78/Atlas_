import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/memory_item.dart';
import '../providers/memory_provider.dart';
import '../theme/app_theme.dart';
import 'detail_screen.dart';
import 'search_screen.dart';

/// Stable category accent colors used across pins and cards.
class AtlasCategory {
  static const Map<String, Color> _colors = {
    'Design Systems': Color(0xFF3B82F6),
    'Design': Color(0xFF3B82F6),
    'Recipes': Color(0xFF10B981),
    'Food & Cooking': Color(0xFF10B981),
    'Travel': Color(0xFFF59E0B),
    'Adventure': Color(0xFFF97316),
    'Shopping': Color(0xFFEC4899),
    'Finance': Color(0xFF6366F1),
    'Work': Color(0xFF9333EA),
    'Code & Math': Color(0xFF8B5CF6),
    'Development': Color(0xFF0EA5E9),
    'Screenshots': Color(0xFF22C55E),
    'Reference': Color(0xFF64748B),
    'Shared': Color(0xFF14B8A6),
    'Music': Color(0xFFE11D48),
    'Uncategorized': Color(0xFF9CA3AF),
    'History': Color(0xFF8B5CF6),
    'Ancient History': Color(0xFF6366F1),
  };

  static const List<Color> _fallback = [
    Color(0xFF3B82F6),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEC4899),
    Color(0xFF9333EA),
    Color(0xFF14B8A6),
    Color(0xFF0EA5E9),
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
    Color(0xFFF97316),
  ];

  static Color color(String category) {
    final matched = _colors[category];
    if (matched != null) return matched;
    return _fallback[category.hashCode.abs() % _fallback.length];
  }
}

class GlobePinData {
  final String category;
  final Color color;
  final IconData icon;
  final int count;
  final double lat;
  final double lng;

  const GlobePinData({
    required this.category,
    required this.color,
    required this.icon,
    required this.count,
    required this.lat,
    required this.lng,
  });
}

/// 3D Projection math used for placing pins and wireframe on the 3D globe.
class GlobeMath {
  static const double radiusFactor = 0.46;

  static ({Offset offset, double z, double radius})? project({
    required double lat,
    required double lng,
    required double angleX,
    required double angleY,
    required Size size,
    Offset? centerOffset,
  }) {
    final center = centerOffset ?? Offset(size.width / 2, size.height * 0.72);
    final radius = math.min(size.width, size.height) * radiusFactor;

    final cosX = math.cos(angleX);
    final sinX = math.sin(angleX);
    final cosY = math.cos(angleY + lng);
    final sinY = math.sin(angleY + lng);
    final cosLat = math.cos(lat);
    final sinLat = math.sin(lat);

    final x = radius * cosLat * sinY;
    final y = radius * (sinLat * cosX - cosLat * sinX * cosY);
    final z = radius * (sinLat * sinX + cosLat * cosX * cosY);

    if (z < -radius * 0.35) return null;
    return (offset: Offset(center.dx + x, center.dy - y), z: z, radius: radius);
  }
}

class UniverseScreen extends StatefulWidget {
  const UniverseScreen({super.key});

  @override
  State<UniverseScreen> createState() => _UniverseScreenState();
}

class _UniverseScreenState extends State<UniverseScreen> {
  String? _selectedCategory;
  int _currentCardIndex = 0;

  double _pinLat(String category) {
    final hash = category.hashCode & 0x7fffffff;
    return (hash % 1400) / 1000 - 0.7;
  }

  double _pinLng(String category) {
    final hash = (category.hashCode * 31) & 0x7fffffff;
    return (hash % 6283) / 1000 - 3.1415;
  }

  List<GlobePinData> _groupPins(List<MemoryItem> memories) {
    final groups = <String, List<MemoryItem>>{};
    for (final m in memories) {
      groups.putIfAbsent(m.category, () => []).add(m);
    }
    return groups.entries.map((e) {
      return GlobePinData(
        category: e.key,
        color: AtlasCategory.color(e.key),
        icon: e.value.first.iconData,
        count: e.value.length,
        lat: _pinLat(e.key),
        lng: _pinLng(e.key),
      );
    }).toList();
  }

  void _showFilterModal(List<GlobePinData> pins, int totalCount) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Filter Memories by Category',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: Text('All ($totalCount)'),
                    selected: _selectedCategory == null,
                    selectedColor: const Color(0xFF0F172A),
                    labelStyle: TextStyle(
                      color: _selectedCategory == null ? Colors.white : const Color(0xFF0F172A),
                      fontWeight: FontWeight.w700,
                    ),
                    onSelected: (_) {
                      setState(() {
                        _selectedCategory = null;
                        _currentCardIndex = 0;
                      });
                      Navigator.pop(context);
                    },
                  ),
                  for (final pin in pins)
                    ChoiceChip(
                      label: Text('${pin.category} (${pin.count})'),
                      selected: _selectedCategory == pin.category,
                      selectedColor: pin.color,
                      labelStyle: TextStyle(
                        color: _selectedCategory == pin.category ? Colors.white : const Color(0xFF0F172A),
                        fontWeight: FontWeight.w700,
                      ),
                      onSelected: (_) {
                        setState(() {
                          _selectedCategory = pin.category;
                          _currentCardIndex = 0;
                        });
                        Navigator.pop(context);
                      },
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _getLocationText(List<MemoryItem> filteredMemories) {
    if (filteredMemories.isEmpty) return 'Global Memory Space';
    final item = filteredMemories[_currentCardIndex % filteredMemories.length];
    if (item.subtitle.isNotEmpty && !item.subtitle.contains('http')) {
      return item.subtitle;
    }
    return '${item.category} • Atlas';
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MemoryProvider>(context);
    final pins = _groupPins(provider.memories);

    final filteredMemories = _selectedCategory == null
        ? provider.memories
        : provider.memories.where((m) => m.category == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Clean Header
            _buildTopHeader(pins: pins, totalMemories: provider.memories.length),
            const SizedBox(height: 10),

            // Sub-header: Location Chip & Card Count Badge
            _buildContextBar(
              location: _getLocationText(filteredMemories),
              currentIndex: filteredMemories.isEmpty ? 0 : (_currentCardIndex % filteredMemories.length),
              totalCards: filteredMemories.length,
            ),
            const SizedBox(height: 12),

            // Active category indicator if filtered
            if (_selectedCategory != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AtlasCategory.color(_selectedCategory!).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Category: $_selectedCategory',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AtlasCategory.color(_selectedCategory!),
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategory = null;
                                _currentCardIndex = 0;
                              });
                            },
                            child: Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: AtlasCategory.color(_selectedCategory!),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Middle Main Content Area (Globe Dome + Floating Card Deck)
            Expanded(
              child: Stack(
                children: [
                  // 3D Globe Dome in Lower Half
                  Positioned.fill(
                    child: UniverseGlobe(
                      pins: pins,
                      selectedCategory: _selectedCategory,
                      onSelect: (category) {
                        setState(() {
                          _selectedCategory = category;
                          _currentCardIndex = 0;
                        });
                      },
                    ),
                  ),

                  // Floating Card Exploration Deck in Upper Half
                  Positioned(
                    left: 20,
                    right: 20,
                    top: 0,
                    height: 275,
                    child: MemoryCardDeck(
                      items: filteredMemories,
                      currentIndex: _currentCardIndex,
                      onIndexChanged: (idx) {
                        setState(() => _currentCardIndex = idx);
                      },
                    ),
                  ),

                  // Floating Drag Instruction Pill
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 24,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.swap_horiz_rounded,
                              size: 16,
                              color: Color(0xFF475569),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Drag or rotate globe to explore pins',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader({
    required List<GlobePinData> pins,
    required int totalMemories,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        children: [
          // Title & Sub-header Text
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Globe Explorer',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Your memories pinned around the world',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

          // Right Action Icons (Filter, Search)
          _buildCircleActionButton(
            icon: Icons.tune_rounded,
            onTap: () => _showFilterModal(pins, totalMemories),
          ),
          const SizedBox(width: 8),
          _buildCircleActionButton(
            icon: Icons.search_rounded,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCircleActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Icon(
            icon,
            size: 20,
            color: const Color(0xFF334155),
          ),
        ),
      ),
    );
  }

  Widget _buildContextBar({
    required String location,
    required int currentIndex,
    required int totalCards,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Location Badge (Dark Capsule)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 15,
                  color: Color(0xFF38BDF8),
                ),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Text(
                    location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Cards Counter Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              totalCards > 0 ? '${currentIndex + 1} / $totalCards Cards' : '0 / 0 Cards',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rotatable 3D Globe with glowing cyan atmosphere rim and category pins.
class UniverseGlobe extends StatefulWidget {
  final List<GlobePinData> pins;
  final String? selectedCategory;
  final ValueChanged<String?> onSelect;

  const UniverseGlobe({
    super.key,
    required this.pins,
    required this.selectedCategory,
    required this.onSelect,
  });

  @override
  State<UniverseGlobe> createState() => _UniverseGlobeState();
}

class _UniverseGlobeState extends State<UniverseGlobe> with SingleTickerProviderStateMixin {
  double _angleX = 0.35;
  double _angleY = 0.0;
  bool _interacting = false;

  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    _spin.addListener(_idleRotate);
  }

  void _idleRotate() {
    if (_interacting || !mounted) return;
    setState(() => _angleY += 0.0006);
  }

  @override
  void dispose() {
    _spin.removeListener(_idleRotate);
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final centerOffset = Offset(size.width / 2, size.height * 0.72);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (_) => setState(() => _interacting = true),
          onPanUpdate: (details) {
            setState(() {
              _angleY += details.delta.dx * 0.012;
              _angleX += details.delta.dy * 0.012;
              _angleX = _angleX.clamp(-1.0, 1.0);
            });
          },
          onPanEnd: (_) => setState(() => _interacting = false),
          onPanCancel: () => setState(() => _interacting = false),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              RepaintBoundary(
                child: CustomPaint(
                  size: size,
                  painter: UniverseGlobePainter(
                    angleX: _angleX,
                    angleY: _angleY,
                    pins: widget.pins,
                    selectedCategory: widget.selectedCategory,
                    centerOffset: centerOffset,
                  ),
                ),
              ),
              for (final pin in widget.pins) ..._buildPin(size, pin, centerOffset),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildPin(Size size, GlobePinData pin, Offset centerOffset) {
    final projected = GlobeMath.project(
      lat: pin.lat,
      lng: pin.lng,
      angleX: _angleX,
      angleY: _angleY,
      size: size,
      centerOffset: centerOffset,
    );
    if (projected == null) return const [];

    final depth = (projected.z + projected.radius) / (2 * projected.radius);
    final selected = widget.selectedCategory == pin.category;
    final pinSize = (selected ? 42.0 : 32.0) * (0.85 + 0.3 * depth);
    final pos = projected.offset;

    return [
      Positioned(
        left: pos.dx - pinSize / 2,
        top: pos.dy - pinSize / 2,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => widget.onSelect(selected ? null : pin.category),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: pinSize,
                height: pinSize,
                decoration: BoxDecoration(
                  color: pin.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: selected ? 3.0 : 2.0),
                  boxShadow: [
                    BoxShadow(
                      color: pin.color.withValues(alpha: selected ? 0.6 : 0.35),
                      blurRadius: selected ? 16 : 8,
                      spreadRadius: selected ? 3 : 1,
                    ),
                  ],
                ),
                child: Icon(
                  pin.icon,
                  color: Colors.white,
                  size: pinSize * 0.45,
                ),
              ),
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: pin.color, width: 1.5),
                    boxShadow: [AtlasTheme.softShadow],
                  ),
                  child: Text(
                    '${pin.count}',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: pin.color,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }
}

class UniverseGlobePainter extends CustomPainter {
  final double angleX;
  final double angleY;
  final List<GlobePinData> pins;
  final String? selectedCategory;
  final Offset centerOffset;

  UniverseGlobePainter({
    required this.angleX,
    required this.angleY,
    required this.pins,
    required this.selectedCategory,
    required this.centerOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = centerOffset;
    final radius = math.min(size.width, size.height) * GlobeMath.radiusFactor;

    // 1. Atmosphere Cyan Glow Arc (Outer Glow Rim)
    final atmosphereGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF38BDF8).withValues(alpha: 0.45),
          const Color(0xFF22D3EE).withValues(alpha: 0.20),
          const Color(0xFF0F172A).withValues(alpha: 0.0),
        ],
        stops: const [0.65, 0.88, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.25));
    canvas.drawCircle(center, radius * 1.25, atmosphereGlow);

    // 2. Cyan Rim Highlight Curve (Atmosphere Ring)
    final rimArcPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF67E8F9),
          const Color(0xFF38BDF8).withValues(alpha: 0.4),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.04))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0;
    canvas.drawCircle(center, radius * 1.02, rimArcPaint);

    // 3. Globe Body Sphere
    final globeBody = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.25, -0.35),
        colors: const [
          Color(0xFF2563EB),
          Color(0xFF1D4ED8),
          Color(0xFF0F172A),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, globeBody);

    // 4. Wireframe Grid
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (double lat = -0.7; lat <= 0.71; lat += 0.35) {
      _drawPath(canvas, size, lat, null, gridPaint);
    }
    for (int i = 0; i < 8; i++) {
      _drawPath(canvas, size, null, i * math.pi / 4, gridPaint);
    }

    // 5. Equator Ring Highlight
    final equator = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    _drawPath(canvas, size, 0.0, null, equator);

    // 6. Glowing Orbital Nodes
    final nodePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 5; i++) {
      final angle = angleY + (i * math.pi / 2.5);
      final nx = center.dx + (radius * 0.92) * math.cos(angle);
      final ny = center.dy + (radius * 0.35) * math.sin(angle);
      canvas.drawCircle(Offset(nx, ny), 2.5, nodePaint);
    }
  }

  void _drawPath(Canvas canvas, Size size, double? lat, double? lng, Paint paint) {
    final path = Path();
    bool drawing = false;

    if (lat != null) {
      for (double l = 0; l <= math.pi * 2 + 0.15; l += 0.12) {
        final p = GlobeMath.project(
          lat: lat,
          lng: l,
          angleX: angleX,
          angleY: angleY,
          size: size,
          centerOffset: centerOffset,
        );
        if (p == null) {
          drawing = false;
          continue;
        }
        if (drawing) {
          path.lineTo(p.offset.dx, p.offset.dy);
        } else {
          path.moveTo(p.offset.dx, p.offset.dy);
          drawing = true;
        }
      }
    } else {
      for (double a = -1.2; a <= 1.21; a += 0.12) {
        final p = GlobeMath.project(
          lat: a,
          lng: lng!,
          angleX: angleX,
          angleY: angleY,
          size: size,
          centerOffset: centerOffset,
        );
        if (p == null) {
          drawing = false;
          continue;
        }
        if (drawing) {
          path.lineTo(p.offset.dx, p.offset.dy);
        } else {
          path.moveTo(p.offset.dx, p.offset.dy);
          drawing = true;
        }
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant UniverseGlobePainter oldDelegate) =>
      oldDelegate.angleX != angleX ||
      oldDelegate.angleY != angleY ||
      oldDelegate.pins != pins ||
      oldDelegate.selectedCategory != selectedCategory ||
      oldDelegate.centerOffset != centerOffset;
}

/// Interactive Card Deck widget inspired by the reference design.
class MemoryCardDeck extends StatefulWidget {
  final List<MemoryItem> items;
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;

  const MemoryCardDeck({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onIndexChanged,
  });

  @override
  State<MemoryCardDeck> createState() => _MemoryCardDeckState();
}

class _MemoryCardDeckState extends State<MemoryCardDeck> {
  double _dragOffset = 0.0;

  void _nextCard() {
    if (widget.items.isEmpty) return;
    widget.onIndexChanged((widget.currentIndex + 1) % widget.items.length);
  }

  void _previousCard() {
    if (widget.items.isEmpty) return;
    widget.onIndexChanged(
      (widget.currentIndex - 1 + widget.items.length) % widget.items.length,
    );
  }

  int _calculateReadTime(String text) {
    if (text.isEmpty) return 2;
    final words = text.trim().split(RegExp(r'\s+')).length;
    return math.max(1, (words / 25).ceil());
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'No memories found for this filter',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ),
      );
    }

    final total = widget.items.length;
    final activeIndex = widget.currentIndex % total;
    final activeItem = widget.items[activeIndex];

    return Column(
      children: [
        // Main Stacked Card Container
        Expanded(
          child: GestureDetector(
            onHorizontalDragUpdate: (details) {
              setState(() {
                _dragOffset += details.delta.dx;
              });
            },
            onHorizontalDragEnd: (details) {
              if (_dragOffset < -50 || details.primaryVelocity! < -300) {
                _nextCard();
              } else if (_dragOffset > 50 || details.primaryVelocity! > 300) {
                _previousCard();
              }
              setState(() => _dragOffset = 0.0);
            },
            child: Stack(
              children: [
                // Bottom Stacked Card Shadow Edge Layer 2
                if (total > 2)
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),

                // Middle Stacked Card Layer 1
                if (total > 1)
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                  ),

                // Top Front Interactive Card
                Positioned.fill(
                  child: Transform.translate(
                    offset: Offset(_dragOffset, 0),
                    child: Material(
                      elevation: 4,
                      shadowColor: Colors.black.withValues(alpha: 0.08),
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Card Top Row: Category Chip & Read Time
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    activeItem.category.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF334155),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time_rounded,
                                      size: 13,
                                      color: Color(0xFF94A3B8),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${_calculateReadTime(activeItem.aiSummary)} min read',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Main Title
                            Text(
                              activeItem.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 17.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),

                            // Description / Summary Snippet
                            Expanded(
                              child: Text(
                                activeItem.aiSummary.isNotEmpty
                                    ? activeItem.aiSummary
                                    : activeItem.subtitle,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF475569),
                                  height: 1.4,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),

                            // Divider
                            Container(
                              height: 1,
                              color: const Color(0xFFF1F5F9),
                            ),
                            const SizedBox(height: 8),

                            // Card Footer Row: Counter & ...more >
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Card ${activeIndex + 1} of $total',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => DetailScreen(memory: activeItem),
                                      ),
                                    );
                                  },
                                  child: const Row(
                                    children: [
                                      Text(
                                        '...more',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      SizedBox(width: 2),
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        size: 16,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Deck Controls Row: Arrow Left, Instruction Text, Arrow Right
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Left Button
            Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 2,
              shadowColor: Colors.black.withValues(alpha: 0.06),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _previousCard,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    size: 18,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Instruction Label
            const Text(
              'SWIPE OR TAP CARD',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF94A3B8),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(width: 16),

            // Right Button
            Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 2,
              shadowColor: Colors.black.withValues(alpha: 0.06),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _nextCard,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
