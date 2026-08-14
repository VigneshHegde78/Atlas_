import 'dart:io';
import 'package:flutter/material.dart';
import '../models/memory_item.dart';
import '../theme/app_theme.dart';

class DetailScreen extends StatelessWidget {
  final MemoryItem memory;

  const DetailScreen({super.key, required this.memory});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AtlasColors.surface,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 280,
                  color: memory.iconBgColor,
                  child: memory.imageBytes != null
                      ? Image.memory(memory.imageBytes!, fit: BoxFit.cover)
                      : (memory.imagePath != null
                          ? Image.file(File(memory.imagePath!), fit: BoxFit.cover)
                          : Center(
                              child: Icon(
                                memory.iconData,
                                size: 80,
                                color: AtlasColors.blue.withOpacity(0.4),
                              ),
                            )),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(0.9),
                          radius: 22,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_rounded, size: 18, color: AtlasColors.blue),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                        CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(0.9),
                          radius: 22,
                          child: IconButton(
                            icon: const Icon(Icons.share_rounded, size: 18, color: AtlasColors.blue),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Sharing memory link...')),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            Transform.translate(
              offset: const Offset(0, -28),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28.0),
                decoration: const BoxDecoration(
                  color: AtlasColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(Icons.language_rounded, size: 14, color: Colors.grey),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${memory.sourceApp.toUpperCase()} • JUST NOW',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.grey.shade500,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Text(
                      memory.title,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AtlasColors.blue,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [AtlasTheme.softShadow],
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ShaderMask(
                                shaderCallback: (bounds) => const LinearGradient(
                                  colors: [AtlasColors.purple, Colors.blueAccent],
                                ).createShader(bounds),
                                child: const Icon(
                                  Icons.auto_awesome_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 8),
                              ShaderMask(
                                shaderCallback: (bounds) => const LinearGradient(
                                  colors: [AtlasColors.purple, Colors.blueAccent],
                                ).createShader(bounds),
                                child: const Text(
                                  'UNDERSTANDING',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            memory.aiSummary,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Opening ${memory.title}...')),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AtlasColors.blue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 4,
                              ),
                              child: const Text(
                                'Open Link',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.bookmark_outline_rounded, color: AtlasColors.blue, size: 22),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Bookmarked memory!')),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    const Text(
                      'Related Memories',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AtlasColors.blue,
                      ),
                    ),
                    const SizedBox(height: 14),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Center(
                              child: Icon(Icons.palette_rounded, color: Colors.grey, size: 20),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'UI Inspiration Board',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AtlasColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Collection • 4 items',
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
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
