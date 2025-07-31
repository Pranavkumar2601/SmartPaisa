// lib/screens/categories_screen.dart (COMPLETE ENHANCED VERSION)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../models/haptic_feedback_type.dart';
import '../services/category_service.dart';
import '../services/settings_service.dart';
import '../theme/theme.dart';
import '../models/category_overview.dart';
import 'transactions_screen.dart';
import 'dart:async';
import 'dart:math' as math;

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen>
    with TickerProviderStateMixin {

  final CategoryService _categoryService = CategoryService.instance;
  final SettingsService _settings = SettingsService.instance;

  // Enhanced Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _floatingController;
  late AnimationController _rotationController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _floatingAnimation;
  late Animation<double> _rotationAnimation;

  List<Category> _categories = [];
  List<CategoryOverview> _categoryOverviews = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';

  StreamSubscription<List<Category>>? _categorySubscription;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadCategories();
    _startListeningToUpdates();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _floatingController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 10000),
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

    _floatingAnimation = Tween<double>(
      begin: 0.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(_rotationController);

    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _slideController.forward();
    });
    _pulseController.repeat(reverse: true);
    _floatingController.repeat(reverse: true);
    _rotationController.repeat();
  }

  void _startListeningToUpdates() {
    _categorySubscription = _categoryService.categoriesStream.listen(
          (categories) {
        setState(() {
          _categories = categories;
        });
        _loadCategoryOverviews();
      },
    );
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);

    try {
      await _categoryService.initialize();
      final categories = await _categoryService.getCategories();

      setState(() {
        _categories = categories;
      });

      await _loadCategoryOverviews();
    } catch (e) {
      print('❌ Error loading categories: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCategoryOverviews() async {
    try {
      final overviews = await _categoryService.getCategoryOverview();
      setState(() {
        _categoryOverviews = overviews;
      });
    } catch (e) {
      print('❌ Error loading category overviews: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: _isLoading ? _buildEnhancedLoadingState() : _buildEnhancedContent(),
      floatingActionButton: _buildEnhancedFAB(),
    );
  }

  Widget _buildEnhancedLoadingState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.vibrantGreen.withOpacity(0.1),
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
                'assets/animations/loading_categories.json',
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
                                    colors: [AppTheme.vibrantGreen, AppTheme.vibrantBlue],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.vibrantGreen.withOpacity(0.4),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.category_rounded,
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
                colors: [AppTheme.vibrantGreen, AppTheme.vibrantBlue],
              ).createShader(bounds),
              child: const Text(
                'Loading Categories',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Organizing your transaction categories...',
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
    final filteredOverviews = _getFilteredOverviews();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            _buildEnhancedAppBar(innerBoxIsScrolled),
          ],
          body: RefreshIndicator(
            onRefresh: _loadCategories,
            color: AppTheme.vibrantGreen,
            child: CustomScrollView(
              slivers: [
                // Enhanced Summary Stats
                SliverToBoxAdapter(child: _buildEnhancedSummaryStats()),

                // Enhanced Filter Chips
                SliverToBoxAdapter(child: _buildEnhancedFilterChips()),

                // Categories List
                if (filteredOverviews.isEmpty)
                  SliverToBoxAdapter(child: _buildEnhancedEmptyState())
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) => AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: _buildEnhancedCategoryCard(filteredOverviews[index], index),
                          ),
                        ),
                      ),
                      childCount: filteredOverviews.length,
                    ),
                  ),

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
              AppTheme.vibrantGreen,
              AppTheme.vibrantGreen.withOpacity(0.8),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.vibrantGreen.withOpacity(0.3),
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
              const Text(
                'Categories',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_categoryOverviews.isNotEmpty)
                Text(
                  '${_categoryOverviews.length} categories organized',
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
        // Enhanced Filter Button
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list_rounded, color: Colors.white),
            onSelected: (filter) {
              setState(() {
                _selectedFilter = filter;
              });

              if (_settings.getBool('haptic_feedback', true)) {
                _settings.triggerHaptic(HapticFeedbackType.selection);
              }
            },
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            itemBuilder: (context) => [
              _buildPopupMenuItem('All', 'All Categories', Icons.apps_rounded),
              _buildPopupMenuItem('expense', 'Expense Categories', Icons.trending_down_rounded),
              _buildPopupMenuItem('income', 'Income Categories', Icons.trending_up_rounded),
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
          Icon(icon, size: 18, color: AppTheme.vibrantGreen),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildEnhancedSummaryStats() {
    final totalExpenseCategories = _categoryOverviews
        .where((o) => o.category.type == 'expense')
        .length;

    final totalIncomeCategories = _categoryOverviews
        .where((o) => o.category.type == 'income')
        .length;

    final totalExpenseAmount = _categoryOverviews
        .where((o) => o.category.type == 'expense')
        .fold(0.0, (sum, o) => sum + o.totalAmount);

    return Container(
      margin: const EdgeInsets.all(20),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value * 0.02 + 0.98,
            child: Container(
              padding: const EdgeInsets.all(24),
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
                  color: AppTheme.vibrantGreen.withOpacity(0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.vibrantGreen.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
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
                          Icons.analytics_rounded,
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
                                'Category Overview',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Financial organization insights',
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
                  Row(
                    children: [
                      Expanded(
                        child: _buildEnhancedStatItem(
                          'Expense Categories',
                          totalExpenseCategories.toString(),
                          Icons.trending_down_rounded,
                          AppTheme.darkOrangeRed,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildEnhancedStatItem(
                          'Income Categories',
                          totalIncomeCategories.toString(),
                          Icons.trending_up_rounded,
                          AppTheme.vibrantGreen,
                        ),
                      ),
                    ],
                  ),
                  if (totalExpenseAmount > 0) ...[
                    const SizedBox(height: 20),
                    _buildEnhancedStatItem(
                      'Total Monthly Spending',
                      _formatAmount(totalExpenseAmount),
                      Icons.account_balance_wallet_rounded,
                      AppTheme.vibrantBlue,
                      isLarge: true,
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

  Widget _buildEnhancedStatItem(String title, String value, IconData icon, Color color, {bool isLarge = false}) {
    return Container(
      padding: EdgeInsets.all(isLarge ? 20 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isLarge ? 12 : 10),
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
            child: Icon(icon, color: Colors.white, size: isLarge ? 28 : 24),
          ),
          SizedBox(height: isLarge ? 12 : 10),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: isLarge ? 24 : 20,
            ),
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
        ],
      ),
    );
  }

  Widget _buildEnhancedFilterChips() {
    final filters = [
      {'value': 'All', 'label': 'All Categories', 'icon': Icons.apps_rounded},
      {'value': 'expense', 'label': 'Expenses', 'icon': Icons.trending_down_rounded},
      {'value': 'income', 'label': 'Income', 'icon': Icons.trending_up_rounded},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      margin: const EdgeInsets.only(bottom: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final isSelected = _selectedFilter == filter['value'];
            final color = filter['value'] == 'expense'
                ? AppTheme.darkOrangeRed
                : filter['value'] == 'income'
                ? AppTheme.vibrantGreen
                : AppTheme.vibrantBlue;

            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedFilter = filter['value'] as String;
                  });

                  if (_settings.getBool('haptic_feedback', true)) {
                    _settings.triggerHaptic(HapticFeedbackType.selection);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                        filter['icon'] as IconData,
                        size: 18,
                        color: isSelected ? Colors.white : color,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        filter['label'] as String,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? Colors.white : color,
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
    );
  }

  Widget _buildEnhancedCategoryCard(CategoryOverview overview, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _navigateToCategoryDetails(overview.category),
          child: Hero(
            tag: 'category_${overview.category.id}',
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
                  color: overview.category.color.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: overview.category.color.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Enhanced Category Icon
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              overview.category.color,
                              overview.category.color.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: overview.category.color.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(
                          overview.category.icon,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),

                      const SizedBox(width: 20),

                      // Enhanced Category Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              overview.category.name,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              overview.category.description,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Enhanced Amount Display
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  overview.category.color.withOpacity(0.1),
                                  overview.category.color.withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: overview.category.color.withOpacity(0.2),
                              ),
                            ),
                            child: Text(
                              overview.formattedTotalAmount,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: overview.category.color,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${overview.transactionCount} transactions',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Enhanced Monthly Stats
                  if (overview.thisMonthAmount > 0) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            overview.category.color.withOpacity(0.05),
                            overview.category.color.withOpacity(0.02),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: overview.category.color.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: overview.category.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.calendar_month_rounded,
                              size: 16,
                              color: overview.category.color,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'This Month',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatAmount(overview.thisMonthAmount),
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: overview.category.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (overview.monthlyChangePercent != 0) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: overview.hasIncrease
                                    ? AppTheme.darkOrangeRed.withOpacity(0.1)
                                    : AppTheme.vibrantGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    overview.hasIncrease ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                                    size: 14,
                                    color: overview.hasIncrease ? AppTheme.darkOrangeRed : AppTheme.vibrantGreen,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${overview.monthlyChangePercent.abs().toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: overview.hasIncrease ? AppTheme.darkOrangeRed : AppTheme.vibrantGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            // Enhanced Empty State Animation
            AnimatedBuilder(
              animation: _floatingAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _floatingAnimation.value),
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: Lottie.asset(
                      'assets/animations/empty_categories.json',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.vibrantGreen.withOpacity(0.2),
                                AppTheme.vibrantBlue.withOpacity(0.2),
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.category_outlined,
                            size: 80,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [AppTheme.vibrantGreen, AppTheme.vibrantBlue],
              ).createShader(bounds),
              child: const Text(
                'No Categories Found',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Create categories to organize your transactions\nand gain better insights into your spending',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showEnhancedAddCategoryDialog,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Your First Category'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.vibrantGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedFAB() {
    return AnimatedBuilder(
      animation: _floatingAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatingAnimation.value * 0.5),
          child: FloatingActionButton.extended(
            onPressed: _showEnhancedAddCategoryDialog,
            backgroundColor: AppTheme.vibrantGreen,
            foregroundColor: Colors.white,
            elevation: 8,
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'Add Category',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }

  // Get filtered category overviews
  List<CategoryOverview> _getFilteredOverviews() {
    if (_selectedFilter == 'All') {
      return _categoryOverviews;
    }

    return _categoryOverviews
        .where((overview) => overview.category.type == _selectedFilter)
        .toList();
  }

  // Navigate to category details screen
  void _navigateToCategoryDetails(Category category) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            EnhancedCategoryDetailsScreen(category: category),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          );
        },
      ),
    );
  }

  // Show enhanced add category dialog
  void _showEnhancedAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => const EnhancedAddCategoryDialog(),
    );
  }

  // Format amount for display
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

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _floatingController.dispose();
    _rotationController.dispose();
    _categorySubscription?.cancel();
    super.dispose();
  }
}
// Enhanced Category Details Screen
class EnhancedCategoryDetailsScreen extends StatefulWidget {
  final Category category;

