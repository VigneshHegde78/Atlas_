import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/memory_provider.dart';
import '../theme/app_theme.dart';

enum AddMemoryTab {
  note,
  voice,
  document,
}

class AddMemorySheet extends StatefulWidget {
  const AddMemorySheet({super.key});

  @override
  State<AddMemorySheet> createState() => _AddMemorySheetState();
}

class _AddMemorySheetState extends State<AddMemorySheet> with SingleTickerProviderStateMixin {
  static const List<String> _categories = [
    'Finance',
    'Recipes',
    'Travel',
    'Development',
    'Design Systems',
    'Shopping',
    'Work',
    'Reference',
    'Uncategorized',
  ];

  AddMemoryTab _currentTab = AddMemoryTab.note;

  // Note & Link Controllers
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();

  // Voice Memo State
  bool _isRecording = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;
  final TextEditingController _voiceTranscriptController = TextEditingController();

  // Document State
  final TextEditingController _docTitleController = TextEditingController();
  final TextEditingController _docContentController = TextEditingController();
  String _selectedDocFileName = 'Document.pdf';
  int _docPageCount = 1;

  String _category = 'Uncategorized';

  late final AnimationController _pulseAnimController;

  @override
  void initState() {
    super.initState();
    _pulseAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _pulseAnimController.dispose();
    _contentController.dispose();
    _urlController.dispose();
    _voiceTranscriptController.dispose();
    _docTitleController.dispose();
    _docContentController.dispose();
    super.dispose();
  }

