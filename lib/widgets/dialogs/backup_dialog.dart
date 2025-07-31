// lib/widgets/dialogs/backup_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../theme/theme.dart';
import '../../services/backup_service.dart';

class BackupDialog extends StatefulWidget {
  final Future<void> Function() onBackup;
  final Future<void> Function(String) onRestore;

  const BackupDialog({
    super.key,
    required this.onBackup,
    required this.onRestore,
  });

  @override
  State<BackupDialog> createState() => _BackupDialogState();
}

class _BackupDialogState extends State<BackupDialog>
    with TickerProviderStateMixin {
  late AnimationController _dialogController;
  late AnimationController _progressController;
  late Animation<double> _dialogAnimation;
  late Animation<double> _progressAnimation;

  bool _isProcessing = false;
  String _processingText = '';
  double _progress = 0.0;
  List<File> _availableBackups = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadAvailableBackups();
  }

  void _initializeAnimations() {
    _dialogController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _dialogAnimation = CurvedAnimation(
      parent: _dialogController,
      curve: Curves.elasticOut,
    );

    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    );

    _dialogController.forward();
  }

  Future<void> _loadAvailableBackups() async {
    try {
      final backups = await BackupService.instance.getAvailableBackups();
      if (mounted) {
        setState(() {
          _availableBackups = backups;
        });
      }
    } catch (e) {
      print('Error loading backups: $e');
    }
  }

  @override
  void dispose() {
    _dialogController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _performBackup() async {
    setState(() {
      _isProcessing = true;
      _processingText = 'Creating backup...';
      _progress = 0.0;
    });

    _progressController.forward();

    try {
      // Simulate progress
      for (int i = 1; i <= 5; i++) {
        await Future.delayed(const Duration(milliseconds: 400));
        if (mounted) {
          setState(() {
            _progress = i / 5;
            switch (i) {
              case 1:
                _processingText = 'Collecting transaction data...';
                break;
              case 2:
                _processingText = 'Gathering categories...';
                break;
              case 3:
                _processingText = 'Compiling settings...';
                break;
              case 4:
                _processingText = 'Creating backup file...';
                break;
              case 5:
                _processingText = 'Backup completed!';
                break;
            }
          });
        }
      }

      final result = await BackupService.instance.createBackup();

      if (result.success && result.filePath != null) {
        // Share the backup file using the native sharing
        await Share.shareXFiles(
          [XFile(result.filePath!)],
          text: 'SmartPaisa Backup - ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
          subject: 'SmartPaisa Data Backup',
        );
        await _loadAvailableBackups();
      }

      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _processingText = 'Backup failed: $e';
        });
        _progressController.reverse();
      }
    }
  }

  Future<void> _restoreFromBackup(File backupFile) async {
    // Show confirmation dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDarkGray,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Restore Backup?', style: TextStyle(color: Colors.white)),
        content: Text(
          'This will replace all current data with the backup data. This action cannot be undone.',
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.7))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.darkOrangeRed),
            child: const Text('Restore', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
      _processingText = 'Restoring backup...';
      _progress = 0.0;
    });

    _progressController.forward();

    try {
      // Simulate progress
      for (int i = 1; i <= 4; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          setState(() {
            _progress = i / 4;
            switch (i) {
              case 1:
                _processingText = 'Reading backup file...';
                break;
              case 2:
                _processingText = 'Restoring transactions...';
                break;
              case 3:
                _processingText = 'Restoring settings...';
                break;
              case 4:
                _processingText = 'Restoration completed!';
                break;
            }
          });
        }
      }

      await widget.onRestore(backupFile.path);

      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _processingText = 'Restore failed: $e';
        });
        _progressController.reverse();
      }
    }
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
              color: AppTheme.vibrantBlue.withOpacity(0.3),
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
              if (_isProcessing) _buildProgressSection() else _buildContent(),
              if (!_isProcessing) _buildFooter(),
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
            AppTheme.vibrantBlue.withOpacity(0.1),
            AppTheme.vibrantBlue.withOpacity(0.05),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.vibrantBlue,
                  AppTheme.vibrantBlue.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.vibrantBlue.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              _isProcessing ? Icons.sync_rounded : Icons.backup_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isProcessing ? 'Processing...' : 'Backup & Restore',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isProcessing
                      ? 'Please wait while we process your request'
                      : 'Manage your data backups',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.vibrantBlue.withOpacity(0.1),
                  AppTheme.vibrantBlue.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.vibrantBlue.withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                // Progress Bar
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _progress * _progressAnimation.value,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.vibrantBlue,
                                AppTheme.vibrantBlue.withOpacity(0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.vibrantBlue.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _processingText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.vibrantBlue,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  '${(_progress * 100).toInt()}% Complete',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          children: [
            const SizedBox(height: 8),

            // Create Backup
            _buildActionCard(
              title: 'Create New Backup',
              subtitle: 'Export all your data and share via any app',
              icon: Icons.backup_rounded,
              color: AppTheme.vibrantGreen,
              onTap: _performBackup,
            ),

            const SizedBox(height: 16),

            // Available Backups Section
            if (_availableBackups.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Available Backups (${_availableBackups.length})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              ..._availableBackups.take(3).map((backup) =>
                  _buildBackupItem(backup)
              ).toList(),

              if (_availableBackups.length > 3)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'And ${_availableBackups.length - 3} more backups available...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.folder_open_rounded,
                      color: Colors.white.withOpacity(0.5),
                      size: 40,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No backups found',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your first backup to keep your data safe',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: color,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackupItem(File backup) {
    final fileName = backup.path.split('/').last;
    final fileSize = backup.lengthSync();
    final lastModified = backup.lastModifiedSync();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.tealGreenDark.withOpacity(0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _restoreFromBackup(backup),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.tealGreenDark.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.file_present_rounded,
                    color: AppTheme.tealGreenDark,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Backup ${_formatDate(lastModified)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${(fileSize / 1024).toStringAsFixed(1)} KB • ${_formatTime(lastModified)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Icon(
                      Icons.restore_rounded,
                      color: AppTheme.tealGreenDark,
                      size: 18,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tap to\nRestore',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.tealGreenDark,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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
      child: Row(
        children: [
          Expanded(
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
}
