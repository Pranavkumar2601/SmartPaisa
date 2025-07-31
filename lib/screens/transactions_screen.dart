// lib/screens/transactions_screen.dart (COMPLETE ENHANCED VERSION)
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../services/storage_service.dart';
import '../services/category_service.dart';
import '../models/haptic_feedback_type.dart';
import '../services/settings_service.dart';
import '../theme/theme.dart';
import '../utils/helpers.dart';
import 'dart:async';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen>
    with TickerProviderStateMixin {

  final StorageService _storage = StorageService.instance;
  final CategoryService _categoryService = CategoryService.instance;
  final SettingsService _settings = SettingsService.instance;

  // Enhanced Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _floatingController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _floatingAnimation;

  List<Transaction> _allTransactions = [];
  List<Transaction> _filteredTransactions = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  bool _isRefreshing = false;

  // Enhanced Filter States
  String _selectedFilter = 'All';
  String _selectedType = 'All';
  String _selectedCategory = 'All';
  String _searchQuery = '';
  DateTimeRange? _dateRange;
  String _sortOption = 'date_desc';

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
    _setupScrollListener();
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

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
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

    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _slideController.forward();
    });
    _pulseController.repeat(reverse: true);
    _floatingController.repeat(reverse: true);
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.offset > 100) {
        // Hide FAB when scrolling down
      }
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _storage.getTransactions(),
        _categoryService.getCategories(),
      ]);

      if (mounted) {
        setState(() {
          _allTransactions = results[0] as List<Transaction>;
          _categories = results[1] as List<Category>;
          _applyFilters();
          _isLoading = false;
        });
      }

      print('📊 Loaded ${_allTransactions.length} transactions');
    } catch (e) {
      print('❌ Error loading transactions: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilters() {
    List<Transaction> filtered = List.from(_allTransactions);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((t) =>
      t.merchant.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.originalMessage.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    // Apply type filter
    if (_selectedType != 'All') {
      final isCredit = _selectedType == 'Credit';
      filtered = filtered.where((t) => t.type == (isCredit ? TransactionType.credit : TransactionType.debit)).toList();
    }

    // Apply category filter
    if (_selectedCategory != 'All') {
      filtered = filtered.where((t) => t.categoryId == _selectedCategory).toList();
    }

    // Apply date range filter
    if (_dateRange != null) {
      filtered = filtered.where((t) =>
      t.dateTime.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
          t.dateTime.isBefore(_dateRange!.end.add(const Duration(days: 1)))
      ).toList();
    }

    // Apply sorting
    _applySorting(filtered);

    setState(() {
      _filteredTransactions = filtered;
    });
  }

  void _applySorting(List<Transaction> transactions) {
    switch (_sortOption) {
      case 'date_desc':
        transactions.sort((a, b) => b.dateTime.compareTo(a.dateTime));
        break;
      case 'date_asc':
        transactions.sort((a, b) => a.dateTime.compareTo(b.dateTime));
        break;
      case 'amount_desc':
        transactions.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'amount_asc':
        transactions.sort((a, b) => a.amount.compareTo(b.amount));
        break;
      case 'merchant':
        transactions.sort((a, b) => a.merchant.compareTo(b.merchant));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: _isLoading ? _buildLoadingState() : _buildTransactionsContent(),
      floatingActionButton: _buildEnhancedFAB(),
    );
  }

  Widget _buildLoadingState() {
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
                'assets/animations/loading_money.json',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppTheme.vibrantBlue, AppTheme.vibrantGreen],
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
                            Icons.receipt_long_rounded,
                            size: 80,
                            color: Colors.white,
                          ),
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
                colors: [AppTheme.vibrantBlue, AppTheme.vibrantGreen],
              ).createShader(bounds),
              child: const Text(
                'Loading Transactions',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Fetching your financial data...',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            _buildEnhancedAppBar(innerBoxIsScrolled),
          ],
          body: RefreshIndicator(
            onRefresh: _handleRefresh,
            color: AppTheme.vibrantBlue,
            child: Column(
              children: [
                // Enhanced Filter Summary
                if (_hasActiveFilters()) _buildEnhancedFilterSummary(),

                // Quick Stats Bar
                _buildQuickStatsBar(),

                // Transactions List
                Expanded(
                  child: _filteredTransactions.isEmpty
                      ? _buildEnhancedEmptyState()
                      : _buildEnhancedTransactionsList(),
                ),
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
              AppTheme.vibrantBlue.withOpacity(0.8),
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
              const Text(
                'Transactions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_filteredTransactions.isNotEmpty)
                Text(
                  '${_filteredTransactions.length} of ${_allTransactions.length} records',
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
        // Enhanced Search Button
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.search_rounded, color: Colors.white),
            onPressed: _showEnhancedSearchDialog,
          ),
        ),
        // Enhanced Sort Button
        Container(
          margin: const EdgeInsets.fromLTRB(0, 8, 8, 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: PopupMenuButton<String>(
            icon: const Icon(Icons.sort_rounded, color: Colors.white),
            onSelected: _handleSortOption,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            itemBuilder: (context) => [
              _buildPopupMenuItem('date_desc', 'Newest First', Icons.arrow_downward),
              _buildPopupMenuItem('date_asc', 'Oldest First', Icons.arrow_upward),
              _buildPopupMenuItem('amount_desc', 'Highest Amount', Icons.trending_up),
              _buildPopupMenuItem('amount_asc', 'Lowest Amount', Icons.trending_down),
              _buildPopupMenuItem('merchant', 'Merchant A-Z', Icons.sort_by_alpha),
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

  Widget _buildQuickStatsBar() {
    final totalSpent = _filteredTransactions
        .where((t) => t.type == TransactionType.debit)
        .fold<double>(0, (sum, t) => sum + t.amount);

    final totalReceived = _filteredTransactions
        .where((t) => t.type == TransactionType.credit)
        .fold<double>(0, (sum, t) => sum + t.amount);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Total Spent',
              '₹${totalSpent.toStringAsFixed(0)}',
              AppTheme.darkOrangeRed,
              Icons.arrow_upward_rounded,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Theme.of(context).dividerColor,
          ),
          Expanded(
            child: _buildStatItem(
              'Total Received',
              '₹${totalReceived.toStringAsFixed(0)}',
              AppTheme.vibrantGreen,
              Icons.arrow_downward_rounded,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Theme.of(context).dividerColor,
          ),
          Expanded(
            child: _buildStatItem(
              'Net Balance',
              '₹${(totalReceived - totalSpent).toStringAsFixed(0)}',
              totalReceived >= totalSpent ? AppTheme.vibrantGreen : AppTheme.darkOrangeRed,
              Icons.account_balance_wallet_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  bool _hasActiveFilters() {
    return _selectedType != 'All' ||
        _selectedCategory != 'All' ||
        _searchQuery.isNotEmpty ||
        _dateRange != null;
  }

  Widget _buildEnhancedFilterSummary() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.vibrantBlue.withOpacity(0.1),
            AppTheme.vibrantGreen.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.vibrantBlue.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.vibrantBlue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.filter_alt_rounded,
              color: AppTheme.vibrantBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active Filters',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getFilterSummaryText(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: AppTheme.darkOrangeRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _clearAllFilters,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  'Clear All',
                  style: TextStyle(
                    color: AppTheme.darkOrangeRed,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFilterSummaryText() {
    final List<String> activeFilters = [];

    if (_selectedType != 'All') activeFilters.add(_selectedType);
    if (_selectedCategory != 'All') {
      final category = _categories.firstWhere((c) => c.id == _selectedCategory);
      activeFilters.add(category.name);
    }
    if (_searchQuery.isNotEmpty) activeFilters.add('"$_searchQuery"');
    if (_dateRange != null) activeFilters.add('Custom Date Range');

    return activeFilters.join(' • ');
  }

  Widget _buildEnhancedTransactionsList() {
    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: _filteredTransactions.length,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _buildEnhancedTransactionCard(
                  _filteredTransactions[index],
                  index,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEnhancedTransactionCard(Transaction transaction, int index) {
    final category = _categories.firstWhere(
          (c) => c.id == transaction.categoryId,
      orElse: () => Category(
        id: 'unknown',
        name: 'Uncategorized',
        description: 'Unknown category',
        type: 'expense',
        icon: Icons.help_outline_rounded,
        color: Colors.grey,
      ),
    );

    final isCredit = transaction.type == TransactionType.credit;
    final transactionColor = isCredit ? AppTheme.vibrantGreen : AppTheme.darkOrangeRed;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showTransactionDetails(transaction),
          onLongPress: () => _showTransactionOptions(transaction),
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
                color: transactionColor.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: transactionColor.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Enhanced Method Icon with Animation
                    Hero(
                      tag: 'transaction_${transaction.id}',
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              transactionColor,
                              transactionColor.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: transactionColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          _getTransactionIcon(transaction),
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Enhanced Transaction Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transaction.merchant,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              // Enhanced Category Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      category.color.withOpacity(0.2),
                                      category.color.withOpacity(0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: category.color.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      category.icon,
                                      color: category.color,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      category.name,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: category.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Method Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _getMethodString(transaction),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
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
                                transactionColor.withOpacity(0.1),
                                transactionColor.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: transactionColor.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '${isCredit ? '+' : '-'}₹${transaction.amount.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: transactionColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatTransactionDate(transaction.dateTime),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Enhanced Additional Info
                if (transaction.referenceNumber != null || transaction.balance != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.background.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (transaction.referenceNumber != null) ...[
                          Icon(
                            Icons.tag_rounded,
                            size: 14,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Ref: ${transaction.referenceNumber}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        if (transaction.referenceNumber != null && transaction.balance != null)
                          Container(
                            width: 1,
                            height: 16,
                            color: Theme.of(context).dividerColor,
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        if (transaction.balance != null) ...[
                          Icon(
                            Icons.account_balance_wallet_rounded,
                            size: 14,
                            color: AppTheme.vibrantBlue,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Balance: ₹${transaction.balance!.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.vibrantBlue,
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
    );
  }

  Widget _buildEnhancedEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Enhanced Empty State Animation
            SizedBox(
              width: 200,
              height: 200,
              child: Lottie.asset(
                'assets/animations/empty_state.json',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return AnimatedBuilder(
                    animation: _floatingAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _floatingAnimation.value),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.vibrantBlue.withOpacity(0.2),
                                AppTheme.vibrantGreen.withOpacity(0.2),
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.receipt_long_outlined,
                            size: 80,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          ),
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
                colors: [AppTheme.vibrantBlue, AppTheme.vibrantGreen],
              ).createShader(bounds),
              child: Text(
                _hasActiveFilters() ? 'No matches found' : 'No transactions yet',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _hasActiveFilters()
                  ? 'Try adjusting your search criteria\nor clear filters to see all transactions'
                  : 'Your transaction history will appear here\nonce you start using the app',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (_hasActiveFilters()) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _clearAllFilters,
                icon: const Icon(Icons.clear_all_rounded),
                label: const Text('Clear All Filters'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.vibrantBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
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
            onPressed: _showEnhancedFilterBottomSheet,
            backgroundColor: AppTheme.vibrantBlue,
            foregroundColor: Colors.white,
            elevation: 8,
            icon: const Icon(Icons.tune_rounded),
            label: Text(
              _hasActiveFilters() ? 'Filters (${_getActiveFilterCount()})' : 'Filter',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (_selectedType != 'All') count++;
    if (_selectedCategory != 'All') count++;
    if (_searchQuery.isNotEmpty) count++;
    if (_dateRange != null) count++;
    return count;
  }

  // Enhanced Dialog Methods
  void _showEnhancedSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.vibrantBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.search_rounded,
                      color: AppTheme.vibrantBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Search Transactions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by merchant, amount, or message...',
                  prefixIcon: Icon(Icons.search_rounded, color: AppTheme.vibrantBlue),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.vibrantBlue, width: 2),
                  ),
                ),
                autofocus: true,
                onSubmitted: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                  _applyFilters();
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
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
                      onPressed: () {
                        setState(() {
                          _searchQuery = _searchController.text;
                        });
                        _applyFilters();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.vibrantBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Search'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEnhancedFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => EnhancedFilterBottomSheet(
          scrollController: scrollController,
          selectedType: _selectedType,
          selectedCategory: _selectedCategory,
          categories: _categories,
          dateRange: _dateRange,
          onFiltersChanged: (type, category, dateRange) {
            setState(() {
              _selectedType = type;
              _selectedCategory = category;
              _dateRange = dateRange;
            });
            _applyFilters();
          },
        ),
      ),
    );
  }

  void _showTransactionDetails(Transaction transaction) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            EnhancedTransactionDetailsScreen(transaction: transaction),
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

  void _showTransactionOptions(Transaction transaction) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => EnhancedTransactionOptionsSheet(
        transaction: transaction,
        categories: _categories,
        onCategoryChanged: (categoryId) {
          _assignTransactionToCategory(transaction, categoryId);
        },
      ),
    );
  }

  // Utility Methods
  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    await _loadData();
    setState(() => _isRefreshing = false);
  }

  void _handleSortOption(String option) {
    setState(() {
      _sortOption = option;
    });
    _applyFilters();

    if (_settings.getBool('haptic_feedback', true)) {
      _settings.triggerHaptic(HapticFeedbackType.selection);
    }
  }

  void _clearAllFilters() {
    setState(() {
      _selectedType = 'All';
      _selectedCategory = 'All';
      _searchQuery = '';
      _dateRange = null;
      _searchController.clear();
    });
    _applyFilters();
  }

  Future<void> _assignTransactionToCategory(Transaction transaction, String categoryId) async {
    try {
      await _categoryService.assignTransactionToCategory(
        transaction.id,
        categoryId,
      );
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                const Text('Transaction category updated'),
              ],
            ),
            backgroundColor: AppTheme.vibrantGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      print('❌ Error updating transaction category: $e');
    }
  }

  IconData _getTransactionIcon(Transaction transaction) {
    // Add your transaction icon logic here
    return Icons.payment_rounded;
  }

  String _getMethodString(Transaction transaction) {
    // Add your method string logic here
    return 'UPI';
  }

  String _formatTransactionDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _floatingController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

// Enhanced Supporting Widgets will be provided in the next part...
// Enhanced Filter Bottom Sheet
class EnhancedFilterBottomSheet extends StatefulWidget {
  final ScrollController scrollController;
  final String selectedType;
  final String selectedCategory;
  final List<Category> categories;
  final DateTimeRange? dateRange;
  final Function(String type, String category, DateTimeRange? dateRange) onFiltersChanged;

  const EnhancedFilterBottomSheet({
    super.key,
    required this.scrollController,
    required this.selectedType,
    required this.selectedCategory,
    required this.categories,
    required this.dateRange,
    required this.onFiltersChanged,
  });

  @override
  State<EnhancedFilterBottomSheet> createState() => _EnhancedFilterBottomSheetState();
}

class _EnhancedFilterBottomSheetState extends State<EnhancedFilterBottomSheet>
    with TickerProviderStateMixin {
  late String _selectedType;
  late String _selectedCategory;
  late DateTimeRange? _dateRange;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.selectedType;
    _selectedCategory = widget.selectedCategory;
    _dateRange = widget.dateRange;

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.vibrantBlue, AppTheme.vibrantBlue.withOpacity(0.8)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Filter Transactions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                controller: widget.scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Transaction Type Filter
                    _buildSectionHeader('Transaction Type', Icons.swap_vert_rounded),
                    const SizedBox(height: 12),
                    _buildTypeSelector(),

                    const SizedBox(height: 24),

                    // Category Filter
                    _buildSectionHeader('Category', Icons.category_rounded),
                    const SizedBox(height: 12),
                    _buildCategoryDropdown(),

                    const SizedBox(height: 24),

                    // Date Range Filter
                    _buildSectionHeader('Date Range', Icons.date_range_rounded),
                    const SizedBox(height: 12),
                    _buildDateRangeSelector(),

                    const SizedBox(height: 32),

                    // Action buttons
                    _buildActionButtons(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.vibrantBlue, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeSelector() {
    final types = ['All', 'Debit', 'Credit'];

    return Row(
      children: types.map((type) {
        final isSelected = _selectedType == type;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedType = type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                  colors: [AppTheme.vibrantBlue, AppTheme.vibrantBlue.withOpacity(0.8)],
                )
                    : null,
                color: isSelected ? null : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppTheme.vibrantBlue : Theme.of(context).colorScheme.outline,
                ),
                boxShadow: isSelected
                    ? [
                  BoxShadow(
                    color: AppTheme.vibrantBlue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
                    : null,
              ),
              child: Text(
                type,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.vibrantBlue),
          items: [
            const DropdownMenuItem(
              value: 'All',
              child: Text('All Categories'),
            ),
            ...widget.categories.map((category) => DropdownMenuItem(
              value: category.id,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: category.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      category.icon,
                      size: 16,
                      color: category.color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(category.name),
                ],
              ),
            )),
          ],
          onChanged: (value) {
            setState(() {
              _selectedCategory = value!;
            });
          },
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return InkWell(
      onTap: _selectDateRange,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.date_range_rounded,
              color: AppTheme.vibrantBlue,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _dateRange == null
                    ? 'Select date range'
                    : '${_dateRange!.start.day}/${_dateRange!.start.month}/${_dateRange!.start.year} - ${_dateRange!.end.day}/${_dateRange!.end.month}/${_dateRange!.end.year}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            if (_dateRange != null)
              IconButton(
                icon: Icon(Icons.clear_rounded, color: AppTheme.darkOrangeRed),
                onPressed: () {
                  setState(() {
                    _dateRange = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                _selectedType = 'All';
                _selectedCategory = 'All';
                _dateRange = null;
              });
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Clear All'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              widget.onFiltersChanged(_selectedType, _selectedCategory, _dateRange);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.vibrantBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Apply Filters'),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
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
        _dateRange = picked;
      });
    }
  }
}

// Enhanced Transaction Details Screen
class EnhancedTransactionDetailsScreen extends StatefulWidget {
  final Transaction transaction;

  const EnhancedTransactionDetailsScreen({super.key, required this.transaction});

  @override
  State<EnhancedTransactionDetailsScreen> createState() => _EnhancedTransactionDetailsScreenState();
}

class _EnhancedTransactionDetailsScreenState extends State<EnhancedTransactionDetailsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
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

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCredit = widget.transaction.type == TransactionType.credit;
    final transactionColor = isCredit ? AppTheme.vibrantGreen : AppTheme.darkOrangeRed;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            slivers: [
              _buildEnhancedAppBar(transactionColor),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildTransactionSummaryCard(transactionColor),
                      const SizedBox(height: 20),
                      _buildTransactionDetailsCard(),
                      const SizedBox(height: 20),
                      _buildOriginalMessageCard(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedAppBar(Color transactionColor) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              transactionColor,
              transactionColor.withOpacity(0.8),
            ],
          ),
        ),
        child: FlexibleSpaceBar(
          titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          title: const Text(
            'Transaction Details',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
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
            icon: const Icon(Icons.share_rounded, color: Colors.white),
            onPressed: _shareTransaction,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionSummaryCard(Color transactionColor) {
    return Hero(
      tag: 'transaction_${widget.transaction.id}',
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
            color: transactionColor.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: transactionColor.withOpacity(0.1),
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
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [transactionColor, transactionColor.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: transactionColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.transaction.type == TransactionType.credit
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.transaction.merchant,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Payment Method', // Add your method string logic
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    transactionColor.withOpacity(0.1),
                    transactionColor.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: transactionColor.withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Amount',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    '${widget.transaction.type == TransactionType.credit ? '+' : '-'}₹${widget.transaction.amount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: transactionColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppTheme.vibrantBlue),
              const SizedBox(width: 8),
              Text(
                'Transaction Details',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Date & Time', _formatDetailDate(widget.transaction.dateTime)),
          _buildDetailRow('Type', widget.transaction.type.toString().split('.').last.toUpperCase()),
          _buildDetailRow('Transaction ID', widget.transaction.id),
          if (widget.transaction.referenceNumber != null)
            _buildDetailRow('Reference Number', widget.transaction.referenceNumber!),
          if (widget.transaction.balance != null)
            _buildDetailRow('Account Balance', '₹${widget.transaction.balance!.toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  Widget _buildOriginalMessageCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.message_outlined, color: AppTheme.vibrantGreen),
              const SizedBox(width: 8),
              Text(
                'Original SMS Message',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.transaction.originalMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDetailDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _shareTransaction() {
    // Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.share_rounded, color: Colors.white),
            const SizedBox(width: 12),
            const Text('Share feature coming soon!'),
          ],
        ),
        backgroundColor: AppTheme.vibrantBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// Enhanced Transaction Options Sheet
class EnhancedTransactionOptionsSheet extends StatelessWidget {
  final Transaction transaction;
  final List<Category> categories;
  final Function(String categoryId) onCategoryChanged;

  const EnhancedTransactionOptionsSheet({
    super.key,
    required this.transaction,
    required this.categories,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.vibrantBlue, AppTheme.vibrantBlue.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.more_horiz_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Transaction Options',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Options
          _buildOptionTile(
            context,
            Icons.category_rounded,
            'Change Category',
            'Assign to a different category',
            AppTheme.vibrantBlue,
                () => _showCategorySelector(context),
          ),

          _buildOptionTile(
            context,
            Icons.share_rounded,
            'Share Transaction',
            'Share transaction details',
            AppTheme.vibrantGreen,
                () => _shareTransaction(context),
          ),

          _buildOptionTile(
            context,
            Icons.info_outline_rounded,
            'View Full Details',
            'See complete transaction information',
            AppTheme.warningOrange,
                () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EnhancedTransactionDetailsScreen(transaction: transaction),
                ),
              );
            },
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildOptionTile(
      BuildContext context,
      IconData icon,
      String title,
      String subtitle,
      Color color,
      VoidCallback onTap,
      ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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

  void _showCategorySelector(BuildContext context) {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'Select Category',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...categories.map((category) => ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: category.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(category.icon, color: category.color),
                    ),
                    title: Text(category.name),
                    onTap: () {
                      onCategoryChanged(category.id);
                      Navigator.pop(context);
                    },
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareTransaction(BuildContext context) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.share_rounded, color: Colors.white),
            const SizedBox(width: 12),
            const Text('Share feature coming soon!'),
          ],
        ),
        backgroundColor: AppTheme.vibrantBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
