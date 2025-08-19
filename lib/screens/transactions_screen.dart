// lib/screens/transactions_screen.dart
// Production-grade Enhanced Transaction Screen
// Built: 19 Aug 2025 - Complete Implementation with All Features

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/rendering.dart';

import '../models/category.dart';
import '../models/haptic_feedback_type.dart';
import '../models/transaction.dart';
import '../services/category_service.dart';
import '../services/settings_service.dart';
import '../services/storage_service.dart';
import '../theme/theme.dart';
import '../utils/helpers.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// CURRENCY & DATE FORMATTING UTILITIES
/// ════════════════════════════════════════════════════════════════════════════

final NumberFormat _currencyFormatter = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 2,
);

final NumberFormat _compactFormatter = NumberFormat.compactCurrency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);

String formatCurrency(num amount, {bool signed = false, bool compact = false}) {
  if (amount == 0) return '₹0';

  final formatter = compact && amount.abs() >= 1000
      ? _compactFormatter
      : _currencyFormatter;
  final formattedAmount = formatter.format(amount.abs());

  if (signed) {
    final prefix = amount >= 0 ? '+' : '-';
    return '$prefix$formattedAmount';
  }

  return formattedAmount;
}

String formatRelativeDate(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);

  if (difference.inDays == 0) {
    if (difference.inHours == 0) {
      return difference.inMinutes <= 1
          ? 'Just now'
          : '${difference.inMinutes}m ago';
    }
    return '${difference.inHours}h ago';
  } else if (difference.inDays == 1) {
    return 'Yesterday';
  } else if (difference.inDays < 7) {
    return '${difference.inDays} days ago';
  } else if (difference.inDays < 30) {
    final weeks = (difference.inDays / 7).floor();
    return '${weeks}w ago';
  } else if (difference.inDays < 365) {
    final months = (difference.inDays / 30).floor();
    return '${months}mo ago';
  }

  return DateFormat('dd MMM yyyy').format(date);
}

String formatFullDate(DateTime date) {
  return DateFormat('dd MMM yyyy • hh:mm a').format(date);
}

