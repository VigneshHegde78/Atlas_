import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/memory_item.dart';
import '../theme/app_theme.dart';
import 'detail_screen.dart';

class GraphNodeData {
  final int id;
  Offset position;
  final MemoryItem memory;
  final Color color;

  GraphNodeData({
    required this.id,
    required this.position,
    required this.memory,
    required this.color,
  });
}

class GraphEdgeData {
  final int sourceId;
  final int targetId;
  final double similarity; // 0.0 to 1.0 (e.g. 0.94 = 94% data similarity)
  final String label;

  GraphEdgeData({
    required this.sourceId,
    required this.targetId,
    required this.similarity,
    required this.label,
  });
}

class UniverseScreen extends StatefulWidget {
  const UniverseScreen({super.key});

  @override
  State<UniverseScreen> createState() => _UniverseScreenState();
}

class _UniverseScreenState extends State<UniverseScreen> with SingleTickerProviderStateMixin {
  String _viewMode = 'graph'; // 'graph' or 'globe'
  int _selectedNodeIndex = 0;

  double _globeAngleX = 0.2;
  double _globeAngleY = 0.0;

  late AnimationController _animController;

  final List<GraphNodeData> _nodes = [
    GraphNodeData(
      id: 0,
      position: const Offset(180, 140),
      memory: MemoryItem(
        id: '1',
        title: 'Linear Design System',
        subtitle: 'linear.app/docs',
        sourceApp: 'Arc Browser',
        type: MemoryType.link,
        savedAt: DateTime.now(),
        aiSummary: 'Minimalist interaction design system with high contrast navy palettes.',
        category: 'Design',
        iconBgColor: const Color(0xFFEFF6FF),
        iconData: Icons.link_rounded,
      ),
      color: const Color(0xFF3B82F6),
    ),
    GraphNodeData(
      id: 1,
      position: const Offset(270, 70),
      memory: MemoryItem(
        id: '2',
        title: 'Paneer Tikka Recipe',
        subtitle: 'Instagram Screenshot',
        sourceApp: 'Instagram',
        type: MemoryType.screenshot,
        savedAt: DateTime.now(),
        aiSummary: 'Spicy yogurt marination steps for authentic cottage cheese tikka.',
        category: 'Recipes',
        iconBgColor: AtlasColors.emeraldLight,
        iconData: Icons.image_rounded,
      ),
      color: AtlasColors.emerald,
    ),
    GraphNodeData(
      id: 2,
      position: const Offset(80, 250),
      memory: MemoryItem(
        id: '3',
        title: 'Airbnb Goa Booking',
        subtitle: 'Receipt PDF',
        sourceApp: 'Files',
        type: MemoryType.pdf,
        savedAt: DateTime.now(),
        aiSummary: 'Beach resort stay booking confirmation for October travel.',
        category: 'Travel',
        iconBgColor: AtlasColors.amberLight,
        iconData: Icons.picture_as_pdf_rounded,
      ),
      color: AtlasColors.amber,
    ),
    GraphNodeData(
      id: 3,
      position: const Offset(90, 80),
      memory: MemoryItem(
        id: '4',
        title: 'Interview Notes',
        subtitle: 'Technical Round',
        sourceApp: 'Notes',
        type: MemoryType.note,
        savedAt: DateTime.now(),
        aiSummary: 'System design principles & Flutter state management questions.',
        category: 'Work',
        iconBgColor: const Color(0xFFF3E8FF),
        iconData: Icons.description_rounded,
      ),
      color: AtlasColors.purple,
    ),
    GraphNodeData(
      id: 4,
      position: const Offset(290, 210),
      memory: MemoryItem(
        id: '5',
        title: 'Tokyo Flight Itinerary',
        subtitle: 'Safari Bookmark',
        sourceApp: 'Safari',
        type: MemoryType.link,
        savedAt: DateTime.now(),
        aiSummary: 'Direct flights options to Tokyo Haneda airport.',
        category: 'Travel',
        iconBgColor: const Color(0xFFE0F2FE),
        iconData: Icons.flight_takeoff_rounded,
      ),
      color: const Color(0xFF0284C7),
    ),
  ];

  final List<GraphEdgeData> _edges = [
    GraphEdgeData(sourceId: 2, targetId: 4, similarity: 0.94, label: 'Travel 94%'),
    GraphEdgeData(sourceId: 0, targetId: 3, similarity: 0.82, label: 'System Design 82%'),
    GraphEdgeData(sourceId: 0, targetId: 1, similarity: 0.68, label: 'Media UI 68%'),
    GraphEdgeData(sourceId: 3, targetId: 2, similarity: 0.58, label: 'Calendar 58%'),
  ];

