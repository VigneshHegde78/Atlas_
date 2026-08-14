import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/memory_provider.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final memoryProvider = Provider.of<MemoryProvider>(context);

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

              Row(
                children: [
                  Expanded(
                    child: _buildStatCard('Memories', '${memoryProvider.memories.length}', Icons.psychology_rounded),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard('Screenshots', '${memoryProvider.permittedScreenshotIds.length}', Icons.image_rounded),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard('Storage', '14 MB', Icons.storage_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              _buildSettingTile(
                icon: Icons.verified_user_rounded,
                title: 'Photo Library Permission',
                subtitle: memoryProvider.hasPhotoPermission ? 'Granted' : 'Disabled',
                trailing: Switch(
                  value: memoryProvider.hasPhotoPermission,
                  activeColor: AtlasColors.emerald,
                  onChanged: (val) => memoryProvider.togglePhotoPermission(val),
                ),
              ),
              const SizedBox(height: 12),

              _buildSettingTile(
                icon: Icons.cloud_download_rounded,
                title: 'Export Memory Space',
                subtitle: 'Backup your index to JSON format',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Memory space exported successfully.')),
                  );
                },
              ),
              const SizedBox(height: 12),

              _buildSettingTile(
                icon: Icons.lock_rounded,
                title: 'Private Encryption Key',
                subtitle: 'Device local keychain active',
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
                      'Personal Memory OS • Save Anything, Find Everything',
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

  Widget _buildStatCard(String label, String value, IconData icon) {
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
          Icon(icon, size: 20, color: AtlasColors.blue),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AtlasColors.blue,
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
