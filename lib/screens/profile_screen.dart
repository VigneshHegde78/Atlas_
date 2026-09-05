import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/memory_provider.dart';
import '../services/auth_service.dart';
import '../services/backup_service.dart';
import '../services/data_export_service.dart';
import '../services/firebase_sync_service.dart';
import '../services/security_service.dart';
import '../theme/app_theme.dart';
import 'auth_modal.dart';
import 'collections_screen.dart';
import 'pro_upgrade_sheet.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SecurityService _securityService = SecurityService.instance;
  final AuthService _authService = AuthService.instance;

  @override
  void initState() {
    super.initState();
    _securityService.initialize();
    _authService.initialize();
  }

  void _showTrashSheet(BuildContext context, MemoryProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final trashItems = provider.trashMemories;

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Trash Bin',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AtlasColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${trashItems.length} deleted memories',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (trashItems.isNotEmpty)
                        TextButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (dCtx) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                title: const Text('Empty Trash?'),
                                content: const Text(
                                  'This will permanently delete all items in trash. This action cannot be undone.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(dCtx).pop(),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      Navigator.of(dCtx).pop();
                                      await provider.emptyTrash();
                                      setSheetState(() {});
                                      if (ctx.mounted) {
                                        Navigator.of(ctx).pop();
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AtlasColors.rose,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Empty All'),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.delete_forever_rounded,
                            size: 16,
                            color: AtlasColors.rose,
                          ),
                          label: const Text(
                            'Empty Trash',
                            style: TextStyle(
                              color: AtlasColors.rose,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const Divider(height: 24),
                  if (trashItems.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              size: 48,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Trash is empty',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: trashItems.length,
                        separatorBuilder: (_, index) =>
                            const Divider(height: 1),
                        itemBuilder: (itemCtx, index) {
                          final item = trashItems[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                item.iconData,
                                color: const Color(0xFF0F172A),
                                size: 20,
                              ),
                            ),
                            title: Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              '${item.sourceApp} • ${item.category}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.restore_from_trash_rounded,
                                    color: AtlasColors.emerald,
                                    size: 20,
                                  ),
                                  tooltip: 'Restore',
                                  onPressed: () async {
                                    await provider.restoreMemory(item.id);
                                    setSheetState(() {});
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_forever_rounded,
                                    color: AtlasColors.rose,
                                    size: 20,
                                  ),
                                  tooltip: 'Delete Permanently',
                                  onPressed: () async {
                                    await provider.permanentDeleteMemory(
                                      item.id,
                                    );
                                    setSheetState(() {});
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showExportVaultSheet(BuildContext context, MemoryProvider provider) {
    String selectedFormat =
        'Obsidian Markdown'; // 'Obsidian Markdown', 'JSON Vault', 'CSV Digest'
    final memories = provider.memories;
    final collections = provider.collections;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            String exportContent = '';
            String formatDesc = '';
            if (selectedFormat == 'Obsidian Markdown') {
              exportContent = DataExportService.instance
                  .exportToObsidianMarkdown(memories, collections);
              formatDesc =
                  'Frontmatter YAML format compatible with Obsidian, Notion & Logseq.';
            } else if (selectedFormat == 'JSON Vault') {
              exportContent = DataExportService.instance.exportToJson(
                memories,
                collections,
              );
              formatDesc =
                  'Complete machine-readable JSON archive with full OCR & entity metadata.';
            } else {
              exportContent = DataExportService.instance.exportToCsv(memories);
              formatDesc =
                  'Tabular CSV format compatible with Excel and Google Sheets.';
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.82,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Export Memory Space',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AtlasColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${memories.length} Memories • ${collections.length} Spaces',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: const Text(
                          '100% Portable',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Format Picker Row
                  Row(
                    children: [
                      _buildFormatTab(
                        'Obsidian Markdown',
                        Icons.menu_book_rounded,
                        selectedFormat,
                        (fmt) {
                          setModalState(() => selectedFormat = fmt);
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFormatTab(
                        'JSON Vault',
                        Icons.code_rounded,
                        selectedFormat,
                        (fmt) {
                          setModalState(() => selectedFormat = fmt);
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFormatTab(
                        'CSV Digest',
                        Icons.table_chart_rounded,
                        selectedFormat,
                        (fmt) {
                          setModalState(() => selectedFormat = fmt);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Text(
                    formatDesc,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Preview Container
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          exportContent,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: exportContent),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '$selectedFormat copied to clipboard!',
                                ),
                                backgroundColor: const Color(0xFF0F172A),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          label: const Text('Copy to Clipboard'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0F172A),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: exportContent),
                            );
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Vault archive exported successfully (${memories.length} items).',
                                ),
                                backgroundColor: const Color(0xFF10B981),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.download_done_rounded,
                            size: 16,
                          ),
                          label: const Text('Export File'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFormatTab(
    String title,
    IconData icon,
    String current,
    Function(String) onSelect,
  ) {
    final isSelected = current == title;
    return Expanded(
      child: InkWell(
        onTap: () => onSelect(title),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF0F172A)
                : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
              const SizedBox(height: 4),
              Text(
                title.split(' ').first,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBackupModal(BuildContext context, MemoryProvider provider) {
    final backupBundle = BackupService.instance.createAtlasBackup(
      memories: provider.memories,
      collections: provider.collections,
    );
    final restoreController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Encrypted Backup & Restore',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AtlasColors.textPrimary,
                  ),
                ),
                Text(
                  'Full snapshot of SQLite database, tags, OCR & collections.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),

                // Card 1: Create Backup
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF2563EB,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.cloud_upload_rounded,
                              color: Color(0xFF2563EB),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Generate Backup Bundle',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Package .atlasbackup payload with checksum',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: backupBundle),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Backup bundle copied to clipboard (.atlasbackup)!',
                                ),
                                backgroundColor: Color(0xFF0F172A),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy_all_rounded, size: 16),
                          label: const Text('Copy .atlasbackup Bundle'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Card 2: Restore from Backup
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF10B981,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.settings_backup_restore_rounded,
                              color: Color(0xFF10B981),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Restore from Backup',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Paste backup JSON / bundle string to merge data',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: restoreController,
                        maxLines: 3,
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                        decoration: InputDecoration(
                          hintText: 'Paste .atlasbackup JSON here...',
                          hintStyle: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade400,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final text = restoreController.text.trim();
                            if (text.isEmpty) return;
                            final success = await BackupService.instance
                                .restoreAtlasBackup(text, provider);
                            if (context.mounted) {
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? 'Backup successfully restored & merged into database!'
                                        : 'Invalid backup format. Please check the backup string.',
                                  ),
                                  backgroundColor: success
                                      ? const Color(0xFF10B981)
                                      : AtlasColors.rose,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.unarchive_rounded, size: 16),
                          label: const Text('Verify & Restore Data'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final memoryProvider = Provider.of<MemoryProvider>(context);
    final canPop = Navigator.of(context).canPop();

    String syncStatusText;
    Color syncStatusColor;
    switch (memoryProvider.syncState) {
      case CloudSyncState.synced:
        syncStatusText = 'Cloud Synced (Firestore)';
        syncStatusColor = AtlasColors.emerald;
        break;
      case CloudSyncState.syncing:
        syncStatusText = 'Syncing with Cloud...';
        syncStatusColor = AtlasColors.amber;
        break;
      case CloudSyncState.pending:
        syncStatusText = 'Changes Pending Upload';
        syncStatusColor = AtlasColors.amber;
        break;
      case CloudSyncState.offline:
      case CloudSyncState.error:
        syncStatusText = 'Offline First (Local SQLite)';
        syncStatusColor = Colors.grey.shade600;
        break;
    }

    final lastSyncText = memoryProvider.lastSyncedAt != null
        ? 'Last synced: ${DateFormat('hh:mm a').format(memoryProvider.lastSyncedAt!)}'
        : 'Changes stored securely in local SQLite';

    return Scaffold(
      backgroundColor: AtlasColors.surface,
      appBar: AppBar(
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 100.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. User Profile Account Card (Top)
              _buildUserProfileCard(context),
              const SizedBox(height: 16),

              // 2. Metrics Statistics Row (Clean 3-item summary)
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Memories',
                      '${memoryProvider.memories.length}',
                      Icons.auto_stories_rounded,
                      color: AtlasColors.blue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(
                      'Favorites',
                      '${memoryProvider.favoriteMemories.length}',
                      Icons.favorite_rounded,
                      color: AtlasColors.rose,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(
                      'Spaces',
                      '${memoryProvider.collections.length}',
                      Icons.folder_copy_rounded,
                      color: AtlasColors.amber,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const CollectionsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // SECTION 1: PREFERENCES & SECURITY
              _buildSectionHeader('PREFERENCES & SECURITY'),
              const SizedBox(height: 10),

              // Biometric / App Lock Tile
              AnimatedBuilder(
                animation: _securityService,
                builder: (context, _) {
                  return _buildSettingTile(
                    icon: Icons.fingerprint_rounded,
                    title: 'App Privacy Lock',
                    subtitle: _securityService.isAppLockEnabled
                        ? 'Protected with PIN / Biometrics'
                        : 'Tap switch to lock on close',
                    trailing: Switch(
                      value: _securityService.isAppLockEnabled,
                      activeThumbColor: AtlasColors.blue,
                      onChanged: (val) async {
                        await _securityService.setAppLockEnabled(val);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                val
                                    ? 'App Privacy Lock enabled.'
                                    : 'App Privacy Lock disabled.',
                              ),
                              backgroundColor: AtlasColors.blue,
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),

              _buildSettingTile(
                icon: Icons.photo_library_rounded,
                title: 'Photo Library Access',
                subtitle: memoryProvider.hasPhotoPermission
                    ? 'Enabled for Screenshot Scanner'
                    : 'Disabled (tap switch to allow)',
                trailing: Switch(
                  value: memoryProvider.hasPhotoPermission,
                  activeThumbColor: AtlasColors.blue,
                  onChanged: (val) => memoryProvider.togglePhotoPermission(val),
                ),
              ),
              const SizedBox(height: 24),

              // SECTION 2: DATA & SYNC
              _buildSectionHeader('DATA & SYNC'),
              const SizedBox(height: 10),

              // Cloud Sync Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [AtlasTheme.softShadow],
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: syncStatusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.cloud_sync_rounded,
                        color: syncStatusColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            syncStatusText,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AtlasColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            lastSyncText,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => memoryProvider.syncNow(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AtlasColors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Sync',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              _buildSettingTile(
                icon: Icons.file_download_rounded,
                title: 'Export Memory Vault',
                subtitle: 'Markdown (Obsidian), JSON & CSV formats',
                onTap: () => _showExportVaultSheet(context, memoryProvider),
              ),
              const SizedBox(height: 10),

              _buildSettingTile(
                icon: Icons.backup_rounded,
                title: 'Backup & Restore',
                subtitle: 'Generate .atlasbackup or restore past vault',
                onTap: () => _showBackupModal(context, memoryProvider),
              ),
              const SizedBox(height: 10),

              _buildSettingTile(
                icon: Icons.delete_outline_rounded,
                title: 'Trash Bin',
                subtitle: providerFormatTrash(
                  memoryProvider.trashMemories.length,
                ),
                onTap: () => _showTrashSheet(context, memoryProvider),
              ),
              const SizedBox(height: 36),

              // Simple, clean app footer
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/icons/app_logo.png',
                      width: 32,
                      height: 32,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'ATLAS • Personal Memory OS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AtlasColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String providerFormatTrash(int count) {
    if (count == 0) return 'Trash is empty';
    if (count == 1) return '1 item in trash';
    return '$count items in trash';
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
          color: Colors.grey.shade500,
        ),
      ),
    );
  }

  Widget _buildUserProfileCard(BuildContext context) {
    return AnimatedBuilder(
      animation: _authService,
      builder: (context, _) {
        final isAuth = _authService.isAuthenticated;
        final displayName = isAuth && _authService.userDisplayName.isNotEmpty
            ? _authService.userDisplayName
            : (isAuth ? 'ATLAS User' : 'Guest');
        final email = isAuth && _authService.userEmail.isNotEmpty
            ? _authService.userEmail
            : (isAuth ? '' : 'Sign in to sync across devices');
        final isPro = _authService.isProUser;
        final initials = isAuth
            ? (displayName.length >= 2
                  ? displayName.substring(0, 2).toUpperCase()
                  : displayName.substring(0, 1).toUpperCase())
            : '?';

        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [AtlasTheme.softShadow],
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: const BoxDecoration(
                      color: AtlasColors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AtlasColors.textPrimary,
                                ),
                              ),
                            ),
                            if (isPro) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFFFDE68A),
                                  ),
                                ),
                                child: const Text(
                                  'PRO',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFB45309),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isAuth ? Icons.logout_rounded : Icons.login_rounded,
                      color: AtlasColors.blue,
                      size: 20,
                    ),
                    tooltip: isAuth ? 'Sign Out' : 'Sign In',
                    onPressed: () {
                      if (isAuth) {
                        _authService.signOut();
                      } else {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (ctx) => const AuthModal(),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            if (!isPro) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => const ProUpgradeSheet(),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AtlasColors.blue.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AtlasColors.blue.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFF59E0B,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFF59E0B),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Upgrade to ATLAS PRO',
                              style: TextStyle(
                                color: AtlasColors.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Multi-device sync • Unlimited AI memory chat',
                              style: TextStyle(
                                color: AtlasColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AtlasColors.blue,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon, {
    Color color = AtlasColors.blue,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [AtlasTheme.softShadow],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AtlasColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [AtlasTheme.softShadow],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AtlasColors.blue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AtlasColors.blue, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AtlasColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null)
              trailing
            else
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Colors.grey.shade400,
              ),
          ],
        ),
      ),
    );
  }
}
