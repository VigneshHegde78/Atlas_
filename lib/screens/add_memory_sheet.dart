import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/memory_provider.dart';
import '../theme/app_theme.dart';

/// Bottom sheet used by the center (+) tab to add new data into memory.
class AddMemorySheet extends StatefulWidget {
  const AddMemorySheet({super.key});

  @override
  State<AddMemorySheet> createState() => _AddMemorySheetState();
}

class _AddMemorySheetState extends State<AddMemorySheet> {
  static const List<String> _categories = [
    'Design Systems',
    'Recipes',
    'Travel',
    'Shopping',
    'Finance',
    'Work',
    'Development',
    'Reference',
    'Shared',
    'Uncategorized',
  ];

  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  String _category = 'Uncategorized';

  @override
  void dispose() {
    _contentController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _save() {
    final content = _contentController.text.trim();
    final url = _urlController.text.trim();
    if (content.isEmpty && url.isEmpty) return;
    Provider.of<MemoryProvider>(context, listen: false)
        .addMemoryManually(content: content, url: url, category: _category);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.82;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 14, 4),
              child: Row(
                children: [
                  const Text(
                    'New Memory',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AtlasColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: Colors.grey.shade500),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _field(
                      controller: _contentController,
                      hint: 'Write your note...',
                      icon: Icons.notes_rounded,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 12),
                    _field(
                      controller: _urlController,
                      hint: 'Paste a link (optional)',
                      icon: Icons.link_rounded,
                      maxLines: 1,
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'CATEGORY',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final c in _categories) _categoryPill(c),
                      ],
                    ),
                    const SizedBox(height: 22),
                    AnimatedBuilder(
                      animation: Listenable.merge([_contentController, _urlController]),
                      builder: (context, _) {
                        final enabled = _contentController.text.trim().isNotEmpty ||
                            _urlController.text.trim().isNotEmpty;
                        return SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: enabled ? _save : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AtlasColors.blue,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey.shade200,
                              disabledForegroundColor: Colors.grey.shade500,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(27),
                              ),
                              elevation: enabled ? 4 : 0,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_rounded, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Save to Memory',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      minLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AtlasColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade400,
        ),
        prefixIcon: Icon(icon, size: 18, color: AtlasColors.blue),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AtlasColors.blue, width: 1.5),
        ),
      ),
    );
  }

  Widget _categoryPill(String category) {
    final selected = _category == category;
    return GestureDetector(
      onTap: () => setState(() => _category = category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AtlasColors.blue : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AtlasColors.blue : Colors.transparent,
          ),
        ),
        child: Text(
          category,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}
