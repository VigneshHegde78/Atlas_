import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/memory_item.dart';
import '../providers/memory_provider.dart';
import '../theme/app_theme.dart';
import 'detail_screen.dart';
import 'search_screen.dart';

/// Stable category accent colors used across pins, cards, and constellation star nodes.
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
  String _activeTab = 'universe'; // 'globe' or 'universe'
  String? _selectedNodeId;

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
                'Filter Memories',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
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

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MemoryProvider>(context);
    final pins = _groupPins(provider.memories);

    final filteredMemories = _selectedCategory == null
        ? provider.memories
        : provider.memories.where((m) => m.category == _selectedCategory).toList();

    final isUniverseMode = _activeTab == 'universe';

    return Scaffold(
      backgroundColor: isUniverseMode ? const Color(0xFF424242) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Minimal Heading & Subheading Header for Globe or Universe mode
            _buildTopHeader(
              isUniverseMode: isUniverseMode,
              pins: pins,
              totalMemories: provider.memories.length,
            ),
            const SizedBox(height: 10),

            if (!isUniverseMode) ...[
              // Sub-header: Location Chip & Card Count Badge for Globe View
              _buildContextBar(
                location: _getLocationText(filteredMemories),
                currentIndex: filteredMemories.isEmpty ? 0 : (_currentCardIndex % filteredMemories.length),
                totalCards: filteredMemories.length,
              ),
              const SizedBox(height: 12),
            ],

            // Middle Main Content Area
            Expanded(
              child: Stack(
                children: [
                  if (isUniverseMode)
                    // Constellation View in Grey[800]
                    Positioned.fill(
                      child: ConstellationUniverseView(
                        memories: provider.memories,
                        selectedCategory: _selectedCategory,
                        selectedNodeId: _selectedNodeId,
                        onCategorySelected: (cat) {
                          setState(() {
                            _selectedCategory = cat;
                            _selectedNodeId = null;
                          });
                        },
                        onNodeSelected: (nodeId) {
                          setState(() {
                            _selectedNodeId = nodeId;
                          });
                        },
                      ),
                    )
                  else ...[
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

                    // Floating Card Exploration Deck in Upper Half (Compact height)
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
                      bottom: 72,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.94),
                            borderRadius: BorderRadius.circular(20),
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
                                'Drag or swipe globe to explore',
                                style: TextStyle(
                                  fontSize: 11.5,
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

                  // Floating Capsule Bottom Navigation Toggle
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 12,
                    child: Center(
                      child: _buildBottomCapsuleToggle(),
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

  String _getLocationText(List<MemoryItem> filteredMemories) {
    if (filteredMemories.isEmpty) return 'Giza Plateau, Egypt';
    final item = filteredMemories[_currentCardIndex % filteredMemories.length];
    if (item.subtitle.isNotEmpty && !item.subtitle.contains('http')) {
      return item.subtitle;
    }
    return '${item.category} Explore';
  }

  Widget _buildTopHeader({
    required bool isUniverseMode,
    required List<GlobePinData> pins,
    required int totalMemories,
  }) {
    final heading = isUniverseMode ? 'The Universe' : 'Globe Explorer';
    final subheading = isUniverseMode
        ? 'Explore your memory constellations'
        : 'Your memories pinned around the world';

    final headingColor = isUniverseMode ? Colors.white : const Color(0xFF0F172A);
    final subheadingColor = isUniverseMode ? const Color(0xFFD1D5DB) : const Color(0xFF64748B);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        children: [
          // Title & Sub-header Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  heading,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: headingColor,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subheading,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: subheadingColor,
                  ),
                ),
              ],
            ),
          ),

          // Right Action Icons (Filter, Search)
          _buildCircleActionButton(
            icon: Icons.tune_rounded,
            onTap: () => _showFilterModal(pins, totalMemories),
            isDark: isUniverseMode,
          ),
          const SizedBox(width: 8),
          _buildCircleActionButton(
            icon: Icons.search_rounded,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
            isDark: isUniverseMode,
          ),
        ],
      ),
    );
  }

  Widget _buildCircleActionButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isDark = false,
  }) {
    return Material(
      color: isDark ? const Color(0xFF262626) : Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark ? const Color(0xFF525252) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isDark ? Colors.white : const Color(0xFF334155),
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

  Widget _buildBottomCapsuleToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFF334155).withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Globe Tab
          GestureDetector(
            onTap: () => setState(() => _activeTab = 'globe'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              decoration: BoxDecoration(
                color: _activeTab == 'globe' ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.language_rounded,
                    size: 18,
                    color: _activeTab == 'globe' ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Globe',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _activeTab == 'globe' ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Universe Tab
          GestureDetector(
            onTap: () => setState(() => _activeTab = 'universe'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _activeTab == 'universe' ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 18,
                    color: _activeTab == 'universe' ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Universe',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _activeTab == 'universe' ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Constellation View in Grey[800] theme.
class ConstellationUniverseView extends StatefulWidget {
  final List<MemoryItem> memories;
  final String? selectedCategory;
  final String? selectedNodeId;
  final ValueChanged<String?> onCategorySelected;
  final ValueChanged<String?> onNodeSelected;

  const ConstellationUniverseView({
    super.key,
    required this.memories,
    required this.selectedCategory,
    required this.selectedNodeId,
    required this.onCategorySelected,
    required this.onNodeSelected,
  });

  @override
  State<ConstellationUniverseView> createState() => _ConstellationUniverseViewState();
}

class _ConstellationUniverseViewState extends State<ConstellationUniverseView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  List<String> _extractCategories() {
    final categories = {'All'};
    for (final m in widget.memories) {
      if (m.category.isNotEmpty) {
        categories.add(m.category);
      }
    }
    return categories.toList();
  }

  /// Calculates pseudo-random 2D positions for memory nodes across the sky canvas.
  List<ConstellationNode> _buildNodes(Size size) {
    final nodes = <ConstellationNode>[];
    if (widget.memories.isEmpty) return nodes;

    final count = widget.memories.length;
    for (int i = 0; i < count; i++) {
      final memory = widget.memories[i];
      final hash = (memory.id.hashCode ^ (memory.category.hashCode * 17)) & 0x7fffffff;
      final hashY = ((memory.title.hashCode * 31) ^ (i * 101)) & 0x7fffffff;

      // Spread evenly in normalized space (0.12..0.88, 0.14..0.76)
      final normX = 0.12 + 0.76 * ((hash % 1000) / 1000.0);
      final normY = 0.14 + 0.62 * ((hashY % 1000) / 1000.0);

      nodes.add(
        ConstellationNode(
          index: i,
          memory: memory,
          position: Offset(normX * size.width, normY * size.height),
          color: AtlasCategory.color(memory.category),
        ),
      );
    }
    return nodes;
  }

  /// Builds constellation links (edges) between nodes.
  List<ConstellationEdge> _buildEdges(List<ConstellationNode> nodes) {
    final edges = <ConstellationEdge>[];
    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        // Connect nodes in the same category
        if (nodes[i].memory.category == nodes[j].memory.category) {
          edges.add(ConstellationEdge(i, j));
        } else {
          // Connect nearby nodes in distance to form constellation chains
          final dist = (nodes[i].position - nodes[j].position).distance;
          if (dist < 140) {
            edges.add(ConstellationEdge(i, j));
          }
        }
      }
    }
    return edges;
  }

  @override
  Widget build(BuildContext context) {
    final categories = _extractCategories();

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final nodes = _buildNodes(size);
        final edges = _buildEdges(nodes);

        // Filter visible nodes if category is selected
        final filteredNodes = widget.selectedCategory == null || widget.selectedCategory == 'All'
            ? nodes
            : nodes.where((n) => n.memory.category == widget.selectedCategory).toList();

        // Selected Node & Connected Siblings
        ConstellationNode? selectedNode;
        final connectedNodeIds = <String>{};

        if (widget.selectedNodeId != null) {
          final selectedIdx = nodes.indexWhere((n) => n.memory.id == widget.selectedNodeId);
          if (selectedIdx != -1) {
            selectedNode = nodes[selectedIdx];
            connectedNodeIds.add(selectedNode.memory.id);

            for (final edge in edges) {
              if (edge.sourceIndex == selectedIdx) {
                connectedNodeIds.add(nodes[edge.targetIndex].memory.id);
              } else if (edge.targetIndex == selectedIdx) {
                connectedNodeIds.add(nodes[edge.sourceIndex].memory.id);
              }
            }
          }
        }

        return Stack(
          children: [
            // 1. Constellation Canvas in Grey[800]
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) {
                final tapPos = details.localPosition;
                ConstellationNode? closest;
                double minDist = 40.0; // Touch radius threshold

                for (final node in filteredNodes) {
                  final dist = (node.position - tapPos).distance;
                  if (dist < minDist) {
                    minDist = dist;
                    closest = node;
                  }
                }

                if (closest != null) {
                  widget.onNodeSelected(closest.memory.id);
                } else {
                  widget.onNodeSelected(null);
                }
              },
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
                  return CustomPaint(
                    size: size,
                    painter: ConstellationCanvasPainter(
                      nodes: filteredNodes,
                      edges: edges,
                      selectedNodeId: widget.selectedNodeId,
                      connectedNodeIds: connectedNodeIds,
                      pulseValue: _pulseController.value,
                    ),
                  );
                },
              ),
            ),

            // 2. Category Filter Chips Bar (before the canvas)
            Positioned(
              top: 12,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: categories.length,
                  itemBuilder: (context, idx) {
                    final cat = categories[idx];
                    final isSelected = (cat == 'All' && (widget.selectedCategory == null || widget.selectedCategory == 'All')) ||
                        widget.selectedCategory == cat;

                    final chipBg = isSelected ? Colors.white : const Color(0xFF262626);
                    final chipBorder = isSelected ? Colors.white : const Color(0xFF525252);
                    final chipText = isSelected ? const Color(0xFF111827) : Colors.white;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => widget.onCategorySelected(cat == 'All' ? null : cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: chipBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: chipBorder, width: 1),
                          ),
                          child: Center(
                            child: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: chipText,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // 3. Floating Selected Memory Card Overlay
            if (selectedNode != null)
              Positioned(
                left: 20,
                right: 20,
                bottom: 120,
                child: ConstellationMemoryCard(
                  memory: selectedNode.memory,
                  onClose: () => widget.onNodeSelected(null),
                  onNext: () {
                    final index = filteredNodes.indexWhere((n) => n.memory.id == selectedNode!.memory.id);
                    if (index != -1 && filteredNodes.isNotEmpty) {
                      final nextIndex = (index + 1) % filteredNodes.length;
                      widget.onNodeSelected(filteredNodes[nextIndex].memory.id);
                    }
                  },
                  onPrevious: () {
                    final index = filteredNodes.indexWhere((n) => n.memory.id == selectedNode!.memory.id);
                    if (index != -1 && filteredNodes.isNotEmpty) {
                      final prevIndex = (index - 1 + filteredNodes.length) % filteredNodes.length;
                      widget.onNodeSelected(filteredNodes[prevIndex].memory.id);
                    }
                  },
                ),
              ),

            // 4. Bottom Instruction Pill
            if (selectedNode == null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 72,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF262626),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF525252)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: const Text(
                      'Select a star node to open card',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFE5E7EB),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class ConstellationNode {
  final int index;
  final MemoryItem memory;
  final Offset position;
  final Color color;

  ConstellationNode({
    required this.index,
    required this.memory,
    required this.position,
    required this.color,
  });
}

class ConstellationEdge {
  final int sourceIndex;
  final int targetIndex;

  ConstellationEdge(this.sourceIndex, this.targetIndex);
}

/// CustomPainter for rendering constellation canvas in Grey[800] theme.
class ConstellationCanvasPainter extends CustomPainter {
  final List<ConstellationNode> nodes;
  final List<ConstellationEdge> edges;
  final String? selectedNodeId;
  final Set<String> connectedNodeIds;
  final double pulseValue;

  ConstellationCanvasPainter({
    required this.nodes,
    required this.edges,
    required this.selectedNodeId,
    required this.connectedNodeIds,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Grey[800] Background Painting
    final bgRect = Offset.zero & size;
    final bgPaint = Paint();

    final bgGradient = RadialGradient(
      center: const Alignment(0, -0.2),
      radius: 1.3,
      colors: const [
        Color(0xFF525252),
        Color(0xFF424242), // Colors.grey[800]
        Color(0xFF262626),
      ],
    );
    bgPaint.shader = bgGradient.createShader(bgRect);
    canvas.drawRect(bgRect, bgPaint);

    // 2. Background Stardust Field
    final starPaint = Paint();
    final random = math.Random(42);
    for (int i = 0; i < 70; i++) {
      final sx = random.nextDouble() * size.width;
      final sy = random.nextDouble() * size.height;
      final opacity = (0.2 + 0.6 * random.nextDouble()) * (0.8 + 0.2 * math.sin(pulseValue * math.pi * 2 + i));

      starPaint.color = Colors.white.withValues(alpha: (opacity * 0.55).clamp(0.1, 0.7));
      canvas.drawCircle(Offset(sx, sy), random.nextDouble() * 1.5 + 0.5, starPaint);
    }

    final hasSelection = selectedNodeId != null;

    // 3. Constellation Connection Lines (Edges)
    for (final edge in edges) {
      if (edge.sourceIndex >= nodes.length || edge.targetIndex >= nodes.length) continue;
      final p1 = nodes[edge.sourceIndex].position;
      final p2 = nodes[edge.targetIndex].position;

      final isSourceSelected = nodes[edge.sourceIndex].memory.id == selectedNodeId;
      final isTargetSelected = nodes[edge.targetIndex].memory.id == selectedNodeId;
      final isConnectedEdge = isSourceSelected || isTargetSelected;

      Paint linePaint;
      if (isConnectedEdge) {
        linePaint = Paint()
          ..color = Colors.white
          ..strokeWidth = 2.2
          ..style = PaintingStyle.stroke;
        canvas.drawLine(p1, p2, linePaint);
      } else if (hasSelection) {
        linePaint = Paint()
          ..color = const Color(0xFF9CA3AF).withValues(alpha: 0.15)
          ..strokeWidth = 0.8
          ..style = PaintingStyle.stroke;
        _drawDashedLine(canvas, p1, p2, linePaint);
      } else {
        linePaint = Paint()
          ..color = const Color(0xFF9CA3AF).withValues(alpha: 0.40)
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;
        _drawDashedLine(canvas, p1, p2, linePaint);
      }
    }

    // 4. Star Nodes & Title Labels
    for (final node in nodes) {
      final isSelected = node.memory.id == selectedNodeId;
      final isConnected = connectedNodeIds.contains(node.memory.id);

      final pos = node.position;

      if (isSelected) {
        // Glowing Aura Ring
        final auraRadius = 14.0 + 4.0 * pulseValue;
        final auraPaint = Paint()
          ..color = node.color.withValues(alpha: 0.50)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawCircle(pos, auraRadius, auraPaint);

        // Core Glowing Star
        final corePaint = Paint()..color = Colors.white;
        canvas.drawCircle(pos, 6.5, corePaint);

        final ringBorder = Paint()
          ..color = node.color
          ..strokeWidth = 2.2
          ..style = PaintingStyle.stroke;
        canvas.drawCircle(pos, 6.5, ringBorder);
      } else if (isConnected) {
        final dotPaint = Paint()..color = node.color;
        canvas.drawCircle(pos, 5.5, dotPaint);

        final centerDot = Paint()..color = Colors.white;
        canvas.drawCircle(pos, 2.5, centerDot);
      } else {
        final dimAlpha = hasSelection ? 0.35 : 0.85;
        final dotPaint = Paint()..color = node.color.withValues(alpha: dimAlpha);
        canvas.drawCircle(pos, 4.0, dotPaint);
      }

      // Render Title Label next to node
      final textColor = isSelected
          ? Colors.white
          : isConnected
              ? Colors.white
              : Colors.white.withValues(alpha: hasSelection ? 0.40 : 0.80);

      final textStyle = TextStyle(
        color: textColor,
        fontSize: isSelected ? 12 : 10.5,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        shadows: [
          BoxShadow(
            color: node.color.withValues(alpha: 0.7),
            blurRadius: 8,
          ),
        ],
      );

      final textSpan = TextSpan(text: node.memory.title, style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        maxLines: 1,
      );
      textPainter.layout();

      // Position label neatly near the node dot
      final labelOffset = Offset(pos.dx - textPainter.width / 2, pos.dy + 10);
      textPainter.paint(canvas, labelOffset);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    final count = (distance / (dashWidth + dashSpace)).floor();

    for (int i = 0; i < count; i++) {
      final startFrac = (i * (dashWidth + dashSpace)) / distance;
      final endFrac = (i * (dashWidth + dashSpace) + dashWidth) / distance;
      final start = Offset(p1.dx + dx * startFrac, p1.dy + dy * startFrac);
      final end = Offset(p1.dx + dx * endFrac, p1.dy + dy * endFrac);
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ConstellationCanvasPainter oldDelegate) => true;
}

/// Floating memory card pop-up overlay for the selected star node.
class ConstellationMemoryCard extends StatelessWidget {
  final MemoryItem memory;
  final VoidCallback onClose;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const ConstellationMemoryCard({
    super.key,
    required this.memory,
    required this.onClose,
    required this.onNext,
    required this.onPrevious,
  });

  int _calculateReadTime(String text) {
    if (text.isEmpty) return 2;
    final words = text.trim().split(RegExp(r'\s+')).length;
    return math.max(1, (words / 25).ceil());
  }

  @override
  Widget build(BuildContext context) {
    final accent = AtlasCategory.color(memory.category);

    return Material(
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.5),
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: accent.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Category Chip, Read Time, and Close Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    memory.category.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: accent,
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
                      '${_calculateReadTime(memory.aiSummary)} min read',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onClose,
                      child: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Title
            Text(
              memory.title,
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

            // Description / AI Summary
            Text(
              memory.aiSummary.isNotEmpty ? memory.aiSummary : memory.subtitle,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF475569),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),

            // Divider
            Container(
              height: 1,
              color: const Color(0xFFF1F5F9),
            ),
            const SizedBox(height: 8),

            // Footer Row: Cycle Controls & ...more >
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: onPrevious,
                      child: const Icon(
                        Icons.arrow_back_ios_rounded,
                        size: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Star Node Card',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onNext,
                      child: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => DetailScreen(memory: memory),
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

    // 6. Glowing Orbital Rings / Nodes
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
