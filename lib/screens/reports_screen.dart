// lib/screens/reports_screen.dart (COMPLETE ENHANCED VERSION)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../services/storage_service.dart';
import '../services/category_service.dart';
import '../models/haptic_feedback_type.dart';
import '../services/settings_service.dart';
import '../widgets/charts/pie_chart_widget.dart';
import '../widgets/charts/bar_chart_widget.dart';
import '../theme/theme.dart';
import '../utils/helpers.dart';
import 'dart:async';
import 'dart:math' as math;

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with TickerProviderStateMixin {

  final StorageService _storage = StorageService.instance;
  final CategoryService _categoryService = CategoryService.instance;
  final SettingsService _settings = SettingsService.instance;

  // Enhanced Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _chartController;
  late AnimationController _rotationController;
  late AnimationController _bounceController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _chartAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _bounceAnimation;

  List<Transaction> _transactions = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String _selectedPeriod = 'This Month';
  DateTime _customStartDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _customEndDate = DateTime.now();

  // Analytics data
  Map<String, dynamic> _analyticsData = {};

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadReportsData();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _chartController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 10000),
      vsync: this,
    );

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _chartAnimation = CurvedAnimation(
      parent: _chartController,
      curve: Curves.elasticOut,
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(_rotationController);

    _bounceAnimation = CurvedAnimation(
      parent: _bounceController,
      curve: Curves.bounceOut,
    );

    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _slideController.forward();
    });
    _pulseController.repeat(reverse: true);
    _rotationController.repeat();
  }

  Future<void> _loadReportsData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _storage.getTransactions(),
        _categoryService.getCategories(),
      ]);

      setState(() {
        _transactions = results[0] as List<Transaction>;
        _categories = results[1] as List<Category>;
      });

      await _calculateAnalytics();

      // Start chart animations after data loads
      _chartController.forward();
      _bounceController.forward();

    } catch (e) {
      print('❌ Error loading reports data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _calculateAnalytics() async {
    final filteredTransactions = _getFilteredTransactions();

    setState(() {
      _analyticsData = {
        'totalTransactions': filteredTransactions.length,
        'totalIncome': _calculateTotalIncome(filteredTransactions),
        'totalExpense': _calculateTotalExpense(filteredTransactions),
        'avgTransactionAmount': _calculateAverageTransaction(filteredTransactions),
        'topCategory': _getTopCategory(filteredTransactions),
        'monthlyTrend': _calculateMonthlyTrend(filteredTransactions),
        'categoryBreakdown': _calculateCategoryBreakdown(filteredTransactions),
        'dailyAverage': _calculateDailyAverage(filteredTransactions),
        'savingsRate': _calculateSavingsRate(filteredTransactions),
        'expenseGrowth': _calculateExpenseGrowth(filteredTransactions),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: _isLoading ? _buildEnhancedLoadingState() : _buildEnhancedContent(),
    );
  }

  Widget _buildEnhancedLoadingState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.vibrantBlue.withOpacity(0.1),
            Theme.of(context).colorScheme.background,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Enhanced Loading Animation
            SizedBox(
              width: 200,
              height: 200,
              child: Lottie.asset(
                'assets/animations/loading_analytics.json',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return AnimatedBuilder(
                    animation: _rotationAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotationAnimation.value,
                        child: AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseAnimation.value,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [AppTheme.vibrantBlue, AppTheme.tealGreenDark],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.vibrantBlue.withOpacity(0.4),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.analytics_rounded,
                                  size: 80,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [AppTheme.vibrantBlue, AppTheme.tealGreenDark],
              ).createShader(bounds),
              child: const Text(
                'Analyzing Your Data',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Generating insights and reports...',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            _buildEnhancedAppBar(innerBoxIsScrolled),
          ],
          body: RefreshIndicator(
            onRefresh: _handleRefresh,
            color: AppTheme.vibrantBlue,
            child: CustomScrollView(
              slivers: [
                // Enhanced Period Selector
                SliverToBoxAdapter(child: _buildEnhancedPeriodSelector()),

                // Enhanced Key Metrics Summary
                SliverToBoxAdapter(child: _buildEnhancedKeyMetrics()),

                // Enhanced Charts Section
                SliverToBoxAdapter(child: _buildEnhancedChartsSection()),

                // Enhanced Detailed Analytics
                SliverToBoxAdapter(child: _buildEnhancedDetailedAnalytics()),

                // Enhanced Trends & Insights
                SliverToBoxAdapter(child: _buildEnhancedTrendsSection()),

                // Bottom padding
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedAppBar(bool innerBoxIsScrolled) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.vibrantBlue,
              AppTheme.tealGreenDark,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.vibrantBlue.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: FlexibleSpaceBar(
          titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.analytics_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Reports & Analytics',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (!_isLoading && _analyticsData.isNotEmpty)
                Text(
                  '${_analyticsData['totalTransactions']} transactions analyzed',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        // Enhanced Menu Button
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            onSelected: _handleMenuAction,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            itemBuilder: (context) => [
              _buildPopupMenuItem('export', 'Export Report', Icons.download_rounded),
              _buildPopupMenuItem('share', 'Share Analytics', Icons.share_rounded),
              _buildPopupMenuItem('refresh', 'Refresh Data', Icons.refresh_rounded),
            ],
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(String value, String text, IconData icon) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.vibrantBlue),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildEnhancedPeriodSelector() {
    final periods = [
      {'value': 'This Week', 'icon': Icons.view_week_rounded},
      {'value': 'This Month', 'icon': Icons.calendar_month_rounded},
      {'value': 'Last Month', 'icon': Icons.calendar_today_rounded},
      {'value': 'Last 3 Months', 'icon': Icons.date_range_rounded},
      {'value': 'This Year', 'icon': Icons.calendar_today_rounded},
      {'value': 'Custom', 'icon': Icons.tune_rounded},
    ];

    return Container(
      margin: const EdgeInsets.all(20),
      child: AnimatedBuilder(
        animation: _bounceAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_bounceAnimation.value * 0.05),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.surface,
                    Theme.of(context).colorScheme.surface.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.vibrantBlue.withOpacity(0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.vibrantBlue.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppTheme.vibrantBlue, AppTheme.vibrantBlue.withOpacity(0.8)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.vibrantBlue.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.access_time_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [AppTheme.vibrantBlue, AppTheme.tealGreenDark],
                              ).createShader(bounds),
                              child: Text(
                                'Analysis Period',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Select timeframe for analysis',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: periods.map((period) {
                        final isSelected = _selectedPeriod == period['value'];
                        final color = isSelected ? AppTheme.vibrantBlue : AppTheme.tealGreenDark;

                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () {
                              if (period['value'] == 'Custom') {
                                _selectCustomDateRange();
                              } else {
                                setState(() {
                                  _selectedPeriod = period['value'] as String;
                                });
                                _calculateAnalytics();
                              }

                              if (_settings.getBool('haptic_feedback', true)) {
                                _settings.triggerHaptic(HapticFeedbackType.selection);
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? LinearGradient(
                                  colors: [color, color.withOpacity(0.8)],
                                )
                                    : null,
                                color: isSelected ? null : Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? color : Theme.of(context).colorScheme.outline,
                                ),
                                boxShadow: isSelected
                                    ? [
                                  BoxShadow(
                                    color: color.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    period['icon'] as IconData,
                                    size: 16,
                                    color: isSelected ? Colors.white : color,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    period['value'] as String,
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                      color: isSelected ? Colors.white : color,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  if (_selectedPeriod == 'Custom') ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.vibrantBlue.withOpacity(0.1),
                            AppTheme.tealGreenDark.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.vibrantBlue.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.date_range_rounded,
                            color: AppTheme.vibrantBlue,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Custom Range: ${Helpers.formatDate(_customStartDate)} - ${Helpers.formatDate(_customEndDate)}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.vibrantBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEnhancedKeyMetrics() {
    if (_analyticsData.isEmpty) return const SizedBox.shrink();

    final totalIncome = _analyticsData['totalIncome'] as double;
    final totalExpense = _analyticsData['totalExpense'] as double;
    final netAmount = totalIncome - totalExpense;
    final savingsRate = _analyticsData['savingsRate'] as double;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedBuilder(
        animation: _chartAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _chartAnimation.value,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.vibrantGreen, AppTheme.vibrantGreen.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.vibrantGreen.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [AppTheme.vibrantGreen, AppTheme.vibrantBlue],
                            ).createShader(bounds),
                            child: Text(
                              'Financial Overview',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your financial health snapshot',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Primary metrics row with animations
                AnimationLimiter(
                  child: Row(
                    children: [
                      Expanded(
                        child: AnimationConfiguration.staggeredList(
                          position: 0,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            horizontalOffset: -50.0,
                            child: FadeInAnimation(
                              child: _buildEnhancedMetricCard(
                                'Total Income',
                                _formatAmount(totalIncome),
                                Icons.trending_up_rounded,
                                AppTheme.vibrantGreen,
                                'This period',
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AnimationConfiguration.staggeredList(
                          position: 1,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            horizontalOffset: 50.0,
                            child: FadeInAnimation(
                              child: _buildEnhancedMetricCard(
                                'Total Expense',
                                _formatAmount(totalExpense),
                                Icons.trending_down_rounded,
                                AppTheme.darkOrangeRed,
                                'This period',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Secondary metrics row
                AnimationLimiter(
                  child: Row(
                    children: [
                      Expanded(
                        child: AnimationConfiguration.staggeredList(
                          position: 2,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            horizontalOffset: -50.0,
                            child: FadeInAnimation(
                              child: _buildEnhancedMetricCard(
                                'Net Balance',
                                _formatAmount(netAmount.abs()),
                                netAmount >= 0 ? Icons.account_balance_wallet_rounded : Icons.warning_rounded,
                                netAmount >= 0 ? AppTheme.vibrantBlue : AppTheme.darkOrangeRed,
                                netAmount >= 0 ? 'Surplus' : 'Deficit',
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AnimationConfiguration.staggeredList(
                          position: 3,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            horizontalOffset: 50.0,
                            child: FadeInAnimation(
                              child: _buildEnhancedMetricCard(
                                'Savings Rate',
                                '${savingsRate.toStringAsFixed(1)}%',
                                Icons.savings_rounded,
                                savingsRate > 20 ? AppTheme.vibrantGreen : AppTheme.tealGreenDark,
                                _getSavingsMessage(savingsRate),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEnhancedMetricCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const Spacer(),
              // Trend indicator placeholder
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.trending_up_rounded,
                  color: color,
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedChartsSection() {
    final filteredTransactions = _getFilteredTransactions();
    final expenseTransactions = filteredTransactions.where((t) => t.type == TransactionType.debit).toList();

    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.warningOrange, AppTheme.warningOrange.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.warningOrange.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.insert_chart_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [AppTheme.warningOrange, AppTheme.darkOrangeRed],
                      ).createShader(bounds),
                      child: Text(
                        'Visual Analytics',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Interactive charts and visualizations',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (expenseTransactions.isNotEmpty) ...[
            // Enhanced Pie Chart
            AnimatedBuilder(
              animation: _chartAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _chartAnimation.value,
                  child: Container(
                    height: 360,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.surface,
                          Theme.of(context).colorScheme.surface.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.warningOrange.withOpacity(0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.warningOrange.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Icon(
                                Icons.pie_chart_rounded,
                                color: AppTheme.warningOrange,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Expense Distribution',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: TransactionPieChart(
                            transactions: expenseTransactions,
                            categories: _categories,
                            maxWidth: MediaQuery.of(context).size.width - 48,
                            maxHeight: 300,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Enhanced Bar Chart
            AnimatedBuilder(
              animation: _chartAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _chartAnimation.value,
                  child: Container(
                    height: 320,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.surface,
                          Theme.of(context).colorScheme.surface.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.vibrantBlue.withOpacity(0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.vibrantBlue.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Icon(
                                Icons.bar_chart_rounded,
                                color: AppTheme.vibrantBlue,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Spending Trends',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: TransactionBarChart(
                            transactions: expenseTransactions,
                            period: _selectedPeriod,
                            maxHeight: 260,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ] else
            _buildNoDataMessage(),
        ],
      ),
    );
  }

  Widget _buildNoDataMessage() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: Lottie.asset(
                'assets/animations/empty_chart.json',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.insert_chart_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Data to Display',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No transactions found for the selected period',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedDetailedAnalytics() {
    if (_analyticsData.isEmpty) return const SizedBox.shrink();

    final totalTransactions = _analyticsData['totalTransactions'] as int;
    final avgAmount = _analyticsData['avgTransactionAmount'] as double;
    final dailyAvg = _analyticsData['dailyAverage'] as double;
    final topCategory = _analyticsData['topCategory'] as Map<String, dynamic>?;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.tealGreenDark, AppTheme.tealGreenDark.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.tealGreenDark.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [AppTheme.tealGreenDark, AppTheme.vibrantBlue],
                      ).createShader(bounds),
                      child: Text(
                        'Detailed Analysis',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Deep dive into your financial patterns',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Enhanced Analytics Grid
          AnimationLimiter(
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                AnimationConfiguration.staggeredGrid(
                  position: 0,
                  duration: const Duration(milliseconds: 375),
                  columnCount: 2,
                  child: ScaleAnimation(
                    child: FadeInAnimation(
                      child: _buildEnhancedAnalyticsCard(
                        'Total Transactions',
                        totalTransactions.toString(),
                        Icons.receipt_long_rounded,
                        AppTheme.vibrantBlue,
                        '$_selectedPeriod',
                      ),
                    ),
                  ),
                ),
                AnimationConfiguration.staggeredGrid(
                  position: 1,
                  duration: const Duration(milliseconds: 375),
                  columnCount: 2,
                  child: ScaleAnimation(
                    child: FadeInAnimation(
                      child: _buildEnhancedAnalyticsCard(
                        'Average Amount',
                        _formatAmount(avgAmount),
                        Icons.analytics_rounded,
                        AppTheme.vibrantGreen,
                        'Per transaction',
                      ),
                    ),
                  ),
                ),
                AnimationConfiguration.staggeredGrid(
                  position: 2,
                  duration: const Duration(milliseconds: 375),
                  columnCount: 2,
                  child: ScaleAnimation(
                    child: FadeInAnimation(
                      child: _buildEnhancedAnalyticsCard(
                        'Daily Average',
                        _formatAmount(dailyAvg),
                        Icons.today_rounded,
                        AppTheme.warningOrange,
                        'Per day',
                      ),
                    ),
                  ),
                ),
                if (topCategory != null)
                  AnimationConfiguration.staggeredGrid(
                    position: 3,
                    duration: const Duration(milliseconds: 375),
                    columnCount: 2,
                    child: ScaleAnimation(
                      child: FadeInAnimation(
                        child: _buildEnhancedAnalyticsCard(
                          'Top Category',
                          topCategory['name'] as String,
                          Icons.category_rounded,
                          topCategory['color'] as Color,
                          _formatAmount(topCategory['amount'] as double),
                        ),
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

  Widget _buildEnhancedAnalyticsCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedTrendsSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.vibrantGreen, AppTheme.vibrantGreen.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.vibrantGreen.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lightbulb_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [AppTheme.vibrantGreen, AppTheme.tealGreenDark],
                      ).createShader(bounds),
                      child: Text(
                        'Insights & Recommendations',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'AI-powered financial guidance',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          AnimationLimiter(
            child: Column(
              children: _generateInsights().asMap().entries.map((entry) {
                final index = entry.key;
                final insight = entry.value;

                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: _buildEnhancedInsightCard(insight),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedInsightCard(Map<String, dynamic> insight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (insight['color'] as Color).withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: (insight['color'] as Color).withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [insight['color'] as Color, (insight['color'] as Color).withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: (insight['color'] as Color).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              insight['icon'] as IconData,
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
                  insight['title'] as String,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  insight['description'] as String,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: insight['color'] as Color,
            size: 16,
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _getSavingsMessage(double savingsRate) {
    if (savingsRate > 30) return 'Excellent!';
    if (savingsRate > 20) return 'Great job!';
    if (savingsRate > 10) return 'Good start';
    return 'Needs work';
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    await _loadReportsData();
    setState(() => _isRefreshing = false);
  }

  // Analytics calculation methods (keeping your existing implementations)
  List<Transaction> _getFilteredTransactions() {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate = now;

    switch (_selectedPeriod) {
      case 'This Week':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case 'This Month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'Last Month':
        startDate = DateTime(now.year, now.month - 1, 1);
        endDate = DateTime(now.year, now.month, 0, 23, 59, 59);
        break;
      case 'Last 3 Months':
        startDate = DateTime(now.year, now.month - 3, 1);
        break;
      case 'This Year':
        startDate = DateTime(now.year, 1, 1);
        break;
      case 'Custom':
        startDate = _customStartDate;
        endDate = _customEndDate;
        break;
      default:
        startDate = DateTime(now.year, now.month, 1);
    }

    return _transactions.where((t) =>
    t.dateTime.isAfter(startDate.subtract(const Duration(days: 1))) &&
        t.dateTime.isBefore(endDate.add(const Duration(days: 1)))
    ).toList();
  }

  double _calculateTotalIncome(List<Transaction> transactions) {
    return transactions
        .where((t) => t.type == TransactionType.credit)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double _calculateTotalExpense(List<Transaction> transactions) {
    return transactions
        .where((t) => t.type == TransactionType.debit)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double _calculateAverageTransaction(List<Transaction> transactions) {
    if (transactions.isEmpty) return 0.0;
    final total = transactions.fold(0.0, (sum, t) => sum + t.amount);
    return total / transactions.length;
  }

  Map<String, dynamic>? _getTopCategory(List<Transaction> transactions) {
    final categoryTotals = <String, double>{};

    for (final transaction in transactions.where((t) => t.type == TransactionType.debit)) {
      final categoryId = transaction.categoryId.isNotEmpty
          ? transaction.categoryId
          : 'uncategorized';
      categoryTotals[categoryId] = (categoryTotals[categoryId] ?? 0) + transaction.amount;
    }

    if (categoryTotals.isEmpty) return null;

    final topCategoryId = categoryTotals.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    final category = _categories.firstWhere(
          (c) => c.id == topCategoryId,
      orElse: () => Category(
        id: 'unknown',
        name: 'Unknown',
        description: 'Unknown category',
        type: 'expense',
        icon: Icons.help_outline_rounded,
        color: Colors.grey,
      ),
    );

    return {
      'name': category.name,
      'color': category.color,
      'amount': categoryTotals[topCategoryId],
    };
  }

  double _calculateDailyAverage(List<Transaction> transactions) {
    if (transactions.isEmpty) return 0.0;

    final totalExpense = _calculateTotalExpense(transactions);
    final filteredTrans = _getFilteredTransactions();
    final daysDiff = filteredTrans.isNotEmpty
        ? DateTime.now().difference(filteredTrans.last.dateTime).inDays + 1
        : 1;

    return totalExpense / daysDiff;
  }

  double _calculateSavingsRate(List<Transaction> transactions) {
    final income = _calculateTotalIncome(transactions);
    final expense = _calculateTotalExpense(transactions);

    if (income == 0) return 0.0;
    return ((income - expense) / income) * 100;
  }

  Map<String, dynamic> _calculateMonthlyTrend(List<Transaction> transactions) {
    return {'trend': 'stable', 'percentage': 0.0};
  }

  Map<String, dynamic> _calculateCategoryBreakdown(List<Transaction> transactions) {
    return {};
  }

  double _calculateExpenseGrowth(List<Transaction> transactions) {
    return 0.0;
  }

  List<Map<String, dynamic>> _generateInsights() {
    final insights = <Map<String, dynamic>>[];

    if (_analyticsData.isEmpty) return insights;

    final savingsRate = _analyticsData['savingsRate'] as double;
    final totalExpense = _analyticsData['totalExpense'] as double;
    final dailyAvg = _analyticsData['dailyAverage'] as double;

    // Savings rate insight
    if (savingsRate > 20) {
      insights.add({
        'title': 'Excellent Savings Rate',
        'description': 'You\'re saving ${savingsRate.toStringAsFixed(1)}% of your income. This puts you ahead of most people. Keep up the great work!',
        'icon': Icons.savings_rounded,
        'color': AppTheme.vibrantGreen,
      });
    } else if (savingsRate < 10) {
      insights.add({
        'title': 'Improve Your Savings',
        'description': 'Your current savings rate is ${savingsRate.toStringAsFixed(1)}%. Consider reviewing your expenses to increase savings.',
        'icon': Icons.warning_rounded,
        'color': AppTheme.darkOrangeRed,
      });
    }

    // Daily spending insight
    if (dailyAvg > 1000) {
      insights.add({
        'title': 'High Daily Spending',
        'description': 'Your daily average spending is ₹${dailyAvg.toStringAsFixed(0)}. Consider creating a daily budget to control expenses.',
        'icon': Icons.trending_up_rounded,
        'color': AppTheme.warningOrange,
      });
    }

    // Category-specific insights
    final topCategory = _analyticsData['topCategory'] as Map<String, dynamic>?;
    if (topCategory != null) {
      insights.add({
        'title': 'Top Spending Category',
        'description': '${topCategory['name']} accounts for the majority of your expenses. Consider if this aligns with your priorities.',
        'icon': Icons.category_rounded,
        'color': topCategory['color'],
      });
    }

    // Transaction frequency insight
    final totalTransactions = _analyticsData['totalTransactions'] as int;
    if (totalTransactions > 100) {
      insights.add({
        'title': 'High Transaction Frequency',
        'description': 'You made $totalTransactions transactions this period. Consider consolidating purchases to reduce fees.',
        'icon': Icons.receipt_long_rounded,
        'color': AppTheme.vibrantBlue,
      });
    }

    return insights;
  }

  String _formatAmount(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(1)}Cr';
    } else if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return '₹${amount.toStringAsFixed(0)}';
    }
  }

  Future<void> _selectCustomDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _customStartDate, end: _customEndDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppTheme.vibrantBlue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedPeriod = 'Custom';
        _customStartDate = picked.start;
        _customEndDate = picked.end;
      });
      await _calculateAnalytics();
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export':
        _exportReport();
        break;
      case 'share':
        _shareAnalytics();
        break;
      case 'refresh':
        _loadReportsData();
        break;
    }
  }

  void _exportReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.download_rounded, color: Colors.white),
            const SizedBox(width: 12),
            const Text('Export feature coming soon!'),
          ],
        ),
        backgroundColor: AppTheme.vibrantBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _shareAnalytics() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.share_rounded, color: Colors.white),
            const SizedBox(width: 12),
            const Text('Share feature coming soon!'),
          ],
        ),
        backgroundColor: AppTheme.vibrantGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _chartController.dispose();
    _rotationController.dispose();
    _bounceController.dispose();
    super.dispose();
  }
}
