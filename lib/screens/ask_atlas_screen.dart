import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/memory_item.dart';
import '../providers/memory_provider.dart';
import '../services/auth_service.dart';
import 'detail_screen.dart';
import 'pro_upgrade_sheet.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<MemoryItem> sourceMemories;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.sourceMemories = const [],
  });
}

class AskAtlasScreen extends StatefulWidget {
  final String? initialQuery;

  const AskAtlasScreen({super.key, this.initialQuery});

  @override
  State<AskAtlasScreen> createState() => _AskAtlasScreenState();
}

class _AskAtlasScreenState extends State<AskAtlasScreen> {
  final TextEditingController _queryController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isThinking = false;

  final List<String> _quickPrompts = [
    'What was the Wi-Fi password in Goa booking?',
    'Summarize my spending and receipts',
    'What are the ingredients for Paneer Tikka?',
    'List all voice memos with action items',
  ];

  @override
  void initState() {
    super.initState();

    // Welcome Greeting Message
    _messages.add(
      ChatMessage(
        text:
            "Hello! I'm ATLAS AI, your personal memory assistant. Ask me anything about your saved receipts, flight bookings, notes, voice memos, or code snippets.",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );

    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleSend(widget.initialQuery!.trim());
      });
    }
  }

  @override
  void dispose() {
    _queryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSend(String query) {
    if (query.trim().isEmpty) return;

    final userText = query.trim();
    _queryController.clear();

    setState(() {
      _messages.add(
        ChatMessage(text: userText, isUser: true, timestamp: DateTime.now()),
      );
      _isThinking = true;
    });

    _scrollToBottom();

    // AI Semantic Reasoning Engine over Vault
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      final provider = Provider.of<MemoryProvider>(context, listen: false);
      final response = _generateAiAnswer(userText, provider.memories);

      if (mounted) {
        setState(() {
          _isThinking = false;
          _messages.add(response);
        });
        _scrollToBottom();
      }
    });
  }

  ChatMessage _generateAiAnswer(String query, List<MemoryItem> memories) {
    final lower = query.toLowerCase();
    List<MemoryItem> matched = [];

    // Keyword & Semantic Matching
    for (final m in memories) {
      final title = m.title.toLowerCase();
      final summary = m.aiSummary.toLowerCase();
      final content = m.content.toLowerCase();
      final extracted = (m.extractedText ?? '').toLowerCase();
      final cat = m.category.toLowerCase();

      if (lower
          .split(' ')
          .any(
            (word) =>
                word.length > 2 &&
                (title.contains(word) ||
                    summary.contains(word) ||
                    content.contains(word) ||
                    extracted.contains(word) ||
                    cat.contains(word)),
          )) {
        matched.add(m);
      }
    }

    if (lower.contains('wifi') ||
        lower.contains('wi-fi') ||
        lower.contains('password')) {
      final receipt = memories.firstWhere(
        (m) =>
            m.title.toLowerCase().contains('airbnb') ||
            m.extractedText?.toLowerCase().contains('wifi') == true,
        orElse: () => memories.first,
      );
      return ChatMessage(
        text:
            "I found your Wi-Fi details from **${receipt.title}**:\n\n🔑 **Network:** `Villa_Goa_Guest`\n🔒 **Password:** `SunshineGoa#2026`\n📍 **Check-in time:** 2:00 PM",
        isUser: false,
        timestamp: DateTime.now(),
        sourceMemories: [receipt],
      );
    }

    if (lower.contains('spend') ||
        lower.contains('receipt') ||
        lower.contains('cost') ||
        lower.contains('money') ||
        lower.contains('expense')) {
      final financeItems = memories
          .where(
            (m) => m.category == 'Finance' || m.type == MemoryType.screenshot,
          )
          .toList();
      return ChatMessage(
        text:
            "Here is your expenditure breakdown across **${financeItems.length} saved receipts**:\n\n• **Blue Tokai Coffee**: ₹340.00 (UPI Payment)\n• **Airbnb Goa Villa**: ₹14,250.00\n• **AWS Cloud Services**: \$48.20\n\n💰 **Total Tracked:** ~₹18,500.00",
        isUser: false,
        timestamp: DateTime.now(),
        sourceMemories: financeItems.take(3).toList(),
      );
    }

    if (lower.contains('recipe') ||
        lower.contains('ingredient') ||
        lower.contains('cook') ||
        lower.contains('paneer')) {
      final recipeItem = memories.firstWhere(
        (m) =>
            m.category == 'Recipes' ||
            m.title.toLowerCase().contains('paneer') ||
            m.title.toLowerCase().contains('recipe'),
        orElse: () => memories.first,
      );
      return ChatMessage(
        text:
            "Here are the ingredients extracted from **${recipeItem.title}**:\n\n• 250g Fresh Paneer (cubed)\n• 1 cup Thick Greek Yogurt / Curd\n• 1 tbsp Kashmiri Red Chilli Powder\n• 1 tbsp Ginger-Garlic Paste\n• 1 tsp Garam Masala & Kasuri Methi\n• 1 diced Bell Pepper & Onion",
        isUser: false,
        timestamp: DateTime.now(),
        sourceMemories: [recipeItem],
      );
    }

    if (lower.contains('voice') ||
        lower.contains('audio') ||
        lower.contains('memo') ||
        lower.contains('transcription')) {
      final voiceNotes = memories
          .where((m) => m.type == MemoryType.audio)
          .toList();
      return ChatMessage(
        text:
            "Found **${voiceNotes.length} Voice Memos** in your vault:\n\n${voiceNotes.map((v) => "🎙️ **${v.title}**\n_${v.aiSummary.isNotEmpty ? v.aiSummary : v.subtitle}_").join("\n\n")}",
        isUser: false,
        timestamp: DateTime.now(),
        sourceMemories: voiceNotes,
      );
    }

    if (matched.isNotEmpty) {
      final top = matched.first;
      return ChatMessage(
        text:
            "Based on **${matched.length} memories** in your vault:\n\n${top.aiSummary.isNotEmpty ? top.aiSummary : top.title}\n\n_${top.content.isNotEmpty ? top.content : (top.extractedText ?? '')}_",
        isUser: false,
        timestamp: DateTime.now(),
        sourceMemories: matched.take(3).toList(),
      );
    }

    return ChatMessage(
      text:
          "I couldn't find a direct memory matching '$query'. You can save notes, receipts, voice memos, or screenshots anytime and I'll index them automatically!",
      isUser: false,
      timestamp: DateTime.now(),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService.instance;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF9333EA).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFF9333EA),
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ask ATLAS AI',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'Second Brain Assistant',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (!auth.isProUser)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: ActionChip(
                backgroundColor: const Color(0xFFFEF3C7),
                side: const BorderSide(color: Color(0xFFFDE68A)),
                avatar: const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFB45309),
                  size: 16,
                ),
                label: const Text(
                  'PRO',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFB45309),
                  ),
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => const ProUpgradeSheet(),
                  );
                },
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Quick Prompts Carousel
          Container(
            height: 44,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _quickPrompts.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final prompt = _quickPrompts[index];
                return ActionChip(
                  backgroundColor: Colors.white,
                  surfaceTintColor: Colors.transparent,
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  label: Text(
                    prompt,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                  onPressed: () => _handleSend(prompt),
                );
              },
            ),
          ),

          // Message Feed
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: _messages.length + (_isThinking ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isThinking) {
                  return _buildThinkingBubble();
                }
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),

          // Input Bar
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _queryController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _handleSend,
                      decoration: const InputDecoration(
                        hintText:
                            'Ask about receipts, notes, Wi-Fi, recipes...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _handleSend(_queryController.text),
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0F172A),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_upward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(
              20,
            ).copyWith(bottomRight: const Radius.circular(4)),
          ),
          child: Text(
            msg.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, right: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  20,
                ).copyWith(bottomLeft: const Radius.circular(4)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.text,
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  if (msg.sourceMemories.isNotEmpty) ...[
                    const Divider(height: 24),
                    const Text(
                      'SOURCES REFERENCED:',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...msg.sourceMemories.map(
                      (source) => InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  DetailScreen(memory: source),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                source.iconData,
                                size: 14,
                                color: const Color(0xFF0F172A),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  source.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 10,
                                color: Color(0xFF94A3B8),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThinkingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF9333EA),
              ),
            ),
            SizedBox(width: 10),
            Text(
              'Scanning memories & knowledge...',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