  void _toggleRecording() {
    HapticFeedback.mediumImpact();
    if (_isRecording) {
      _recordTimer?.cancel();
      setState(() {
        _isRecording = false;
        if (_voiceTranscriptController.text.trim().isEmpty) {
          _voiceTranscriptController.text =
              'Sprint planning and product release roadmap discussion. Core tasks scheduled for deployment by Thursday.';
        }
      });
    } else {
      setState(() {
        _isRecording = true;
        _recordSeconds = 0;
        _voiceTranscriptController.text = 'Listening and transcribing audio note...';
      });
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          _recordSeconds++;
          if (_recordSeconds == 2) {
            _voiceTranscriptController.text =
                'Discussing system architecture and roadmap priorities...';
          } else if (_recordSeconds == 4) {
            _voiceTranscriptController.text =
                'Discussing system architecture and roadmap priorities. Sprint tasks scheduled for completion by Thursday.';
          } else if (_recordSeconds >= 7) {
            _voiceTranscriptController.text =
                'Discussing system architecture and roadmap priorities. Sprint tasks scheduled for completion by Thursday. Action items assigned to engineering team.';
          }
        });
      });
    }
  }

  void _selectVoicePrompt(String prompt) {
    HapticFeedback.selectionClick();
    setState(() {
      _voiceTranscriptController.text = prompt;
    });
  }

  void _loadSampleDocument(String title, String fileName, int pages, String content) {
    setState(() {
      _docTitleController.text = title;
      _selectedDocFileName = fileName;
      _docPageCount = pages;
      _docContentController.text = content;
    });
  }

  void _save() {
    final provider = Provider.of<MemoryProvider>(context, listen: false);

    if (_currentTab == AddMemoryTab.note) {
      final content = _contentController.text.trim();
      final url = _urlController.text.trim();
      if (content.isEmpty && url.isEmpty) return;
      provider.addMemoryManually(content: content, url: url, category: _category);
    } else if (_currentTab == AddMemoryTab.voice) {
      var transcript = _voiceTranscriptController.text.trim();
      if (transcript.isEmpty || transcript.startsWith('Listening')) {
        transcript =
            'Audio voice memo recorded on ${DateTime.now().month}/${DateTime.now().day}. Discussion points and transcript indexed into ATLAS.';
      }
      provider.addVoiceMemory(
        transcript: transcript,
        duration: Duration(seconds: _recordSeconds > 0 ? _recordSeconds : 15),
        category: _category,
      );
    } else if (_currentTab == AddMemoryTab.document) {
      final title = _docTitleController.text.trim();
      final content = _docContentController.text.trim();
      if (title.isEmpty && content.isEmpty) return;
      provider.addDocumentMemory(
        title: title.isNotEmpty ? title : 'Document PDF',
        content: content.isNotEmpty ? content : 'PDF document indexed into ATLAS memory vault.',
        fileName: _selectedDocFileName,
        pageCount: _docPageCount,
        category: _category,
      );
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;

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
                    'Capture Memory',
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

            // Tab Switcher Capsules
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    _buildTabButton(AddMemoryTab.note, 'Note & Link', Icons.edit_note_rounded),
                    _buildTabButton(AddMemoryTab.voice, 'Voice Memo', Icons.mic_rounded),
                    _buildTabButton(AddMemoryTab.document, 'PDF / Doc', Icons.picture_as_pdf_rounded),
                  ],
                ),
              ),
            ),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_currentTab == AddMemoryTab.note) _buildNoteSection(),
                    if (_currentTab == AddMemoryTab.voice) _buildVoiceSection(),
                    if (_currentTab == AddMemoryTab.document) _buildDocumentSection(),

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

                    // Save Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(27),
                          ),
                          elevation: 2,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_rounded, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Save to ATLAS',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
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
        ),
      ),
    );
  }

  Widget _buildTabButton(AddMemoryTab tab, String label, IconData icon) {
    final isSelected = _currentTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            _currentTab = tab;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? const Color(0xFF0F172A) : Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? const Color(0xFF0F172A) : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoteSection() {
    return Column(
      children: [
        _field(
          controller: _contentController,
          hint: 'Write your note or thoughts...',
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
      ],
    );
  }

  Widget _buildVoiceSection() {
    final mins = _recordSeconds ~/ 60;
    final secs = _recordSeconds % 60;
    final timeStr = '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Voice Recorder Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              // Live Timer & Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _isRecording ? Colors.redAccent : Colors.grey.shade400,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isRecording ? 'RECORDING LIVE' : 'VOICE RECORDER',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: _isRecording ? Colors.redAccent : const Color(0xFF0F172A),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _isRecording ? timeStr : (_recordSeconds > 0 ? timeStr : '00:15'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Solid Waveform Bars
              SizedBox(
                height: 38,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(24, (index) {
                    final waveHeight = _isRecording
                        ? 8.0 + (math.sin(index * 0.6 + _pulseAnimController.value * math.pi * 2).abs() * 26)
                        : 6.0 + (index % 5) * 4;
                    return Container(
                      width: 4,
                      height: waveHeight,
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      decoration: BoxDecoration(
                        color: _isRecording
                            ? Colors.redAccent
                            : const Color(0xFF334155),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 20),

              // Solid High-Contrast Mic Button
              GestureDetector(
                onTap: _toggleRecording,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isRecording ? Colors.redAccent : const Color(0xFF0F172A),
                    boxShadow: [
                      BoxShadow(
                        color: (_isRecording ? Colors.redAccent : Colors.black)
                            .withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _isRecording ? 'Tap to finish recording' : 'Tap to record voice memo',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Quick Speech Suggestions
        const Text(
          'Quick Voice Templates',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildVoicePresetChip(
              'Sprint Roadmap & Action Items',
              'Sprint planning roadmap review. Core deliverables scheduled for production deploy by Thursday.',
            ),
            _buildVoicePresetChip(
              'Product Architecture Decision',
              'Architecture review: utilizing SQLite embedded persistence with on-device OCR indexing for zero latency.',
            ),
            _buildVoicePresetChip(
              'Personal Reminder & Schedule',
              'Meeting with travel coordinator next Monday at 10:00 AM regarding flight bookings.',
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Auto Speech-to-Text Transcript Box
        _field(
          controller: _voiceTranscriptController,
          hint: 'Voice transcription will appear here...',
          icon: Icons.subtitles_rounded,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildVoicePresetChip(String label, String fullTranscript) {
    return InkWell(
      onTap: () => _selectVoicePrompt(fullTranscript),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mic_none_rounded, size: 13, color: Color(0xFF0F172A)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Document Presets / Quick Loaders
        const Text(
          'Quick Document Templates',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildDocPresetChip(
              'Quarterly Financial Review',
              'Q3_Finance_Review.pdf',
              12,
              'Consolidated revenue grew by 18.4% YoY. Operating margin improved by 230 bps driven by supply chain efficiencies and enterprise software tier growth.',
            ),
            _buildDocPresetChip(
              'System Architecture Whitepaper',
              'ATLAS_Architecture_v2.pdf',
              24,
              'Distributed local SQLite replication with on-device OCR pipeline and zero-latency embedding vectors for personal knowledge graphs.',
            ),
            _buildDocPresetChip(
              'Tokyo Travel Itinerary & Rail Pass',
              'Tokyo_Travel_Pass_2026.pdf',
              4,
              'JR Rail Pass active from Shibuya to Kyoto. Hotel reservation confirmed at Park Hyatt Tokyo with check-in at 3:00 PM.',
            ),
          ],
        ),
        const SizedBox(height: 16),

        _field(
          controller: _docTitleController,
          hint: 'Document Title (e.g. Q3 Report.pdf)',
          icon: Icons.title_rounded,
          maxLines: 1,
        ),
        const SizedBox(height: 10),
        _field(
          controller: _docContentController,
          hint: 'Document content / extracted searchable text...',
          icon: Icons.description_rounded,
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildDocPresetChip(String title, String fileName, int pages, String content) {
    final isSelected = _selectedDocFileName == fileName;
    return InkWell(
      onTap: () => _loadSampleDocument(title, fileName, pages, content),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A).withValues(alpha: 0.08) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F172A) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.picture_as_pdf_rounded, size: 14, color: isSelected ? const Color(0xFF0F172A) : Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(
              fileName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? const Color(0xFF0F172A) : Colors.grey.shade800,
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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AtlasColors.textPrimary,
        ),
        decoration: InputDecoration(
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Icon(icon, color: Colors.grey.shade500, size: 20),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.fromLTRB(4, 14, 16, 14),
        ),
      ),
    );
  }

  Widget _categoryPill(String cat) {
    final isSelected = _category == cat;
    return InkWell(
      onTap: () {
        setState(() {
          _category = cat;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          cat,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}