  final List<GlobeMemoryNode> _globeNodes = [
    GlobeMemoryNode(
      memory: MemoryItem(
        id: '1',
        title: 'Linear Design System',
        subtitle: 'linear.app/docs',
        sourceApp: 'Arc Browser',
        type: MemoryType.link,
        savedAt: DateTime.now(),
        aiSummary: 'Minimalist interaction design system with high contrast navy palettes.',
        category: 'Design',
        iconBgColor: const Color(0xFFEFF6FF),
        iconData: Icons.link_rounded,
      ),
      lat: 0.2,
      lng: 0.5,
      color: const Color(0xFF3B82F6),
    ),
    GlobeMemoryNode(
      memory: MemoryItem(
        id: '2',
        title: 'Paneer Tikka Recipe',
        subtitle: 'Instagram Screenshot',
        sourceApp: 'Instagram',
        type: MemoryType.screenshot,
        savedAt: DateTime.now(),
        aiSummary: 'Spicy yogurt marination steps for authentic cottage cheese tikka.',
        category: 'Recipes',
        iconBgColor: AtlasColors.emeraldLight,
        iconData: Icons.image_rounded,
      ),
      lat: -0.4,
      lng: -0.8,
      color: AtlasColors.emerald,
    ),
    GlobeMemoryNode(
      memory: MemoryItem(
        id: '3',
        title: 'Airbnb Goa Booking',
        subtitle: 'Receipt PDF',
        sourceApp: 'Files',
        type: MemoryType.pdf,
        savedAt: DateTime.now(),
        aiSummary: 'Beach resort stay booking confirmation for October travel.',
        category: 'Travel',
        iconBgColor: AtlasColors.amberLight,
        iconData: Icons.picture_as_pdf_rounded,
      ),
      lat: 0.5,
      lng: -0.4,
      color: AtlasColors.amber,
    ),
    GlobeMemoryNode(
      memory: MemoryItem(
        id: '4',
        title: 'Interview Notes',
        subtitle: 'Technical Round',
        sourceApp: 'Notes',
        type: MemoryType.note,
        savedAt: DateTime.now(),
        aiSummary: 'System design principles & Flutter state management questions.',
        category: 'Work',
        iconBgColor: const Color(0xFFF3E8FF),
        iconData: Icons.description_rounded,
      ),
      lat: 0.3,
      lng: 1.2,
      color: AtlasColors.purple,
    ),
    GlobeMemoryNode(
      memory: MemoryItem(
        id: '5',
        title: 'Tokyo Flight Itinerary',
        subtitle: 'Safari Bookmark',
        sourceApp: 'Safari',
        type: MemoryType.link,
        savedAt: DateTime.now(),
        aiSummary: 'Direct flights options to Tokyo Haneda airport.',
        category: 'Travel',
        iconBgColor: const Color(0xFFE0F2FE),
        iconData: Icons.flight_takeoff_rounded,
      ),
      lat: -0.2,
      lng: 0.9,
      color: const Color(0xFF0284C7),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedNode = _nodes[_selectedNodeIndex];

    return Scaffold(
      backgroundColor: AtlasColors.surface,
      body: SafeArea(
        child: Stack(
          children: [
            // Top Navigation & Segmented View Switcher
            Positioned(
              top: 12,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Knowledge Graph',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AtlasColors.blue,
                            ),
                          ),
                          Text(
                            'Data Similarity & Semantic Connections',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 20,
                        child: IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20, color: AtlasColors.blue),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Segmented Control
                  Container(
                    width: 240,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _viewMode = 'graph'),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _viewMode == 'graph' ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: _viewMode == 'graph' ? [AtlasTheme.softShadow] : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.hub_rounded,
                                    size: 16,
                                    color: _viewMode == 'graph' ? AtlasColors.blue : Colors.grey,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Graph View',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: _viewMode == 'graph' ? AtlasColors.blue : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _viewMode = 'globe'),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _viewMode == 'globe' ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: _viewMode == 'globe' ? [AtlasTheme.softShadow] : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.public_rounded,
                                    size: 16,
                                    color: _viewMode == 'globe' ? AtlasColors.blue : Colors.grey,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Globe View',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: _viewMode == 'globe' ? AtlasColors.blue : Colors.grey,
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

            // Main Interactive Content Area
            Positioned.fill(
              top: 130,
              child: _viewMode == 'graph' ? _buildInteractiveGraphView(selectedNode) : _buildGlobeView(_globeNodes[_selectedNodeIndex]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveGraphView(GraphNodeData selectedNode) {
    return Column(
      children: [
        // Detail drawer card for selected knowledge node
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [AtlasTheme.softShadow],
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: selectedNode.color,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Icon(
                                selectedNode.memory.iconData,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    selectedNode.memory.category.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  selectedNode.memory.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AtlasColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => DetailScreen(memory: selectedNode.memory),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AtlasColors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: Row(
                        children: const [
                          Text('Inspect', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, size: 12),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  selectedNode.memory.aiSummary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Knowledge Graph Canvas with Draggable Nodes & Similarity Edges
        Expanded(
          child: Stack(
            children: [
              // Custom Similarity Edges & Pulse Particles Painter
              AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size.infinite,
                    painter: KnowledgeGraphPainter(
                      nodes: _nodes,
                      edges: _edges,
                      selectedIndex: _selectedNodeIndex,
                      animProgress: _animController.value,
                    ),
                  );
                },
              ),

              // Draggable Node Widgets
              ..._nodes.map((node) {
                final bool isSelected = _selectedNodeIndex == node.id;

                return Positioned(
                  left: node.position.dx - 40,
                  top: node.position.dy - 30,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        node.position += details.delta;
                      });
                    },
                    onTap: () {
                      setState(() {
                        _selectedNodeIndex = node.id;
                      });
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: isSelected ? 22 : 16,
                          height: isSelected ? 22 : 16,
                          decoration: BoxDecoration(
                            color: node.color,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: node.color.withOpacity(0.6),
                                blurRadius: isSelected ? 12 : 6,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.92),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? node.color : Colors.grey.shade200,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                            boxShadow: [AtlasTheme.softShadow],
                          ),
                          child: Text(
                            node.memory.title,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: AtlasColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              // Instruction Pill
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [AtlasTheme.softShadow],
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.auto_awesome_rounded, size: 14, color: AtlasColors.amber),
                        SizedBox(width: 8),
                        Text(
                          'Drag nodes to organize • Edge badges show data similarity',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AtlasColors.textPrimary,
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
    );
  }

  Widget _buildGlobeView(GlobeMemoryNode selectedNode) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [AtlasTheme.softShadow],
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: selectedNode.color,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Icon(
                              selectedNode.memory.iconData,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                selectedNode.memory.category.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              selectedNode.memory.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AtlasColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => DetailScreen(memory: selectedNode.memory),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AtlasColors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: Row(
                        children: const [
                          Text('Inspect', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, size: 12),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  selectedNode.memory.aiSummary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _globeAngleY += details.delta.dx * 0.008;
                _globeAngleX += details.delta.dy * 0.008;
                _globeAngleX = _globeAngleX.clamp(-1.2, 1.2);
              });
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size.infinite,
                  painter: Globe3DPainter(
                    angleX: _globeAngleX,
                    angleY: _globeAngleY,
                    nodes: _globeNodes,
                    selectedIndex: _selectedNodeIndex,
                  ),
                ),
                Positioned(
                  bottom: 24,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [AtlasTheme.softShadow],
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.sync_rounded, size: 14, color: AtlasColors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Drag to rotate 3D horizon globe • Tap nodes',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AtlasColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class KnowledgeGraphPainter extends CustomPainter {
  final List<GraphNodeData> nodes;
  final List<GraphEdgeData> edges;
  final int selectedIndex;
  final double animProgress;

  KnowledgeGraphPainter({
    required this.nodes,
    required this.edges,
    required this.selectedIndex,
    required this.animProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var edge in edges) {
      final source = nodes.firstWhere((n) => n.id == edge.sourceId);
      final target = nodes.firstWhere((n) => n.id == edge.targetId);

      final p1 = source.position;
      final p2 = target.position;

      final isConnectedToSelected = (source.id == selectedIndex || target.id == selectedIndex);

      // Edge similarity line paint
      final linePaint = Paint()
        ..color = isConnectedToSelected
            ? AtlasColors.purple.withOpacity(0.7)
            : AtlasColors.blue.withOpacity(edge.similarity * 0.35)
        ..strokeWidth = isConnectedToSelected ? 2.5 : (1.0 + edge.similarity * 1.5)
        ..style = PaintingStyle.stroke;

      // Draw Similarity Edge String Line
      canvas.drawLine(p1, p2, linePaint);

      // Animated Pulse Particle along the similarity edge line
      final double t = (animProgress + (edge.sourceId * 0.25)) % 1.0;
      final Offset pulsePos = Offset(
        p1.dx + (p2.dx - p1.dx) * t,
        p1.dy + (p2.dy - p1.dy) * t,
      );

      final pulsePaint = Paint()
        ..color = isConnectedToSelected ? AtlasColors.purple : AtlasColors.emerald;
      canvas.drawCircle(pulsePos, 3.5, pulsePaint);

      // Draw Similarity Badge Label Pill at Midpoint
      final Offset mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);

      final textSpan = TextSpan(
        text: edge.label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: isConnectedToSelected ? AtlasColors.purple : Colors.grey.shade700,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final bgRect = Rect.fromCenter(
        center: mid,
        width: textPainter.width + 12,
        height: textPainter.height + 6,
      );

      final badgeBgPaint = Paint()
        ..color = Colors.white.withOpacity(0.95)
        ..style = PaintingStyle.fill;

      final badgeBorderPaint = Paint()
        ..color = isConnectedToSelected ? AtlasColors.purple : Colors.grey.shade300
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      canvas.drawRRect(RRect.fromRectAndRadius(bgRect, const Radius.circular(8)), badgeBgPaint);
      canvas.drawRRect(RRect.fromRectAndRadius(bgRect, const Radius.circular(8)), badgeBorderPaint);

      textPainter.paint(
        canvas,
        Offset(mid.dx - textPainter.width / 2, mid.dy - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant KnowledgeGraphPainter oldDelegate) => true;
}

class Globe3DPainter extends CustomPainter {
  final double angleX;
  final double angleY;
  final List<GlobeMemoryNode> nodes;
  final int selectedIndex;

  Globe3DPainter({
    required this.angleX,
    required this.angleY,
    required this.nodes,
    required this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height * 0.75;
    final radius = math.min(size.width, size.height) * 0.65;

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF3B82F6).withOpacity(0.15),
          const Color(0xFF9333EA).withOpacity(0.05),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(centerX, centerY), radius: radius * 1.1));
    canvas.drawCircle(Offset(centerX, centerY), radius * 1.1, glowPaint);

    final meshPaint = Paint()
      ..color = const Color(0xFF0F172A).withOpacity(0.08)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (double lat = -0.6; lat <= 0.6; lat += 0.3) {
      final path = Path();
      bool first = true;
      for (double lng = 0; lng <= math.pi * 2; lng += 0.1) {
        final cosX = math.cos(angleX);
        final sinX = math.sin(angleX);
        final cosY = math.cos(angleY + lng);
        final sinY = math.sin(angleY + lng);
        final cosLat = math.cos(lat);
        final sinLat = math.sin(lat);

        final x = radius * cosLat * sinY;
        final y = radius * (sinLat * cosX - cosLat * sinX * cosY);
        final z = radius * (sinLat * sinX + cosLat * cosX * cosY);

        if (z > -radius * 0.2) {
          final screenX = centerX + x;
          final screenY = centerY - y;
          if (first) {
            path.moveTo(screenX, screenY);
            first = false;
          } else {
            path.lineTo(screenX, screenY);
          }
        }
      }
      canvas.drawPath(path, meshPaint);
    }

    final domePaint = Paint()
      ..color = const Color(0xFF0F172A).withOpacity(0.15)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(centerX, centerY), radius, domePaint);

    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      final cosX = math.cos(angleX);
      final sinX = math.sin(angleX);
      final cosY = math.cos(angleY + node.lng);
      final sinY = math.sin(angleY + node.lng);
      final cosLat = math.cos(node.lat);
      final sinLat = math.sin(node.lat);

      final x = radius * cosLat * sinY;
      final y = radius * (sinLat * cosX - cosLat * sinX * cosY);
      final z = radius * (sinLat * sinX + cosLat * cosX * cosY);

      if (z > -radius * 0.25) {
        final screenX = centerX + x;
        final screenY = centerY - y;
        final isSelected = i == selectedIndex;

        final linePaint = Paint()
          ..color = node.color.withOpacity(isSelected ? 0.6 : 0.2)
          ..strokeWidth = isSelected ? 1.5 : 0.8;
        canvas.drawLine(Offset(centerX, centerY), Offset(screenX, screenY), linePaint);

        final dotPaint = Paint()..color = node.color;
        canvas.drawCircle(Offset(screenX, screenY), isSelected ? 8 : 5, dotPaint);

        final corePaint = Paint()..color = Colors.white;
        canvas.drawCircle(Offset(screenX, screenY), 2, corePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant Globe3DPainter oldDelegate) =>
      oldDelegate.angleX != angleX || oldDelegate.angleY != angleY || oldDelegate.selectedIndex != selectedIndex;
}
