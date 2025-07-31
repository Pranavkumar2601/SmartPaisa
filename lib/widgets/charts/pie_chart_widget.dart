// lib/widgets/charts/pie_chart_widget.dart (COMPLETE ENHANCED VERSION)
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lottie/lottie.dart';
import '../../models/transaction.dart';
import '../../models/category.dart';
import '../../theme/theme.dart';
import '../../utils/helpers.dart';
import 'dart:math' as math;

class TransactionPieChart extends StatefulWidget {
  final List<Transaction> transactions;
  final List<Category> categories;
  final double maxWidth;
  final double maxHeight;

  const TransactionPieChart({
    Key? key,
    required this.transactions,
    required this.categories,
    this.maxWidth = 350,
    this.maxHeight = 350,
  }) : super(key: key);

  @override
  State<TransactionPieChart> createState() => _TransactionPieChartState();
}

class _TransactionPieChartState extends State<TransactionPieChart>
    with TickerProviderStateMixin {

  // Enhanced Animation Controllers
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _shimmerController;

  late Animation<double> _animation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _shimmerAnimation;

  int _touchedIndex = -1;
  Map<String, double> _categoryTotals = {};
  Map<String, Color> _categoryColors = {};
  double _totalAmount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadChartData();
    if (mounted) {
      _loadChartData();
    }
  }

  @override
  void didUpdateWidget(TransactionPieChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.transactions != oldWidget.transactions && mounted) {
      _loadChartData();
    }
  }

  @override
  void dispose() {
    // ✅ SOLUTION: Properly dispose all animation controllers
    _animationController.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 20000),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Create animations...
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.06,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(_rotationController);

    _shimmerAnimation = CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    );

    // ✅ SOLUTION: Only start animations if mounted
    if (mounted) {
      _pulseController.repeat(reverse: true);
      _rotationController.repeat();
      _shimmerController.repeat(reverse: true);
    }
  }

  Future<void> _loadChartData() async {
    // ✅ SOLUTION: Check if widget is still mounted before setState
    if (!mounted) return;
    setState(() => _isLoading = true);

    // Simulate loading time for smooth transition
    await Future.delayed(const Duration(milliseconds: 600));

    // ✅ SOLUTION: Check mounted again after async operation
    if (!mounted) return;
    _calculateCategoryTotals();

    setState(() => _isLoading = false);

    // ✅ SOLUTION: Check mounted before starting animations
    if (mounted && _animationController.status != AnimationStatus.completed) {
      _animationController.forward();
    }
  }

  void _calculateCategoryTotals() {
    _categoryTotals.clear();
    _categoryColors.clear();

    // Calculate totals for each category
    for (final transaction in widget.transactions) {
      if (transaction.type == TransactionType.debit) {
        final categoryId = transaction.categoryId.isEmpty
            ? 'default_uncategorized'
            : transaction.categoryId;

        _categoryTotals[categoryId] = (_categoryTotals[categoryId] ?? 0) + transaction.amount;
      }
    }

    // Calculate total amount
    _totalAmount = _categoryTotals.values.fold(0.0, (sum, amount) => sum + amount);

    // Set colors for categories
    for (final category in widget.categories) {
      _categoryColors[category.id] = category.color;
    }

    // Default color for uncategorized
    _categoryColors['default_uncategorized'] = AppTheme.vibrantBlue.withOpacity(0.7);
  }

  List<PieChartSectionData> _generateSections() {
    if (_categoryTotals.isEmpty || _totalAmount == 0) return [];

    final sections = <PieChartSectionData>[];
    final sortedEntries = _categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Enhanced color palette
    final enhancedColors = [
      AppTheme.vibrantBlue,
      AppTheme.vibrantGreen,
      AppTheme.warningOrange,
      AppTheme.darkOrangeRed,
      AppTheme.tealGreenDark,
      Colors.purple,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
      Colors.amber,
    ];

    int colorIndex = 0;

    for (int index = 0; index < sortedEntries.length; index++) {
      final entry = sortedEntries[index];
      final categoryId = entry.key;
      final amount = entry.value;
      final percentage = (amount / _totalAmount) * 100;

      // ✅ FIXED: Skip very small slices to prevent overlapping
      if (percentage < 2) continue;

      final category = widget.categories.firstWhere(
            (c) => c.id == categoryId,
        orElse: () => Category(
          id: categoryId,
          name: 'Uncategorized',
          description: 'Uncategorized transactions',
          type: 'expense',
          icon: Icons.help_outline_rounded,
          color: enhancedColors[colorIndex % enhancedColors.length],
        ),
      );

      final isTouched = index == _touchedIndex;
      final baseRadius = 85.0;
      final touchRadius = 105.0;
      final radius = isTouched ? touchRadius : baseRadius;

      // ✅ FIXED: Better title formatting and positioning
      final showTitle = percentage >= 8; // Only show percentage for larger slices
      final titleStyle = TextStyle(
        fontSize: isTouched ? 14 : 12,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        shadows: [
          Shadow(
            blurRadius: 3,
            color: Colors.black.withOpacity(0.7),
            offset: const Offset(1, 1),
          ),
        ],
      );

      sections.add(
        PieChartSectionData(
          color: category.color,
          value: amount,
          title: showTitle ? '${percentage.toStringAsFixed(0)}%' : '',
          radius: radius,
          titleStyle: titleStyle,
          titlePositionPercentageOffset: 0.7, // Better positioning
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              category.color,
              category.color.withOpacity(0.7),
              category.color.withOpacity(0.9),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.surface,
            width: isTouched ? 3 : 2,
          ),
        ),
      );

      colorIndex++;
    }

    return sections;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_categoryTotals.isEmpty || _totalAmount == 0) {
      return _buildEnhancedEmptyState();
    }

    return _buildEnhancedChart();
  }

  Widget _buildLoadingState() {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          height: widget.maxHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.surface.withOpacity(0.9),
                Theme.of(context).colorScheme.surface.withOpacity(0.7),
              ],
            ),
          ),
          child: Column(
            children: [
              Expanded(
                flex: 2,
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Rotating shimmer ring
                      AnimatedBuilder(
                        animation: _rotationAnimation,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _rotationAnimation.value,
                            child: Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: SweepGradient(
                                  colors: [
                                    AppTheme.vibrantBlue.withOpacity(0.3),
                                    AppTheme.vibrantGreen.withOpacity(0.3),
                                    AppTheme.warningOrange.withOpacity(0.3),
                                    AppTheme.vibrantBlue.withOpacity(0.3),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      // Inner circle
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.surface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: List.generate(3, (index) {
                      return Container(
                        height: 20,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.vibrantBlue.withOpacity(0.2),
                              AppTheme.vibrantBlue.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEnhancedChart() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Container(
            height: widget.maxHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.surface.withOpacity(0.9),
                  Theme.of(context).colorScheme.surface.withOpacity(0.7),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Enhanced Header
                  _buildChartHeader(),
                  const SizedBox(height: 12),

                  // Chart with Center Info
                  Expanded(
                    flex: 3,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Pie Chart
                        PieChart(
                          PieChartData(
                            sections: _generateSections(),
                            pieTouchData: PieTouchData(
                              enabled: true,
                              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                setState(() {
                                  if (!event.isInterestedForInteractions ||
                                      pieTouchResponse == null ||
                                      pieTouchResponse.touchedSection == null) {
                                    _touchedIndex = -1;
                                    return;
                                  }
                                  _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                });
                              },
                            ),
                            borderData: FlBorderData(show: false),
                            sectionsSpace: 3, // Better spacing between sections
                            centerSpaceRadius: 45, // Create center space for info
                            startDegreeOffset: -90,
                          ),
                        ),

                        // Center Info
                        _buildCenterInfo(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Enhanced Legend
                  Expanded(
                    flex: 2,
                    child: _buildEnhancedLegend(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChartHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.warningOrange, AppTheme.warningOrange.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppTheme.warningOrange.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.pie_chart_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [AppTheme.warningOrange, AppTheme.darkOrangeRed],
                ).createShader(bounds),
                child: Text(
                  'Expense Breakdown',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${_categoryTotals.length} categories',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.vibrantGreen, AppTheme.vibrantGreen.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.vibrantGreen.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  Helpers.formatCurrency(_totalAmount),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCenterInfo() {
    final sortedEntries = _categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topCategory = sortedEntries.isNotEmpty ? sortedEntries.first : null;

    if (topCategory == null) return const SizedBox.shrink();

    final category = widget.categories.firstWhere(
          (c) => c.id == topCategory.key,
      orElse: () => Category(
        id: topCategory.key,
        name: 'Uncategorized',
        description: 'Uncategorized',
        type: 'expense',
        icon: Icons.help_outline_rounded,
        color: AppTheme.vibrantBlue,
      ),
    );

    final percentage = (_totalAmount > 0) ? (topCategory.value / _totalAmount * 100) : 0.0;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.95 + (_pulseAnimation.value - 1.0) * 0.1,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.surface,
                  Theme.of(context).colorScheme.surface.withOpacity(0.9),
                ],
              ),
              border: Border.all(
                color: category.color.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: category.color.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  category.icon,
                  color: category.color,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: category.color,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedLegend() {
    if (_categoryTotals.isEmpty) return const SizedBox.shrink();

    final sortedEntries = _categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.legend_toggle_rounded,
                  color: AppTheme.vibrantBlue,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Category Breakdown',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.vibrantBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: sortedEntries.take(8).map((entry) { // Limit to 8 items
                final categoryId = entry.key;
                final amount = entry.value;
                final percentage = (_totalAmount > 0) ? (amount / _totalAmount * 100) : 0.0;

                final category = widget.categories.firstWhere(
                      (c) => c.id == categoryId,
                  orElse: () => Category(
                    id: categoryId,
                    name: 'Uncategorized',
                    description: 'Uncategorized transactions',
                    type: 'expense',
                    icon: Icons.help_outline_rounded,
                    color: AppTheme.vibrantBlue.withOpacity(0.7),
                  ),
                );

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        category.color.withOpacity(0.1),
                        category.color.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: category.color.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [category.color, category.color.withOpacity(0.8)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: category.color.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        category.icon,
                        size: 12,
                        color: category.color,
                      ),
                      const SizedBox(width: 4),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 80),
                        child: Text(
                          category.name,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: category.color,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedEmptyState() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            height: widget.maxHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.warningOrange.withOpacity(0.05),
                  Theme.of(context).colorScheme.surface,
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Enhanced Empty State Animation
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: Lottie.asset(
                      'assets/animations/empty_pie_chart.json',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return AnimatedBuilder(
                          animation: _rotationAnimation,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _rotationAnimation.value * 0.1,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppTheme.warningOrange.withOpacity(0.2),
                                      AppTheme.darkOrangeRed.withOpacity(0.2),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.pie_chart_outline_rounded,
                                  size: 70,
                                  color: AppTheme.warningOrange,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [AppTheme.warningOrange, AppTheme.darkOrangeRed],
                    ).createShader(bounds),
                    child: const Text(
                      'No Spending Data',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Start making transactions to see\nyour expense distribution',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.warningOrange, AppTheme.darkOrangeRed],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.warningOrange.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.insights_rounded, color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        const Text(
                          'Insights Coming Soon',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
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
      },
    );
  }
}
