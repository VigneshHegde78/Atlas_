import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/memory_provider.dart';
import '../services/firebase_sync_service.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showTrashSheet(BuildContext context, MemoryProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
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
                          color: AtlasColors.blue,
                        ),
                      ),
                      Text(
                        '${provider.trashMemories.length} deleted items',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  if (provider.trashMemories.isNotEmpty)
                    TextButton.icon(
                      onPressed: () {
                        provider.emptyTrash();
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Trash emptied permanently.')),
                        );
                      },
                      icon: const Icon(Icons.delete_forever_rounded, color: AtlasColors.rose, size: 18),
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
            ),
            const Divider(height: 1),
            Expanded(
              child: provider.trashMemories.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.delete_outline_rounded, size: 48, color: Colors.black12),
                          SizedBox(height: 12),
                          Text(
                            'Trash is empty',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: provider.trashMemories.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = provider.trashMemories[index];
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: item.iconBgColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(item.iconData, color: AtlasColors.blue, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AtlasColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Deleted ${item.category}',
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
                                icon: const Icon(Icons.restore_rounded, color: AtlasColors.emerald),
                                tooltip: 'Restore',
                                onPressed: () {
                                  provider.restoreMemory(item.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Restored "${item.title}"')),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_forever_rounded, color: Colors.grey),
                                tooltip: 'Delete forever',
                                onPressed: () {
                                  provider.permanentDeleteMemory(item.id);
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
      ),
    );
  }

  void _exportDatabase(BuildContext context, MemoryProvider provider) {
    final exportData = provider.memories.map((m) => m.toMap()).toList();
    final jsonString = const JsonEncoder.withIndent('  ').convert({
      'app': 'ATLAS Personal Memory OS',
      'exportedAt': DateTime.now().toIso8601String(),
      'totalMemories': provider.memories.length,
      'memories': exportData,
    });

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Memory Space Export', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Successfully exported ${provider.memories.length} active memories from SQLite local database into JSON archive.',
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              height: 120,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                child: Text(
                  jsonString,
                  style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                ),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AtlasColors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final memoryProvider = Provider.of<MemoryProvider>(context);

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
      case CloudSyncState.offline:
      case CloudSyncState.error:
        syncStatusText = 'Offline First (Local SQLite)';
        syncStatusColor = Colors.grey.shade600;
        break;
    }

    final lastSyncText = memoryProvider.lastSyncedAt != null
        ? 'Last synced: ${DateFormat('hh:mm a').format(memoryProvider.lastSyncedAt!)}'
        : 'Changes stored in local SQLite database';

    return Scaffold(
      backgroundColor: AtlasColors.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Account & Privacy'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: AtlasColors.blue,
                  shape: BoxShape.circle,
                  boxShadow: [AtlasTheme.floatShadow],
                ),
                child: const Center(
                  child: Text(
                    'AV',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Alex Vance',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AtlasColors.blue,
                ),
              ),
              Text(
                'alex.vance@atlas.memory',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 28),

              // Metrics Row
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard('Active', '${memoryProvider.memories.length}', Icons.psychology_rounded),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard('Favorites', '${memoryProvider.favoriteMemories.length}', Icons.favorite_rounded, color: AtlasColors.rose),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard('Trash', '${memoryProvider.trashMemories.length}', Icons.delete_outline_rounded, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Cloud Sync Card
              Container(
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
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: syncStatusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.cloud_sync_rounded, color: syncStatusColor, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            syncStatusText,
                            style: const TextStyle(
                              fontSize: 15,
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
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text('Sync', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Trash Management Tile
              _buildSettingTile(
                icon: Icons.delete_sweep_rounded,
                title: 'Trash Bin',
                subtitle: '${memoryProvider.trashMemories.length} items in trash',
                onTap: () => _showTrashSheet(context, memoryProvider),
              ),
              const SizedBox(height: 12),

              _buildSettingTile(
                icon: Icons.verified_user_rounded,
                title: 'Photo Library Permission',
                subtitle: memoryProvider.hasPhotoPermission ? 'Granted' : 'Disabled',
                trailing: Switch(
                  value: memoryProvider.hasPhotoPermission,
                  activeThumbColor: AtlasColors.emerald,
                  onChanged: (val) => memoryProvider.togglePhotoPermission(val),
                ),
              ),
              const SizedBox(height: 12),

              _buildSettingTile(
                icon: Icons.cloud_download_rounded,
                title: 'Export Memory Space',
                subtitle: 'Export SQLite database to JSON archive',
                onTap: () => _exportDatabase(context, memoryProvider),
              ),
              const SizedBox(height: 12),

              _buildSettingTile(
                icon: Icons.lock_rounded,
                title: 'Private Encryption Key',
                subtitle: 'Local SQLite keychain active',
                onTap: () {},
              ),
              const SizedBox(height: 48),

              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/icons/app_logo.png',
                      width: 28,
                      height: 28,
                      color: AtlasColors.blue,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'ATLAS v1.0.0',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AtlasColors.blue,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Offline-First Memory OS • SQLite & Firebase Powered',
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

  Widget _buildStatCard(String label, String value, IconData icon, {Color? color}) {
    final effectiveColor = color ?? AtlasColors.blue;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [AtlasTheme.softShadow],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: effectiveColor),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: effectiveColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
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
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Icon(icon, size: 20, color: AtlasColors.blue),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
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
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }
}
