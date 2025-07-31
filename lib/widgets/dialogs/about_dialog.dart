// lib/widgets/dialogs/about_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/theme.dart';

class AboutAppDialog extends StatefulWidget {
  final String appVersion;
  final String buildNumber;

  const AboutAppDialog({
    super.key,
    required this.appVersion,
    required this.buildNumber,
  });

  @override
  State<AboutAppDialog> createState() => _AboutAppDialogState();
}

class _AboutAppDialogState extends State<AboutAppDialog>
    with TickerProviderStateMixin {
  late AnimationController _dialogController;
  late AnimationController _logoController;
  late Animation<double> _dialogAnimation;
  late Animation<double> _logoAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _dialogController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _dialogAnimation = CurvedAnimation(
      parent: _dialogController,
      curve: Curves.elasticOut,
    );

    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    ));

    _dialogController.forward();
  }

  @override
  void dispose() {
    _dialogController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: _dialogAnimation,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.cardDarkGray,
                AppTheme.cardDarkGray.withOpacity(0.95),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppTheme.vibrantGreen.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 40,
                spreadRadius: 0,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              Flexible(child: _buildContent()),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.vibrantGreen.withOpacity(0.1),
            AppTheme.vibrantGreen.withOpacity(0.05),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          // Animated Logo
          AnimatedBuilder(
            animation: _logoAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _logoAnimation.value * 2 * 3.14159,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.vibrantGreen,
                        AppTheme.vibrantGreen.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.vibrantGreen.withOpacity(0.4),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            'SmartPaisa',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Intelligent Financial Tracker',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.vibrantGreen,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 8),

          // Version Info
          _buildInfoCard(
            title: 'Version Information',
            items: [
              {'label': 'App Version', 'value': 'v${widget.appVersion}'},
              {'label': 'Build Number', 'value': widget.buildNumber},
              {'label': 'Platform', 'value': Theme.of(context).platform.name},
            ],
            color: AppTheme.vibrantBlue,
            icon: Icons.info_outline_rounded,
          ),

          const SizedBox(height: 16),

          // Features
          _buildInfoCard(
            title: 'Key Features',
            items: [
              {'label': 'SMS Transaction Parsing', 'value': '✓'},
              {'label': 'AI-Powered Categorization', 'value': '✓'},
              {'label': 'Advanced Analytics', 'value': '✓'},
              {'label': 'Secure Data Storage', 'value': '✓'},
              {'label': 'Export & Backup', 'value': '✓'},
            ],
            color: AppTheme.tealGreenDark,
            icon: Icons.star_rounded,
          ),

          const SizedBox(height: 16),

          // Developer Info
          _buildInfoCard(
            title: 'Developer',
            items: [
              {'label': 'Created by', 'value': 'SmartPaisa Team'},
              {'label': 'Support Email', 'value': 'support@smartpaisa.com'},
              {'label': 'Website', 'value': 'www.smartpaisa.com'},
            ],
            color: AppTheme.darkOrangeRed,
            icon: Icons.code_rounded,
          ),

          const SizedBox(height: 16),

          // Quick Actions
          _buildQuickActions(),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<Map<String, String>> items,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      item['label']!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      item['value']!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.vibrantGreen.withOpacity(0.1),
            AppTheme.vibrantGreen.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.vibrantGreen.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.vibrantGreen, AppTheme.vibrantGreen.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.launch_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.vibrantGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Rate App',
                    Icons.star_rounded,
                    AppTheme.vibrantGreen,
                        () => _launchUrl('https://play.google.com/store/apps/details?id=com.smartpaisa'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Share',
                    Icons.share_rounded,
                    AppTheme.vibrantBlue,
                        () => _shareApp(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Support',
                    Icons.help_outline_rounded,
                    AppTheme.tealGreenDark,
                        () => _launchUrl('mailto:support@smartpaisa.com'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Privacy',
                    Icons.privacy_tip_rounded,
                    AppTheme.darkOrangeRed,
                        () => _launchUrl('https://smartpaisa.com/privacy'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
      String label,
      IconData icon,
      Color color,
      VoidCallback onPressed,
      ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            HapticFeedback.lightImpact();
            onPressed();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Column(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.surfaceGray.withOpacity(0.3),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          Text(
            '© 2024 SmartPaisa. All rights reserved.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Made with ❤️ for smarter financial management',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Close',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      print('Error launching URL: $e');
    }
  }

  void _shareApp() {
    // Implement app sharing
    HapticFeedback.mediumImpact();
    // You can use share_plus package
  }
}