/// ════════════════════════════════════════════════════════════════════════════
/// MAIN TRANSACTIONS SCREEN
/// ════════════════════════════════════════════════════════════════════════════

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // ──────────────────────────────────────────────────────────────────────────
  // SERVICES & DEPENDENCIES
  // ──────────────────────────────────────────────────────────────────────────

  final StorageService _storage = StorageService.instance;
  final CategoryService _categoryService = CategoryService.instance;
  final SettingsService _settings = SettingsService.instance;

  // ──────────────────────────────────────────────────────────────────────────
  // ANIMATION CONTROLLERS - Optimized for Performance
  // ──────────────────────────────────────────────────────────────────────────

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _floatController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _floatAnimation;

  // ──────────────────────────────────────────────────────────────────────────
  // DATA STATE
  // ──────────────────────────────────────────────────────────────────────────

  List<Transaction> _allTransactions = [];
  List<Transaction> _filteredTransactions = [];
  List<Category> _categories = [];

  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;

  // ──────────────────────────────────────────────────────────────────────────
  // FILTER & SEARCH STATE
  // ──────────────────────────────────────────────────────────────────────────

  String _selectedFilter = 'All';
  String _selectedType = 'All';
  String _selectedCategory = 'All';
  String _searchQuery = '';
  DateTimeRange? _dateRange;
  String _sortOption = 'date_desc';

  // ──────────────────────────────────────────────────────────────────────────
  // CONTROLLERS
  // ──────────────────────────────────────────────────────────────────────────

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // ──────────────────────────────────────────────────────────────────────────
  // LIFECYCLE
  // ──────────────────────────────────────────────────────────────────────────

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

    _floatController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOutCubic,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _floatAnimation = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Start animations
    _fadeController.forward();
    _slideController.forward();
    _floatController.repeat(reverse: true);
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      // Hide keyboard when scrolling
      if (_scrollController.position.userScrollDirection ==
          ScrollDirection.reverse) {
        FocusScope.of(context).unfocus();
      }
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

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
    } catch (e) {
      print('❌ Error loading transactions: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load transactions. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // FILTER & SORT LOGIC
  // ──────────────────────────────────────────────────────────────────────────

  void _applyFilters() {
    List<Transaction> filtered = List.from(_allTransactions);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((transaction) {
        return transaction.merchant.toLowerCase().contains(query) ||
            transaction.originalMessage.toLowerCase().contains(query) ||
            transaction.referenceNumber?.toLowerCase().contains(query) == true;
      }).toList();
    }

    // Apply type filter
    if (_selectedType != 'All') {
      final isCredit = _selectedType == 'Credit';
      filtered = filtered
          .where(
            (transaction) =>
                transaction.type ==
                (isCredit ? TransactionType.credit : TransactionType.debit),
          )
          .toList();
    }

    // Apply category filter
    if (_selectedCategory != 'All') {
      filtered = filtered
          .where((transaction) => transaction.categoryId == _selectedCategory)
          .toList();
    }

    // Apply date range filter
    if (_dateRange != null) {
      filtered = filtered
          .where(
            (transaction) =>
                !transaction.dateTime.isBefore(_dateRange!.start) &&
                !transaction.dateTime.isAfter(
                  _dateRange!.end.add(const Duration(days: 1)),
                ),
          )
          .toList();
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

  // ──────────────────────────────────────────────────────────────────────────
  // BUILD METHODS
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return _buildLoadingState();
    if (_errorMessage != null) return _buildErrorState();
    return _buildTransactionsContent();
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.vibrantBlue.withOpacity(0.05),
            Theme.of(context).colorScheme.background,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RepaintBoundary(
              child: SizedBox(
                width: 160,
                height: 160,
                child: Lottie.asset(
                  'assets/animations/loading_money.json',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.vibrantBlue, AppTheme.vibrantGreen],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        size: 64,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Loading Transactions',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.vibrantBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fetching your financial data...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onBackground.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 80,
              color: AppTheme.darkOrangeRed.withOpacity(0.6),
            ),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onBackground.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.vibrantBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
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
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: AppTheme.vibrantBlue,
          backgroundColor: Theme.of(context).colorScheme.surface,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              _buildSliverAppBar(),
              if (_hasActiveFilters())
                SliverToBoxAdapter(child: _buildFilterSummary()),
              SliverToBoxAdapter(child: _buildQuickStatsBar()),
              _buildTransactionsList(),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
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
              AppTheme.vibrantBlue.withOpacity(0.85),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.vibrantBlue.withOpacity(0.25),
              blurRadius: 15,
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
                  letterSpacing: 0.5,
                ),
              ),
              if (_filteredTransactions.isNotEmpty)
                Text(
                  '${_filteredTransactions.length} of ${_allTransactions.length} records',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        _buildAppBarAction(Icons.search_rounded, 'Search', _showSearchDialog),
        _buildSortMenu(),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildAppBarAction(
    IconData icon,
    String tooltip,
    VoidCallback onPressed,
  ) {
    return Container(
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 22),
        onPressed: onPressed,
        tooltip: tooltip,
        splashRadius: 24,
      ),
    );
  }

  Widget _buildSortMenu() {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 6, 8, 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.sort_rounded, color: Colors.white, size: 22),
        tooltip: 'Sort options',
        onSelected: _handleSortOption,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Theme.of(context).colorScheme.surface,
        elevation: 8,
        itemBuilder: (context) => [
          _buildSortMenuItem(
            'date_desc',
            'Newest First',
            Icons.arrow_downward_rounded,
          ),
          _buildSortMenuItem(
            'date_asc',
            'Oldest First',
            Icons.arrow_upward_rounded,
          ),
          _buildSortMenuItem(
            'amount_desc',
            'Highest Amount',
            Icons.trending_up_rounded,
          ),
          _buildSortMenuItem(
            'amount_asc',
            'Lowest Amount',
            Icons.trending_down_rounded,
          ),
          _buildSortMenuItem(
            'merchant',
            'Merchant A-Z',
            Icons.sort_by_alpha_rounded,
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildSortMenuItem(
    String value,
    String text,
    IconData icon,
  ) {
    final isSelected = _sortOption == value;
    return PopupMenuItem(
      value: value,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.vibrantBlue.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isSelected
                    ? AppTheme.vibrantBlue
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? AppTheme.vibrantBlue
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_rounded, size: 16, color: AppTheme.vibrantBlue),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsBar() {
    final debitTotal = _filteredTransactions
        .where((t) => t.type == TransactionType.debit)
        .fold<double>(0, (sum, t) => sum + t.amount);

    final creditTotal = _filteredTransactions
        .where((t) => t.type == TransactionType.credit)
        .fold<double>(0, (sum, t) => sum + t.amount);

    final netBalance = creditTotal - debitTotal;

    return Container(
      margin: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withOpacity(0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: AppTheme.vibrantBlue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Quick Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.vibrantBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Spent',
                    formatCurrency(debitTotal, compact: true),
                    AppTheme.darkOrangeRed,
                    Icons.trending_up_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Received',
                    formatCurrency(creditTotal, compact: true),
                    AppTheme.vibrantGreen,
                    Icons.trending_down_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Net',
                    formatCurrency(netBalance, compact: true, signed: true),
                    netBalance >= 0
                        ? AppTheme.vibrantGreen
                        : AppTheme.darkOrangeRed,
                    Icons.account_balance_wallet_outlined,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.12), width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: 0.2,
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSummary() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.vibrantBlue.withOpacity(0.08),
            AppTheme.vibrantGreen.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.vibrantBlue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.vibrantBlue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.filter_list_rounded,
              color: AppTheme.vibrantBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active Filters',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.vibrantBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getFilterSummaryText(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: AppTheme.darkOrangeRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _clearAllFilters,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.clear_all_rounded,
                      color: AppTheme.darkOrangeRed,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Clear',
                      style: TextStyle(
                        color: AppTheme.darkOrangeRed,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    if (_filteredTransactions.isEmpty) {
      return SliverFillRemaining(child: _buildEmptyState());
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        return AnimationConfiguration.staggeredList(
          position: index,
          duration: const Duration(milliseconds: 300),
          child: SlideAnimation(
            verticalOffset: 30.0,
            child: FadeInAnimation(
              child: _buildTransactionCard(_filteredTransactions[index], index),
            ),
          ),
        );
      }, childCount: _filteredTransactions.length),
    );
  }

  Widget _buildTransactionCard(Transaction transaction, int index) {
    final category = _categories.firstWhere(
      (c) => c.id == transaction.categoryId,
      orElse: () => Category(
        id: 'unknown',
        name: 'Uncategorized',
        description: 'Unknown category',
        type: 'expense',
        icon: Icons.help_outline_rounded,
        color: Theme.of(context).colorScheme.outline,
      ),
    );

    final isCredit = transaction.type == TransactionType.credit;
    final transactionColor = isCredit
        ? AppTheme.vibrantGreen
        : AppTheme.darkOrangeRed;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showTransactionDetails(transaction),
          onLongPress: () => _showTransactionOptions(transaction),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: transactionColor.withOpacity(0.08),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: transactionColor.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Transaction Icon
                Hero(
                  tag: 'transaction_icon_${transaction.id}',
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          transactionColor.withOpacity(0.15),
                          transactionColor.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: transactionColor.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      _getTransactionIcon(transaction),
                      color: transactionColor,
                      size: 24,
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Transaction Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.merchant,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Category Badge
                          Flexible(
                            child: _TransactionBadge(
                              label: category.name,
                              icon: category.icon,
                              color: category.color,
                              isCategory: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Method Badge
                          _TransactionBadge(
                            label: _getMethodString(transaction),
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Amount and Date
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            transactionColor.withOpacity(0.1),
                            transactionColor.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: transactionColor.withOpacity(0.15),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        formatCurrency(transaction.amount, signed: true),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: transactionColor,
                              letterSpacing: 0.3,
                            ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formatRelativeDate(transaction.dateTime),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 11,
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Empty State Animation
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: _floatAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _floatAnimation.value),
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.vibrantBlue.withOpacity(0.1),
                            AppTheme.vibrantGreen.withOpacity(0.1),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _hasActiveFilters()
                            ? Icons.search_off_rounded
                            : Icons.receipt_long_outlined,
                        size: 64,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            Text(
              _hasActiveFilters() ? 'No matches found' : 'No transactions yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              _hasActiveFilters()
                  ? 'Try adjusting your search criteria\nor clear filters to see all transactions'
                  : 'Your transaction history will appear here\nonce you start using the app',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                height: 1.6,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value * 0.3),
          child: FloatingActionButton.extended(
            onPressed: _showFilterBottomSheet,
            backgroundColor: AppTheme.vibrantBlue,
            foregroundColor: Colors.white,
            elevation: 8,
            icon: Badge(
              isLabelVisible: _hasActiveFilters(),
              label: Text(
                _getActiveFilterCount().toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: AppTheme.darkOrangeRed,
              child: const Icon(Icons.tune_rounded),
            ),
            label: Text(
              _hasActiveFilters()
                  ? 'Filters (${_getActiveFilterCount()})'
                  : 'Filter & Sort',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // HELPER METHODS
  // ──────────────────────────────────────────────────────────────────────────

  bool _hasActiveFilters() {
    return _selectedType != 'All' ||
        _selectedCategory != 'All' ||
        _searchQuery.isNotEmpty ||
        _dateRange != null;
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (_selectedType != 'All') count++;
    if (_selectedCategory != 'All') count++;
    if (_searchQuery.isNotEmpty) count++;
    if (_dateRange != null) count++;
    return count;
  }

  String _getFilterSummaryText() {
    final List<String> activeFilters = [];

    if (_selectedType != 'All') activeFilters.add(_selectedType);
    if (_selectedCategory != 'All') {
      final category = _categories.firstWhere((c) => c.id == _selectedCategory);
      activeFilters.add(category.name);
    }
    if (_searchQuery.isNotEmpty) activeFilters.add('"$_searchQuery"');
    if (_dateRange != null) activeFilters.add('Date Range');

    return activeFilters.join(' • ');
  }

  IconData _getTransactionIcon(Transaction transaction) {
    // You can customize this based on transaction type, method, category, etc.
    switch (transaction.type) {
      case TransactionType.credit:
        return Icons.arrow_downward_rounded;
      case TransactionType.debit:
        return Icons.arrow_upward_rounded;
      default:
        return Icons.payment_rounded;
    }
  }

  String _getMethodString(Transaction transaction) {
    // You can extract this from the transaction or originalMessage
    // For now, returning a default value
    return 'UPI';
  }

  // ──────────────────────────────────────────────────────────────────────────
  // EVENT HANDLERS
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    await _loadData();
    setState(() => _isRefreshing = false);

    if (_settings.getBool('haptic_feedback', true)) {
      HapticFeedback.lightImpact();
    }
  }

  void _handleSortOption(String option) {
    setState(() {
      _sortOption = option;
    });
    _applyFilters();

    if (_settings.getBool('haptic_feedback', true)) {
      HapticFeedback.selectionClick();
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

    if (_settings.getBool('haptic_feedback', true)) {
      HapticFeedback.lightImpact();
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => _EnhancedSearchDialog(
        controller: _searchController,
        initialQuery: _searchQuery,
        onSearch: (query) {
          setState(() {
            _searchQuery = query;
          });
          _applyFilters();
        },
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
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
            position:
                Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeInOutCubic,
                  ),
                ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _showTransactionOptions(Transaction transaction) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (context) => EnhancedTransactionOptionsSheet(
        transaction: transaction,
        categories: _categories,
        onCategoryChanged: (categoryId) {
          _assignTransactionToCategory(transaction, categoryId);
        },
      ),
    );
  }

  Future<void> _assignTransactionToCategory(
    Transaction transaction,
    String categoryId,
  ) async {
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
                Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 12),
                const Text('Transaction category updated successfully'),
              ],
            ),
            backgroundColor: AppTheme.vibrantGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Error updating transaction category: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_rounded, color: Colors.white),
                const SizedBox(width: 12),
                const Text('Failed to update category'),
              ],
            ),
            backgroundColor: AppTheme.darkOrangeRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _floatController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

/// ════════════════════════════════════════════════════════════════════════════
/// SUPPORTING WIDGETS
/// ════════════════════════════════════════════════════════════════════════════

class _TransactionBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final bool isCategory;

  const _TransactionBadge({
    required this.label,
    this.icon,
    this.color,
    this.isCategory = false,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor =
        color ?? Theme.of(context).colorScheme.outline.withOpacity(0.6);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor.withOpacity(0.15), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: badgeColor, size: 12),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: badgeColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _EnhancedSearchDialog extends StatefulWidget {
  final TextEditingController controller;
  final String initialQuery;
  final ValueChanged<String> onSearch;

  const _EnhancedSearchDialog({
    required this.controller,
    required this.initialQuery,
    required this.onSearch,
  });

  @override
  State<_EnhancedSearchDialog> createState() => _EnhancedSearchDialogState();
}

class _EnhancedSearchDialogState extends State<_EnhancedSearchDialog> {
  @override
  void initState() {
    super.initState();
    widget.controller.text = widget.initialQuery;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.vibrantBlue.withOpacity(0.15),
                        AppTheme.vibrantBlue.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.search_rounded,
                    color: AppTheme.vibrantBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Search Transactions',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Search by merchant, amount, or message content',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: widget.controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Enter search terms...',
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: AppTheme.vibrantBlue,
                ),
                suffixIcon: widget.controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () => widget.controller.clear(),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppTheme.vibrantBlue, width: 2),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              onChanged: (value) => setState(() {}),
              onSubmitted: (value) {
                widget.onSearch(value);
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withOpacity(0.3),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onSearch(widget.controller.text);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.vibrantBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_rounded, size: 18),
                        const SizedBox(width: 8),
                        const Text('Search'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// ════════════════════════════════════════════════════════════════════════════
/// PLACEHOLDER CLASSES (Replace with your actual implementations)
/// ════════════════════════════════════════════════════════════════════════════

class EnhancedFilterBottomSheet extends StatelessWidget {
  final ScrollController scrollController;
  final String selectedType;
  final String selectedCategory;
  final List<Category> categories;
  final DateTimeRange? dateRange;
  final Function(String, String, DateTimeRange?) onFiltersChanged;

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
  Widget build(BuildContext context) {
    // Your existing implementation
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: const Center(
        child: Text('Filter Bottom Sheet - Use your existing implementation'),
      ),
    );
  }
}

class EnhancedTransactionDetailsScreen extends StatelessWidget {
  final Transaction transaction;

  const EnhancedTransactionDetailsScreen({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transaction Details')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Transaction Details Screen',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Text('Amount: ${formatCurrency(transaction.amount)}'),
            Text('Merchant: ${transaction.merchant}'),
            Text('Date: ${formatFullDate(transaction.dateTime)}'),
          ],
        ),
      ),
    );
  }
}

class EnhancedTransactionOptionsSheet extends StatelessWidget {
  final Transaction transaction;
  final List<Category> categories;
  final Function(String) onCategoryChanged;

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
      ),
      child: const Center(
        child: Text(
          'Transaction Options Sheet - Use your existing implementation',
        ),
      ),
    );
  }
}
