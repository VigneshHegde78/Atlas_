import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class ProUpgradeSheet extends StatefulWidget {
  const ProUpgradeSheet({super.key});

  @override
  State<ProUpgradeSheet> createState() => _ProUpgradeSheetState();
}

class _ProUpgradeSheetState extends State<ProUpgradeSheet> {
  bool _isAnnual = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF9333EA), Color(0xFF2563EB)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.star_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ATLAS PRO',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Unlock your ultimate second brain',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Billing Interval Toggle
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isAnnual = false),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 4,
                      ),
                      decoration: BoxDecoration(
                        color: !_isAnnual ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: !_isAnnual ? [AtlasTheme.softShadow] : null,
                      ),
                      child: const Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Monthly (₹299/mo)',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isAnnual = true),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _isAnnual
                            ? const Color(0xFF0F172A)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Annual (Save 45%)',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Features Matrix
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                _buildPerkTile(
                  icon: Icons.sync_rounded,
                  title: 'Multi-Device Real-Time Cloud Sync',
                  desc:
                      'Sync your memories across iOS, Android, and Web instantly via Firebase.',
                ),
                _buildPerkTile(
                  icon: Icons.auto_awesome_rounded,
                  title: 'Unlimited "Ask ATLAS" AI Memory Chat',
                  desc:
                      'Conversational natural language assistant to query all notes & receipts.',
                ),
                _buildPerkTile(
                  icon: Icons.document_scanner_rounded,
                  title: 'High-Precision OCR & Structured Entities',
                  desc:
                      'Auto-extract itemized receipt costs, recipes, and flight PNRs.',
                ),
                _buildPerkTile(
                  icon: Icons.shield_rounded,
                  title: 'Encrypted Cloud Backups & Vault Restore',
                  desc:
                      'Automated encrypted .atlasbackup snapshots in Google Cloud.',
                ),
                _buildPerkTile(
                  icon: Icons.folder_special_rounded,
                  title: 'Unlimited Spaces & Smart Albums',
                  desc:
                      'Create infinite custom boards and dynamic rule-based smart collections.',
                ),
              ],
            ),
          ),

          // Upgrade CTA Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await AuthService.instance.upgradeToPro();
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        '🎉 Welcome to ATLAS PRO! All features unlocked.',
                      ),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _isAnnual
                      ? 'Upgrade to Pro — ₹1,999/year'
                      : 'Upgrade to Pro — ₹299/month',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerkTile({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF2563EB), size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
