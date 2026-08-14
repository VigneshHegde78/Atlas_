import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/memory_provider.dart';
import '../theme/app_theme.dart';
import 'detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _hasResults = false;
  String _queryText = '';

  void _onSearchChanged(String val) {
    setState(() {
      _queryText = val;
      _hasResults = val.length >= 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final memoryProvider = Provider.of<MemoryProvider>(context);

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
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AtlasColors.textPrimary,
          ),
          decoration: const InputDecoration(
            hintText: 'That internship from June...',
            hintStyle: TextStyle(
              color: Colors.black26,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
            border: InputBorder.none,
          ),
        ),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                _buildQuickChip('Recipe with paneer'),
                const SizedBox(width: 8),
                _buildQuickChip('Shoes under ₹3000'),
                const SizedBox(width: 8),
                _buildQuickChip('Tokyo flights'),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.black12),

          Expanded(
            child: !_hasResults
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 48,
                          color: AtlasColors.purple.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Search your saved memories with natural language',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                  border: Border.all(color: Colors.grey.shade100),
                                ),
                                child: Text.rich(
                                  TextSpan(
                                    text: 'I found 1 saved item matching your search for ',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AtlasColors.textPrimary,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: '"$_queryText"',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: AtlasColors.blue,
                                        ),
                                      ),
                                      const TextSpan(text: ' based on the text read inside the image/link.'),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => DetailScreen(
                                  memory: memoryProvider.memories.firstWhere(
                                    (m) => m.id == '2',
                                    orElse: () => memoryProvider.memories.first,
                                  ),
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(28),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [AtlasTheme.softShadow],
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: double.infinity,
                                  height: 160,
                                  decoration: BoxDecoration(
                                    color: AtlasColors.emeraldLight.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(
                                            Icons.image_rounded,
                                            size: 44,
                                            color: AtlasColors.emerald,
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'SCREENSHOT',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              color: AtlasColors.emerald,
                                              letterSpacing: 1.0,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Positioned(
                                        bottom: 12,
                                        left: 12,
                                        right: 12,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.9),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Text(
                                            'Extracted: "...marinate paneer cubes in yogurt..."',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AtlasColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Text(
                                    'Paneer Tikka Recipe',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AtlasColors.blue,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Text(
                                    'Saved from Instagram • Yesterday',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
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

  Widget _buildQuickChip(String label) {
    return InkWell(
      onTap: () {
        _searchController.text = label;
        _onSearchChanged(label);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}