  const EnhancedCategoryDetailsScreen({super.key, required this.category});

  @override
  State<EnhancedCategoryDetailsScreen> createState() => _EnhancedCategoryDetailsScreenState();
}

class _EnhancedCategoryDetailsScreenState extends State<EnhancedCategoryDetailsScreen>
    with TickerProviderStateMixin {
  final CategoryService _categoryService = CategoryService.instance;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _chartController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _chartAnimation;

  List<Transaction> _transactions = [];
  CategoryStats? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadCategoryData();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _chartController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));

    _chartAnimation = CurvedAnimation(
      parent: _chartController,
      curve: Curves.elasticOut,
    );

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _loadCategoryData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _categoryService.getCategoryTransactions(widget.category.id),
        _categoryService.getCategoryStats(widget.category.id),
      ]);

      setState(() {
        _transactions = results[0] as List<Transaction>;
        _stats = results[1] as CategoryStats;
        _isLoading = false;
      });

      _chartController.forward();
    } catch (e) {
      print('❌ Error loading category data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _chartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            slivers: [
              _buildEnhancedAppBar(),
              SliverToBoxAdapter(
                child: _isLoading ? _buildLoadingContent() : _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedAppBar() {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              widget.category.color,
              widget.category.color.withOpacity(0.8),
            ],
          ),
        ),
        child: FlexibleSpaceBar(
          titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.category.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                widget.category.description,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          background: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.category.color,
                  widget.category.color.withOpacity(0.8),
                ],
              ),
            ),
            child: Center(
              child: Hero(
                tag: 'category_${widget.category.id}',
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    widget.category.icon,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.edit_rounded, color: Colors.white),
            onPressed: _editCategory,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingContent() {
    return Container(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: Lottie.asset(
                'assets/animations/loading_stats.json',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(widget.category.color),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Loading category details...',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: widget.category.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Enhanced Stats Card
          if (_stats != null) _buildEnhancedStatsCard(),
          const SizedBox(height: 24),

          // Quick Actions
          _buildQuickActions(),
          const SizedBox(height: 24),

          // Enhanced Transactions List
          _buildEnhancedTransactionsList(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildEnhancedStatsCard() {
    return AnimatedBuilder(
      animation: _chartAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _chartAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.category.color.withOpacity(0.1),
                  widget.category.color.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.category.color.withOpacity(0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.category.color.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [widget.category.color, widget.category.color.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(widget.category.icon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Category Statistics',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Financial insights and trends',
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
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Total Amount',
                        '₹${_stats!.totalAmount.toStringAsFixed(0)}',
                        Icons.account_balance_wallet_rounded,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatItem(
                        'Transactions',
                        _stats!.transactionCount.toString(),
                        Icons.receipt_long_rounded,
                      ),
                    ),
                  ],
                ),
                if (_stats!.thisMonthAmount > 0) ...[
                  const SizedBox(height: 16),
                  _buildStatItem(
                    'This Month',
                    '₹${_stats!.thisMonthAmount.toStringAsFixed(0)}',
                    Icons.calendar_month_rounded,
                    isFullWidth: true,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, {bool isFullWidth = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.category.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.category.color.withOpacity(0.2),
        ),
      ),
      child: isFullWidth
          ? Row(
        children: [
          Icon(icon, color: widget.category.color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: widget.category.color,
            ),
          ),
        ],
      )
          : Column(
        children: [
          Icon(icon, color: widget.category.color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: widget.category.color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            'View All Transactions',
            Icons.list_rounded,
                () => _viewAllTransactions(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            'Export Data',
            Icons.download_rounded,
                () => _exportCategoryData(),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.category.color.withOpacity(0.2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: widget.category.color, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: widget.category.color,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedTransactionsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.receipt_long_rounded, color: widget.category.color),
            const SizedBox(width: 8),
            Text(
              'Recent Transactions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_transactions.isEmpty)
          _buildEmptyTransactions()
        else
          AnimationLimiter(
            child: Column(
              children: _transactions.take(10).map((transaction) {
                final index = _transactions.indexOf(transaction);
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: _buildEnhancedTransactionTile(transaction),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyTransactions() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.category.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 48,
                color: widget.category.color,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Transactions Yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Transactions in this category will appear here',
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

  Widget _buildEnhancedTransactionTile(Transaction transaction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _viewTransactionDetails(transaction),
          child: Container(
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
                color: widget.category.color.withOpacity(0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.category.color.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [widget.category.color, widget.category.color.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    transaction.methodIcon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.merchant,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        transaction.methodString,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.category.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        transaction.formattedAmount,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: widget.category.color,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTransactionDate(transaction.dateTime),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
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

  String _formatTransactionDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _editCategory() {
    // Implement edit category functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Edit category feature coming soon!'),
        backgroundColor: widget.category.color,
      ),
    );
  }

  void _viewAllTransactions() {
    // Navigate to all transactions for this category
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryTransactionsScreen(
          category: widget.category,
          transactions: _transactions,
        ),
      ),
    );
  }

  void _exportCategoryData() {
    // Implement export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Export feature coming soon!'),
        backgroundColor: widget.category.color,
      ),
    );
  }

  void _viewTransactionDetails(Transaction transaction) {
    // Navigate to transaction details
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedTransactionDetailsScreen(transaction: transaction),
      ),
    );
  }
}

// Enhanced Add Category Dialog
class EnhancedAddCategoryDialog extends StatefulWidget {
  const EnhancedAddCategoryDialog({super.key});

  @override
  State<EnhancedAddCategoryDialog> createState() => _EnhancedAddCategoryDialogState();
}

class _EnhancedAddCategoryDialogState extends State<EnhancedAddCategoryDialog>
    with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedType = 'expense';
  IconData _selectedIcon = Icons.category_rounded;
  Color _selectedColor = AppTheme.vibrantBlue;

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  final List<Map<String, dynamic>> _availableIcons = [
    {'icon': Icons.restaurant_rounded, 'label': 'Food'},
    {'icon': Icons.directions_car_rounded, 'label': 'Transport'},
    {'icon': Icons.shopping_bag_rounded, 'label': 'Shopping'},
    {'icon': Icons.movie_rounded, 'label': 'Entertainment'},
    {'icon': Icons.electrical_services_rounded, 'label': 'Utilities'},
    {'icon': Icons.local_hospital_rounded, 'label': 'Healthcare'},
    {'icon': Icons.school_rounded, 'label': 'Education'},
    {'icon': Icons.account_balance_wallet_rounded, 'label': 'Finance'},
    {'icon': Icons.work_rounded, 'label': 'Work'},
    {'icon': Icons.trending_up_rounded, 'label': 'Investment'},
    {'icon': Icons.home_rounded, 'label': 'Home'},
    {'icon': Icons.fitness_center_rounded, 'label': 'Fitness'},
  ];

  final List<Color> _availableColors = [
    AppTheme.vibrantBlue,
    AppTheme.vibrantGreen,
    AppTheme.darkOrangeRed,
    AppTheme.warningOrange,
    AppTheme.tealGreenDark,
    Colors.purple,
    Colors.pink,
    Colors.indigo,
    Colors.cyan,
    Colors.amber,
    Colors.deepOrange,
    Colors.teal,
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    _slideController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: SlideTransition(
        position: _slideAnimation,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                Flexible(
                  child: _buildContent(),
                ),
                _buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_selectedColor, _selectedColor.withOpacity(0.8)],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _selectedIcon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create New Category',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Organize your transactions better',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Name
          _buildSectionTitle('Category Name'),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Enter category name',
              prefixIcon: Icon(Icons.label_rounded, color: _selectedColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _selectedColor, width: 2),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Description
          _buildSectionTitle('Description'),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(
              hintText: 'Brief description (optional)',
              prefixIcon: Icon(Icons.description_rounded, color: _selectedColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _selectedColor, width: 2),
              ),
            ),
            maxLines: 2,
          ),

          const SizedBox(height: 20),

          // Type Selection
          _buildSectionTitle('Category Type'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildTypeOption('expense', 'Expense', Icons.trending_down_rounded, AppTheme.darkOrangeRed),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTypeOption('income', 'Income', Icons.trending_up_rounded, AppTheme.vibrantGreen),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Icon Selection
          _buildSectionTitle('Select Icon'),
          const SizedBox(height: 12),
          _buildIconGrid(),

          const SizedBox(height: 20),

          // Color Selection
          _buildSectionTitle('Select Color'),
          const SizedBox(height: 12),
          _buildColorGrid(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: _selectedColor,
      ),
    );
  }

  Widget _buildTypeOption(String value, String label, IconData icon, Color color) {
    final isSelected = _selectedType == value;

    return GestureDetector(
      onTap: () => setState(() => _selectedType = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: [color, color.withOpacity(0.8)])
              : null,
          color: isSelected ? null : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : color,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: _availableIcons.length,
      itemBuilder: (context, index) {
        final iconData = _availableIcons[index];
        final isSelected = iconData['icon'] == _selectedIcon;

        return GestureDetector(
          onTap: () => setState(() => _selectedIcon = iconData['icon']),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(colors: [_selectedColor, _selectedColor.withOpacity(0.8)])
                  : null,
              color: isSelected ? null : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? _selectedColor : Theme.of(context).colorScheme.outline,
              ),
              boxShadow: isSelected
                  ? [
                BoxShadow(
                  color: _selectedColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  iconData['icon'],
                  color: isSelected ? Colors.white : _selectedColor,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  iconData['label'],
                  style: TextStyle(
                    fontSize: 10,
                    color: isSelected ? Colors.white : _selectedColor,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildColorGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: _availableColors.length,
      itemBuilder: (context, index) {
        final color = _availableColors[index];
        final isSelected = color == _selectedColor;

        return GestureDetector(
          onTap: () => setState(() => _selectedColor = color),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: Colors.white, width: 3)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: isSelected ? 8 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: isSelected
                ? const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 20,
            )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _saveCategory,
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Create Category'),
            ),
          ),
        ],
      ),
    );
  }

  void _saveCategory() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a category name'),
          backgroundColor: AppTheme.darkOrangeRed,
        ),
      );
      return;
    }

    final category = Category(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? 'Custom ${_selectedType} category'
          : _descriptionController.text.trim(),
      type: _selectedType,
      icon: _selectedIcon,
      color: _selectedColor,
    );

    try {
      await CategoryService.instance.saveCategory(category);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                const Text('Category created successfully!'),
              ],
            ),
            backgroundColor: AppTheme.vibrantGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      print('Error saving category: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to create category. Please try again.'),
            backgroundColor: AppTheme.darkOrangeRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// Placeholder for CategoryTransactionsScreen
class CategoryTransactionsScreen extends StatelessWidget {
  final Category category;
  final List<Transaction> transactions;

  const CategoryTransactionsScreen({
    super.key,
    required this.category,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${category.name} Transactions'),
        backgroundColor: category.color.withOpacity(0.1),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final transaction = transactions[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: category.color.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(transaction.methodIcon, color: category.color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.merchant,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        transaction.methodString,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  transaction.formattedAmount,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: category.color,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

