// lib/screens/dashboard_screen.dart (COMPLETE ENHANCED VERSION - ALL FIXED)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:lottie/lottie.dart';
import '../services/sms_service.dart';
import '../services/sms_sync_service.dart';
import '../services/storage_service.dart';
import '../services/category_service.dart';
import '../services/settings_service.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/bank_transaction_method.dart';
import '../models/haptic_feedback_type.dart';
import '../widgets/transaction_popup.dart';
import '../widgets/charts/pie_chart_widget.dart';
import '../widgets/charts/bar_chart_widget.dart';
import '../utils/helpers.dart';
import '../theme/theme.dart';
import 'categories_screen.dart';
import 'transactions_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin, WidgetsBindingObserver {

  /* ────────────────────── Services ────────────────────── */
  final _sms = SmsService.instance;
  final _syncService = SmsSyncService.instance;
  final _store = StorageService.instance;
  final _categoryService = CategoryService.instance;
  final _settings = SettingsService.instance;

  /* ────────────────────── Animation Controllers ───────────────────── */
  late final AnimationController _fadeCtl =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
  late final AnimationController _pulseCtl =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 2300))..repeat(reverse: true);
  late final AnimationController _slideCtl =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  late final AnimationController _scaleCtl =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 400));

  late final Animation<double> _fade = CurvedAnimation(parent: _fadeCtl, curve: Curves.easeOut);
  late final Animation<double> _pulse = Tween(begin: 1.0, end: 1.02).animate(CurvedAnimation(parent: _pulseCtl, curve: Curves.easeInOut));
  late final Animation<Offset> _slide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(CurvedAnimation(parent: _slideCtl, curve: Curves.elasticOut));
  late final Animation<double> _scale = CurvedAnimation(parent: _scaleCtl, curve: Curves.bounceOut);

  /* ────────────────────── Navigation ───────────────────── */
  int _selectedTab = 0;
  late final PageController _pageController;

  /* ────────────────────── Data Variables ───────────────────── */
  List<Transaction> _all = [];
  List<Transaction> _recent = [];
  List<Transaction> _uncategorizedTransactions = [];
  List<Category> _categories = [];
  Map<String, double> _categoryTotals = {};
  Map<String, int> _categoryTransactionCounts = {};
  double _spent = 0, _received = 0;
  bool _isLoading = true;
  bool _isSyncing = false;
  DateTime? _appFirstUsedDate;
  StreamSubscription<Transaction>? _transactionSubscription;

  /* ────────────────────── Auto-Sync Management ───────────────────── */
  Timer? _autoSyncTimer;
  DateTime? _lastAutoSync;
  static const Duration _autoSyncInterval = Duration(minutes: 3);

  /* ────────────────────── Filter States ───────────────────── */
  String _mainFilter = 'All';
  String _cardFilter = 'All';
  String _selectedPeriod = 'This Month';
  String _analysisFilter = 'Split';
  final _mainOptions = ['All', 'UPI', 'Card'];
  final _cardOptions = ['All', 'Debit Card', 'Credit Card'];

  /* ────────────────────── Performance Optimization ───────────────────── */
  DateTime? _lastDataUpdate;
  static const Duration _cacheValidDuration = Duration(minutes: 3);

  /* ────────────────────── Enhanced Color Scheme ───────────────────── */
  Color get _filterColor {
    switch (_mainFilter) {
      case 'UPI':
        return AppTheme.vibrantBlue;
      case 'Card':
        return AppTheme.darkOrangeRed;
      default:
        return AppTheme.vibrantGreen;
    }
  }

  IconData get _filterIcon {
    switch (_mainFilter) {
      case 'UPI':
        return Icons.account_balance_wallet_rounded;
      case 'Card':
        return Icons.credit_card_rounded;
      default:
        return Icons.dashboard_rounded;
    }
  }

  List<Color> get _cardGradientColors {
    switch (_mainFilter) {
      case 'UPI':
        return [AppTheme.vibrantBlue, AppTheme.vibrantBlue.withOpacity(0.8)];
      case 'Card':
        return [AppTheme.darkOrangeRed, Colors.deepOrange.withOpacity(0.8)];
      default:
        return [AppTheme.vibrantGreen, AppTheme.tealGreenDark];
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addObserver(this);
    _initApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fadeCtl.dispose();
    _pulseCtl.dispose();
    _slideCtl.dispose();
    _scaleCtl.dispose();
    _pageController.dispose();
    _transactionSubscription?.cancel();
    _autoSyncTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        print('📱 [LIFECYCLE] App resumed - refreshing data and restarting auto-sync');
        _loadData(forceRefresh: true);
        _startAutoSync();
        _performQuickSyncOnResume();
        break;
      case AppLifecycleState.paused:
        print('📱 [LIFECYCLE] App paused - stopping auto-sync');
        _stopAutoSync();
        break;
      case AppLifecycleState.inactive:
        print('📱 [LIFECYCLE] App inactive');
        break;
      case AppLifecycleState.detached:
        print('📱 [LIFECYCLE] App detached');
        _stopAutoSync();
        break;
      case AppLifecycleState.hidden:  // ✅ ADD THIS CASE
        print('📱 [LIFECYCLE] App hidden');
        break;
    }
  }


  /* ────────────────────── Auto-Sync Methods ───────────────────── */
  void _startAutoSync() {
    _stopAutoSync(); // Ensure no duplicate timers

    _autoSyncTimer = Timer.periodic(_autoSyncInterval, (timer) {
      if (mounted && !_isSyncing) {
        print('⏰ Auto-sync triggered after ${_autoSyncInterval.inMinutes} minutes');
        _performAutoSync();
      }
    });

    print('✅ Auto-sync started with ${_autoSyncInterval.inMinutes}-minute intervals');
  }

  void _stopAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
    print('⏹️ Auto-sync stopped');
  }

  Future<void> _performAutoSync() async {
    if (_isSyncing) {
      print('⏸️ Auto-sync skipped - manual sync in progress');
      return;
    }

    try {
      print('🔄 Performing auto-sync...');
      final result = await _syncService.triggerManualSync();

      if (result.success && result.newTransactions > 0) {
        await _loadData(forceRefresh: true);
        _lastAutoSync = DateTime.now();

        // Show subtle notification for auto-sync
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.sync_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text('Auto-sync: ${result.newTransactions} new transactions'),
                ],
              ),
              backgroundColor: AppTheme.vibrantGreen.withOpacity(0.9),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
            ),
          );
        }

        print('✅ Auto-sync completed: ${result.newTransactions} new transactions');
      } else {
        print('📊 Auto-sync: No new transactions');
      }
    } catch (e) {
      print('❌ Auto-sync error: $e');
    }
  }

  Future<void> _performQuickSyncOnResume() async {
    try {
      print('⚡ Performing quick sync on app resume...');

      // Force refresh SMS data to catch any missed transactions
      await _sms.processHistoricalSms();
      await _loadData(forceRefresh: true);

      print('✅ Quick sync on resume completed');
    } catch (e) {
      print('❌ Quick sync on resume error: $e');
    }
  }

  Future<void> _initApp() async {
    await _sms.initialize();
    await _syncService.initialize();
    await _categoryService.initialize();
    await _initializeAppFirstUsedDate();
    await _loadData();

    // Listen for new SMS transactions
    _transactionSubscription = _sms.watchNewTransactions().listen((t) {
      if (mounted) {
        setState(() {
          _all.insert(0, t);
        });
        _applyFilters();

        // Trigger haptic feedback for new transaction
        if (_settings.getBool('haptic_feedback', true)) {
          _settings.triggerHaptic(HapticFeedbackType.success);
        }
      }
    });

    _startContentAnimations();
    _startAutoSync(); // Start auto-sync after initialization
  }

  Future<void> _initializeAppFirstUsedDate() async {
    try {
      final savedDate = _store.getSetting<String>('app_first_use_date', '');
      if (savedDate.isNotEmpty) {
        _appFirstUsedDate = DateTime.parse(savedDate);
      }
    } catch (e) {
      print('❌ Error loading app first used date: $e');
    }
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    // Check cache validity
    if (!forceRefresh &&
        _lastDataUpdate != null &&
        DateTime.now().difference(_lastDataUpdate!) < _cacheValidDuration &&
        _all.isNotEmpty) {
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Load data in parallel with proper error handling
      final List<dynamic> results = await Future.wait<dynamic>([
        _sms.getHistoricalTransactions().catchError((e) {
          print('❌ Error loading transactions: $e');
          return <Transaction>[];
        }),
        _categoryService.getCategories().catchError((e) {
          print('❌ Error loading categories: $e');
          return <Category>[];
        }),
      ]);

      final allTransactions = results[0] as List<Transaction>;
      final categories = results[1] as List<Category>;

      if (!mounted) return;

      setState(() {
        _all = allTransactions;
        _categories = categories;
        _isLoading = false;
        _lastDataUpdate = DateTime.now();
      });

      _applyFilters();
      print('📊 Dashboard data loaded: ${_all.length} transactions, ${_categories.length} categories');
    } catch (e) {
      print('❌ Error in _loadData: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _startContentAnimations() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _slideCtl.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _scaleCtl.forward();
    });
  }

  /* ────────────────────── Helper Methods ───────────────────── */
  bool _isDebitCard(Transaction t) =>
      t.method == BankTransactionMethod.debitCard ||
          t.originalMessage.toLowerCase().contains('debit card') ||
          t.originalMessage.toLowerCase().contains(' dc ') ||
          t.originalMessage.toLowerCase().contains('debit ');

  bool _isCreditCard(Transaction t) =>
      t.method == BankTransactionMethod.creditCard ||
          t.originalMessage.toLowerCase().contains('credit card') ||
          t.originalMessage.toLowerCase().contains(' cc ') ||
          t.originalMessage.toLowerCase().contains('credit ');

  bool _isUPI(Transaction t) =>
      t.method == BankTransactionMethod.upi ||
          t.originalMessage.toLowerCase().contains('upi') ||
          t.merchant.toLowerCase().contains('upi') ||
          t.originalMessage.toLowerCase().contains('paytm') ||
          t.originalMessage.toLowerCase().contains('gpay') ||
          t.originalMessage.toLowerCase().contains('phonepe');

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  Color _getTransactionColor(Transaction t) {
    if (_isUPI(t)) return AppTheme.vibrantBlue;
    if (_isDebitCard(t)) return Colors.indigo;
    if (_isCreditCard(t)) return AppTheme.darkOrangeRed;
    return AppTheme.tealGreenDark;
  }

  IconData _getTransactionIcon(Transaction t) {
    if (_isUPI(t)) return Icons.account_balance_wallet_rounded;
    if (_isDebitCard(t)) return Icons.credit_card_rounded;
    if (_isCreditCard(t)) return Icons.credit_card_outlined;
    return Icons.monetization_on_rounded;
  }

  Widget _getCardImage(Transaction t) {
    if (_isCreditCard(t)) {
      return Container(
        width: 28,
        height: 18,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF6B35), Color(0xFFE63946)],
          ),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE63946).withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'CC',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    } else if (_isDebitCard(t)) {
      return Container(
        width: 28,
        height: 18,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3F51B5), Color(0xFF303F9F)],
          ),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF303F9F).withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'DC',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
    return const SizedBox();
  }

  /* ────────────────────── Data Processing ───────────────────── */
  void _applyFilters() {
    List<Transaction> filteredTransactions = _filterTransactionsFromAppStart(_all);
    Iterable<Transaction> list = filteredTransactions;

    switch (_mainFilter) {
      case 'UPI':
        list = list.where(_isUPI);
        break;
      case 'Card':
        list = list.where((t) => _isDebitCard(t) || _isCreditCard(t));
        if (_cardFilter == 'Debit Card') list = list.where(_isDebitCard);
        if (_cardFilter == 'Credit Card') list = list.where(_isCreditCard);
        break;
    }

    final periodFilteredTransactions = _filterTransactionsByPeriod(list.toList());
    final metrics = _calculateMetricsEfficiently(periodFilteredTransactions);

    _recent = periodFilteredTransactions.take(8).toList();
    _spent = 0;
    _received = 0;

    for (final t in periodFilteredTransactions) {
      if (t.type == TransactionType.debit) {
        _spent += t.amount;
      } else {
        _received += t.amount;
      }
    }

    _categoryTotals = metrics['categoryTotals'] as Map<String, double>;
    _categoryTransactionCounts = metrics['categoryCounts'] as Map<String, int>;
    _uncategorizedTransactions = periodFilteredTransactions
        .where((t) => t.categoryId.isEmpty || t.categoryId == 'default_uncategorized' || !t.isCategorized)
        .toList();

    print('🔍 Applied filters: ${_recent.length} recent, ${_uncategorizedTransactions.length} uncategorized');
  }

  List<Transaction> _filterTransactionsFromAppStart(List<Transaction> allTransactions) {
    if (_appFirstUsedDate == null) return allTransactions;
    return allTransactions.where((transaction) =>
    transaction.dateTime.isAfter(_appFirstUsedDate!) ||
        transaction.dateTime.isAtSameMomentAs(_appFirstUsedDate!)
    ).toList();
  }

  List<Transaction> _filterTransactionsByPeriod(List<Transaction> allTransactions) {
    final now = DateTime.now();
    DateTime startDate;

    switch (_selectedPeriod) {
      case 'Today':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'This Week':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case 'This Month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'Last 3 Months':
        startDate = DateTime(now.year, now.month - 2, 1);
        break;
      case 'This Year':
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        startDate = DateTime(now.year, now.month, 1);
    }

    return allTransactions.where((t) =>
    t.dateTime.isAfter(startDate) &&
        t.dateTime.isBefore(now.add(const Duration(days: 1)))
    ).toList();
  }

  Map<String, dynamic> _calculateMetricsEfficiently(List<Transaction> transactions) {
    final categoryTotals = <String, double>{};
    final categoryCounts = <String, int>{};

    for (final transaction in transactions) {
      if (transaction.type == TransactionType.debit) {
        final categoryId = transaction.categoryId.isNotEmpty
            ? transaction.categoryId
            : 'default_uncategorized';

        categoryTotals[categoryId] = (categoryTotals[categoryId] ?? 0) + transaction.amount;
        categoryCounts[categoryId] = (categoryCounts[categoryId] ?? 0) + 1;
      }
    }

    return {
      'categoryTotals': categoryTotals,
      'categoryCounts': categoryCounts,
    };
  }

  double _calculateAverageDailySpending() {
    if (_all.isEmpty || _appFirstUsedDate == null) return 0.0;
    final debitTransactions = _all.where((t) => t.type == TransactionType.debit).toList();
    if (debitTransactions.isEmpty) return 0.0;
    final daysSinceFirstUse = DateTime.now().difference(_appFirstUsedDate!).inDays + 1;
    return daysSinceFirstUse > 0 ? _spent / daysSinceFirstUse : 0.0;
  }

  Future<void> _performManualSync() async {
    if (_isSyncing) return;

    setState(() => _isSyncing = true);

    // Trigger haptic feedback
    if (_settings.getBool('haptic_feedback', true)) {
      _settings.triggerHaptic(HapticFeedbackType.impact);
    }

    try {
      print('🔄 Starting manual sync...');

      // Force process all SMS messages to catch any missed transactions
      await _sms.processHistoricalSms();

      final result = await _syncService.triggerManualSync();

      if (result.success) {
        await _loadData(forceRefresh: true);

        if (mounted) {
          final message = result.newTransactions > 0
              ? 'Found ${result.newTransactions} new transactions!'
              : 'No new transactions found';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    result.newTransactions > 0 ? Icons.check_circle : Icons.info,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(message)),
                ],
              ),
              backgroundColor: result.newTransactions > 0 ? AppTheme.vibrantGreen : AppTheme.vibrantBlue,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 3),
            ),
          );
        }

        if (_settings.getBool('haptic_feedback', true)) {
          _settings.triggerHaptic(HapticFeedbackType.success);
        }

        print('✅ Manual sync completed: ${result.newTransactions} new transactions');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Sync failed: ${result.message}')),
                ],
              ),
              backgroundColor: AppTheme.darkOrangeRed,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Manual sync error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync error: $e'),
            backgroundColor: AppTheme.darkOrangeRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  void _changePeriod() {
    if (_settings.getBool('haptic_feedback', true)) {
      _settings.triggerHaptic(HapticFeedbackType.selection);
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // ✅ FIXED: Added scroll control
      builder: (context) => DraggableScrollableSheet( // ✅ FIXED: Use DraggableScrollableSheet
        initialChildSize: 0.6,
        maxChildSize: 0.8,
        minChildSize: 0.4,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded( // ✅ FIXED: Use Expanded
                child: SingleChildScrollView( // ✅ FIXED: Make scrollable
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Time Period',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 20),
                      ...['Today', 'This Week', 'This Month', 'Last 3 Months', 'This Year']
                          .map((period) => _buildPeriodOption(period))
                          .toList(),
                      const SizedBox(height: 20),
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


  Widget _buildPeriodOption(String period) {
    final isSelected = _selectedPeriod == period;

    return Container(
      margin: const EdgeInsets.only(bottom: 6), // ✅ FIXED: Reduced margin
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (_settings.getBool('haptic_feedback', true)) {
              _settings.triggerHaptic(HapticFeedbackType.selection);
            }
            setState(() => _selectedPeriod = period);
            Navigator.pop(context);
            _applyFilters();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16), // ✅ FIXED: Reduced padding
            decoration: BoxDecoration(
              color: isSelected
                  ? _filterColor.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? _filterColor.withOpacity(0.3)
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6), // ✅ FIXED: Reduced padding
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _filterColor.withOpacity(0.2)
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getPeriodIcon(period),
                    color: isSelected
                        ? _filterColor
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    size: 16, // ✅ FIXED: Smaller icon
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    period,
                    style: TextStyle(
                      fontSize: 14, // ✅ FIXED: Smaller font
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? _filterColor
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: _filterColor,
                    size: 18, // ✅ FIXED: Smaller icon
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  IconData _getPeriodIcon(String period) {
    switch (period) {
      case 'Today': return Icons.today;
      case 'This Week': return Icons.view_week;
      case 'This Month': return Icons.calendar_month;
      case 'Last 3 Months': return Icons.calendar_view_month;
      case 'This Year': return Icons.calendar_today;
      default: return Icons.date_range;
    }
  }

  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else if (hour < 21) {
      return 'Good Evening';
    } else {
      return 'Good Night';
    }
  }

  /* ────────────────────── Main Build Method ───────────────────── */
  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedTab = index;
          });
        },
        children: [
          _getDashboardContent(),
          const TransactionsScreen(),
          const CategoriesScreen(),
          const ReportsScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  /* ────────────────────── Bottom Navigation Bar ───────────────────── */
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: LayoutBuilder( // ✅ Added LayoutBuilder for dynamic height
          builder: (context, constraints) {
            final screenHeight = MediaQuery.of(context).size.height;
            final isSmallScreen = screenHeight < 700;

            return Container(
              height: isSmallScreen ? 60 : 70, // ✅ Dynamic height
              padding: EdgeInsets.symmetric(
                horizontal: 16, // ✅ Reduced horizontal padding
                vertical: isSmallScreen ? 4 : 8, // ✅ Dynamic vertical padding
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(child: _buildNavItem(0, Icons.dashboard_rounded, 'Dashboard')),
                  Expanded(child: _buildNavItem(1, Icons.receipt_long_rounded, 'Transactions')),
                  Expanded(child: _buildNavItem(2, Icons.category_rounded, 'Categories')),
                  Expanded(child: _buildNavItem(3, Icons.analytics_rounded, 'Reports')),
                  Expanded(child: _buildNavItem(4, Icons.settings_rounded, 'Settings')),
                ],
              ),
            );
          },
        ),
      ),
    );
  }


  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedTab == index;
    final color = isSelected ? _filterColor : Theme.of(context).colorScheme.onSurface.withOpacity(0.6);

    return GestureDetector(
      onTap: () {
        if (_settings.getBool('haptic_feedback', true)) {
          _settings.triggerHaptic(HapticFeedbackType.selection);
        }

        setState(() {
          _selectedTab = index;
        });

        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), // ✅ Reduced padding
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: LayoutBuilder( // ✅ Added LayoutBuilder for responsive sizing
          builder: (context, constraints) {
            final availableHeight = constraints.maxHeight;
            final isCompact = availableHeight < 50;

            return Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: color,
                  size: isCompact ? 18 : 22, // ✅ Dynamic icon size
                ),
                if (!isCompact) ...[
                  const SizedBox(height: 2), // ✅ Reduced spacing
                  Flexible( // ✅ Added Flexible to prevent overflow
                    child: Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 9, // ✅ Smaller font size
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }


  /* ────────────────────── Dashboard Content ───────────────────── */
  Widget _getDashboardContent() {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    return RefreshIndicator(
      onRefresh: () => _loadData(forceRefresh: true),
      color: Theme.of(context).colorScheme.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          _dashboardAppBar(),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFilterSection(),
                    _balanceCard(),
                    _gridOverview(),
                    if (_uncategorizedTransactions.isNotEmpty)
                      _buildUncategorizedAlert(),
                    _recentActivity(),
                    _buildSpendingAnalysis(),
                    _buildEnhancedCategoryBreakdown(),
                    const SizedBox(height: 120), // Extra space for bottom navigation
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /* ────────────────────── Enhanced App Bar (FIXED & DYNAMIC) ───────────────────── */
  Widget _dashboardAppBar() {
    return SliverAppBar(
      expandedHeight: 80,
      floating: true,
      snap: true,
      pinned: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _cardGradientColors,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 10), // ✅ Reduced padding
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;

                // ✅ Enhanced responsive breakpoints
                final isExtraSmall = screenWidth < 300;
                final isSmall = screenWidth < 350;
                final isMedium = screenWidth < 400;
                final isLarge = screenWidth >= 400;

                // ✅ Dynamic sizing based on screen width
                final greetingFontSize = isExtraSmall ? 8.0 : (isSmall ? 9.0 : (isMedium ? 10.0 : 11.0));
                final titleFontSize = isExtraSmall ? 11.0 : (isSmall ? 12.0 : (isMedium ? 14.0 : 16.0));
                final buttonSize = isExtraSmall ? 28.0 : (isSmall ? 30.0 : (isMedium ? 32.0 : 34.0));
                final iconSize = isExtraSmall ? 12.0 : (isSmall ? 13.0 : (isMedium ? 14.0 : 16.0));

                return Align(
                  alignment: Alignment.bottomCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: 36, // ✅ SOLUTION: Fixed max height
                      minHeight: 32,
                    ),
                    child: IntrinsicHeight( // ✅ SOLUTION: Ensures proper height distribution
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // ✅ FIXED: Left side - Greeting and title with proper constraints
                          Expanded(
                            flex: isExtraSmall ? 4 : (isSmall ? 3 : 2),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxHeight: 34, // ✅ Ensures content fits
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // ✅ Greeting text with proper constraints
                                  SizedBox(
                                    height: 14, // ✅ Fixed height for greeting
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        _getTimeBasedGreeting(),
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: greetingFontSize,
                                          fontWeight: FontWeight.w400,
                                          height: 1.0,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),

                                  // ✅ Title text with proper constraints
                                  SizedBox(
                                    height: 18, // ✅ Fixed height for title
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: ShaderMask(
                                        shaderCallback: (bounds) => const LinearGradient(
                                          colors: [Colors.white, Color(0xFFE8F4FD)],
                                        ).createShader(bounds),
                                        child: Text(
                                          isExtraSmall ? 'Overview' : 'Financial Overview',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: titleFontSize,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.1,
                                            height: 1.0,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(width: isExtraSmall ? 4 : (isSmall ? 6 : 8)),

                          // ✅ FIXED: Right side - Action buttons with responsive design
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // ✅ Period selector - adaptive visibility and sizing
                              if (isLarge)
                                Container(
                                  height: buttonSize,
                                  constraints: BoxConstraints(
                                    maxWidth: 75,
                                    minWidth: 55,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(6),
                                      onTap: _changePeriod,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.calendar_today_rounded,
                                              color: Colors.white,
                                              size: 8,
                                            ),
                                            const SizedBox(width: 2),
                                            Flexible(
                                              child: Text(
                                                _getShortPeriodName(_selectedPeriod),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                              if (isLarge) SizedBox(width: isSmall ? 4 : 6),

                              // ✅ Sync button - fully responsive
                              Container(
                                width: buttonSize,
                                height: buttonSize,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 0.5,
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(6),
                                    onTap: _isSyncing ? null : _performManualSync,
                                    child: Center(
                                      child: _isSyncing
                                          ? SizedBox(
                                        width: iconSize - 2,
                                        height: iconSize - 2,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                          : Icon(
                                        Icons.sync_rounded,
                                        color: Colors.white,
                                        size: iconSize,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // ✅ Menu/Calendar button for smaller screens
                              if (!isLarge) ...[
                                SizedBox(width: isExtraSmall ? 4 : 6),
                                Container(
                                  width: buttonSize,
                                  height: buttonSize,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(6),
                                      onTap: _changePeriod,
                                      child: Center(
                                        child: Icon(
                                          Icons.calendar_today_rounded,
                                          color: Colors.white,
                                          size: iconSize,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

// ✅ Enhanced helper method for period names
  String _getShortPeriodName(String period) {
    switch (period) {
      case 'This Week':
        return 'Week';
      case 'This Month':
        return 'Month';
      case 'Last Month':
        return 'Last';
      case 'This Year':
        return 'Year';
      case 'Last 3 Months':
        return '3M';
      case 'Custom':
        return 'Custom';
      default:
        return period.length > 4 ? period.substring(0, 4) : period;
    }
  }

// ✅ FIXED: Responsive Filter Section
  Widget _buildFilterSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isSmallScreen = screenWidth < 350;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 16 : 20,
            vertical: isSmallScreen ? 8 : 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _mainFilterBar(),
              if (_mainFilter == 'Card') ...[
                SizedBox(height: isSmallScreen ? 6 : 8),
                _cardSubFilterBar(),
              ],
            ],
          ),
        );
      },
    );
  }


  Widget _mainFilterBar() => _glassBar(
    options: _mainOptions,
    selected: _mainFilter,
    onTap: (f) {
      setState(() {
        _mainFilter = f;
        if (f != 'Card') _cardFilter = 'All';
        _applyFilters();
      });
    },
  );

  Widget _cardSubFilterBar() => _glassBar(
    options: _cardOptions,
    selected: _cardFilter,
    height: 50,
    onTap: (f) {
      setState(() {
        _cardFilter = f;
        _applyFilters();
      });
    },
  );

  Widget _glassBar({
    required List<String> options,
    required String selected,
    required ValueChanged<String> onTap,
    double height = 60,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: height,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _filterColor.withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: _filterColor.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: options.map((opt) {
              final sel = opt == selected;
              Color optionColor = _filterColor;
              if (opt == 'UPI') optionColor = AppTheme.vibrantBlue;
              if (opt == 'Card') optionColor = AppTheme.darkOrangeRed;
              if (opt == 'Debit Card') optionColor = Colors.indigo;
              if (opt == 'Credit Card') optionColor = AppTheme.darkOrangeRed;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (_settings.getBool('haptic_feedback', true)) {
                      _settings.triggerHaptic(HapticFeedbackType.selection);
                    }
                    onTap(opt);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      gradient: sel
                          ? LinearGradient(
                          colors: [optionColor, optionColor.withOpacity(.7)])
                          : null,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: sel ? [
                        BoxShadow(
                          color: optionColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ] : null,
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (opt == 'UPI')
                            Icon(
                              Icons.account_balance_wallet_rounded,
                              size: height > 50 ? 14 : 12,
                              color: sel ? Colors.white : optionColor,
                            ),
                          if (opt == 'Card')
                            Icon(
                              Icons.credit_card_rounded,
                              size: height > 50 ? 14 : 12,
                              color: sel ? Colors.white : optionColor,
                            ),
                          if (opt == 'UPI' || opt == 'Card') const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              opt,
                              style: TextStyle(
                                fontSize: height > 50 ? 14 : 12,
                                fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                                color: sel ? Colors.white : optionColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  /* ────────────────────── Balance Card (DYNAMIC) ───────────────────── */
  Widget _balanceCard() {
    final bal = _received - _spent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, child) => Transform.scale(scale: _pulse.value, child: child),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 350;

            return Container(
              width: double.infinity,
              padding: EdgeInsets.all(isSmallScreen ? 20 : 28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _cardGradientColors,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: _filterColor.withOpacity(.35),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(_filterIcon, color: Colors.white, size: isSmallScreen ? 18 : 20),
                            SizedBox(width: isSmallScreen ? 6 : 8),
                            Flexible(
                              child: Text(
                                '${_mainFilter == 'All' ? 'Total' : _mainFilter} Balance',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isSmallScreen ? 14 : 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_mainFilter == 'Card')
                        Row(
                          children: [
                            _getCardImage(Transaction(
                              id: '',
                              amount: 0,
                              type: TransactionType.debit,
                              merchant: '',
                              sender: '',
                              dateTime: DateTime.now(),
                              originalMessage: 'debit card',
                              categoryId: 'default_uncategorized',
                              isCategorized: false,
                            )),
                            const SizedBox(width: 4),
                            _getCardImage(Transaction(
                              id: '',
                              amount: 0,
                              type: TransactionType.debit,
                              merchant: '',
                              sender: '',
                              dateTime: DateTime.now(),
                              originalMessage: 'credit card',
                              categoryId: 'default_uncategorized',
                              isCategorized: false,
                            )),
                          ],
                        ),
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 12 : 16),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '₹${bal.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 28 : 36,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 4 : 6),
                  Text(
                    'From ${_recent.length} transactions',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: isSmallScreen ? 12 : 14,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /* ────────────────────── Grid Overview (DYNAMIC) ───────────────────── */
  Widget _gridOverview() {
    final balance = _received - _spent;
    final avgDailySpending = _calculateAverageDailySpending();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: ScaleTransition(
        scale: _scale,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final crossAxisCount = screenWidth < 600 ? 2 : 4;
            final screenHeight = MediaQuery.of(context).size.height;

            // ✅ FIXED: Calculate proper item height based on screen size
            final itemHeight = screenHeight < 700 ? 130 : 150;
            final childAspectRatio = (screenWidth / crossAxisCount) / itemHeight;

            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              childAspectRatio: childAspectRatio.clamp(0.8, 1.2), // ✅ FIXED: Clamp ratio
              mainAxisSpacing: 12, // ✅ FIXED: Reduced spacing
              crossAxisSpacing: 12, // ✅ FIXED: Reduced spacing
              children: [
                _buildSummaryCard(
                  'Total Spent',
                  _spent,
                  Icons.trending_up_rounded,
                  AppTheme.darkOrangeRed,
                  '${_all.where((t) => t.type == TransactionType.debit).length} transactions',
                ),
                _buildSummaryCard(
                  'Total Received',
                  _received,
                  Icons.trending_down_rounded,
                  AppTheme.vibrantGreen,
                  '${_all.where((t) => t.type == TransactionType.credit).length} transactions',
                ),
                _buildSummaryCard(
                  'Net Balance',
                  balance,
                  Icons.account_balance_wallet_rounded,
                  balance >= 0 ? AppTheme.vibrantBlue : AppTheme.darkOrangeRed,
                  balance >= 0 ? 'Surplus' : 'Deficit',
                ),
                _buildSummaryCard(
                  'Daily Average',
                  avgDailySpending,
                  Icons.calendar_today_rounded,
                  AppTheme.tealGreenDark,
                  'Spending per day',
                ),
              ],
            );
          },
        ),
      ),
    );
  }


  Widget _buildSummaryCard(String title, double amount, IconData icon, Color color, String subtitle) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallCard = constraints.maxWidth < 150;
        final cardHeight = constraints.maxHeight;
        final isCompactHeight = cardHeight < 120;

        return Container(
          padding: EdgeInsets.all(isSmallCard ? 12 : 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon container
              Container(
                padding: EdgeInsets.all(isSmallCard ? 8 : 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: isSmallCard ? 16 : 20, // ✅ FIXED: Reduced icon size
                ),
              ),

              // Spacing
              SizedBox(height: isCompactHeight ? 6 : 10), // ✅ FIXED: Dynamic spacing

              // Title
              Flexible( // ✅ FIXED: Wrap title in Flexible
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: isSmallCard ? 11 : 13, // ✅ FIXED: Smaller font
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Small spacing
              SizedBox(height: isCompactHeight ? 2 : 4),

              // Amount
              Flexible( // ✅ FIXED: Wrap amount in Flexible
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '₹${amount.toStringAsFixed(amount < 100 ? 2 : 0)}',
                    style: TextStyle(
                      fontSize: isSmallCard ? 14 : 18, // ✅ FIXED: Smaller font
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ),

              // Small spacing
              SizedBox(height: isCompactHeight ? 2 : 4),

              // Subtitle
              Flexible( // ✅ FIXED: Wrap subtitle in Flexible
                child: Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: isSmallCard ? 9 : 11, // ✅ FIXED: Smaller font
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  /* ────────────────────── Recent Activity (DYNAMIC) ───────────────────── */
  Widget _recentActivity() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _filterColor.withOpacity(0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: _filterColor.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(_filterIcon, color: _filterColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Recent Activity',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            if (_recent.isEmpty)
              Container(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _filterColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        size: 40,
                        color: _filterColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No transactions',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(.7),
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recent.length,
                separatorBuilder: (_, __) => Divider(
                  indent: 20,
                  endIndent: 20,
                  color: Theme.of(context).dividerColor,
                ),
                itemBuilder: (_, i) => _txnTile(_recent[i]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _txnTile(Transaction t) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallTile = constraints.maxWidth < 350;

        return ListTile(
          leading: Container(
            padding: EdgeInsets.all(isSmallTile ? 8 : 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_getTransactionColor(t), _getTransactionColor(t).withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _getTransactionColor(t).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              t.type == TransactionType.debit ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              color: Colors.white,
              size: isSmallTile ? 14 : 16,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  t.merchant,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: isSmallTile ? 14 : null,
                  ),
                ),
              ),
              if (_isDebitCard(t) || _isCreditCard(t)) ...[
                const SizedBox(width: 8),
                _getCardImage(t),
              ],
            ],
          ),
          subtitle: Row(
            children: [
              Icon(
                _getTransactionIcon(t),
                size: 12,
                color: _getTransactionColor(t),
              ),
              const SizedBox(width: 4),
              Expanded( // ✅ FIXED: Wrap subtitle text in Expanded
                child: Text(
                  _timeAgo(t.dateTime),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: isSmallTile ? 12 : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          trailing: LayoutBuilder( // ✅ FIXED: Wrap trailing in LayoutBuilder
            builder: (context, trailingConstraints) {
              final availableWidth = trailingConstraints.maxWidth;
              final availableHeight = trailingConstraints.maxHeight;
              final isNarrow = availableWidth < 80;
              final isCompact = availableHeight < 60;

              return SizedBox(
                width: isNarrow ? 70 : 80, // ✅ FIXED: Constrain width
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min, // ✅ FIXED: Added mainAxisSize.min
                  children: [
                    // Amount section
                    Flexible( // ✅ FIXED: Wrap amount in Flexible
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${t.type == TransactionType.debit ? '-' : '+'}₹${t.amount.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: t.type == TransactionType.debit
                                ? AppTheme.darkOrangeRed
                                : AppTheme.vibrantGreen,
                            fontWeight: FontWeight.w600,
                            fontSize: isSmallTile ? 12 : 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),

                    // Spacing (only if not compact)
                    if (!isCompact)
                      SizedBox(height: isCompact ? 2 : 4),

                    // Tags section
                    if (!isCompact) // ✅ FIXED: Only show tags if there's space
                      Flexible( // ✅ FIXED: Wrap tags in Flexible
                        child: SingleChildScrollView( // ✅ FIXED: Make tags scrollable if needed
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!t.isCategorized) _tag('Uncat', AppTheme.darkOrangeRed),
                              if (_isUPI(t)) ...[
                                if (!t.isCategorized) const SizedBox(width: 2),
                                _tag('UPI', AppTheme.vibrantBlue),
                              ],
                              if (_isDebitCard(t)) ...[
                                if (!t.isCategorized || _isUPI(t)) const SizedBox(width: 2),
                                _tag('DC', Colors.indigo),
                              ],
                              if (_isCreditCard(t)) ...[
                                if (!t.isCategorized || _isUPI(t) || _isDebitCard(t)) const SizedBox(width: 2),
                                _tag('CC', AppTheme.darkOrangeRed),
                              ],
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          onTap: () {
            if (_settings.getBool('haptic_feedback', true)) {
              _settings.triggerHaptic(HapticFeedbackType.selection);
            }
            _showPopup(t);
          },
        );
      },
    );
  }


  Widget _tag(String txt, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), // ✅ FIXED: Reduced padding
    decoration: BoxDecoration(
      color: c.withOpacity(.15),
      borderRadius: BorderRadius.circular(3), // ✅ FIXED: Smaller radius
    ),
    child: Text(
      txt,
      style: TextStyle(
        fontSize: 7, // ✅ FIXED: Smaller font size
        color: c,
        fontWeight: FontWeight.w500,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
  );


  void _showPopup(Transaction t) {
    showDialog(
      context: context,
      builder: (_) => TransactionPopup(
        transaction: t,
        onSave: (newT) async {
          await _store.saveTransaction(newT);
          await _loadData(forceRefresh: true);
        },
      ),
    );
  }

  /* ────────────────────── Uncategorized Alert ───────────────────── */
  Widget _buildUncategorizedAlert() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallAlert = constraints.maxWidth < 350;

          return Container(
            padding: EdgeInsets.all(isSmallAlert ? 16 : 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.darkOrangeRed.withOpacity(0.15),
                  AppTheme.darkOrangeRed.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.darkOrangeRed.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isSmallAlert ? 10 : 12),
                  decoration: BoxDecoration(
                    color: AppTheme.darkOrangeRed.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.warning_rounded,
                    color: AppTheme.darkOrangeRed,
                    size: isSmallAlert ? 20 : 24,
                  ),
                ),
                SizedBox(width: isSmallAlert ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Action Required',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: isSmallAlert ? 14 : null,
                        ),
                      ),
                      SizedBox(height: isSmallAlert ? 2 : 4),
                      Text(
                        '${_uncategorizedTransactions.length} transactions need categorization',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: isSmallAlert ? 12 : null,
                        ),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: AppTheme.darkOrangeRed,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showBulkCategorization(),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallAlert ? 12 : 16,
                        vertical: isSmallAlert ? 10 : 12,
                      ),
                      child: Text(
                        'Categorize',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallAlert ? 12 : 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /* ────────────────────── Spending Analysis ───────────────────── */
  Widget _buildSpendingAnalysis() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spending Analysis',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _filterColor.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: ['Split', 'Trend'].map((filter) {
                    final isSelected = _analysisFilter == filter;
                    return GestureDetector(
                      onTap: () {
                        if (_settings.getBool('haptic_feedback', true)) {
                          _settings.triggerHaptic(HapticFeedbackType.selection);
                        }
                        setState(() => _analysisFilter = filter);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? _filterColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          filter,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : _filterColor,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: _analysisFilter == 'Split'
                ? _buildPieChartSection()
                : _buildTrendChartSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartSection() {
    if (_categoryTotals.isEmpty) {
      return _buildEmptyAnalysis();
    }

    return Container(
      key: const ValueKey('pie_chart'),
      height: 380, // ✅ FIXED: Increased height for better spacing
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _filterColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _filterColor.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with proper spacing
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10), // ✅ FIXED: Reduced bottom padding
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_filterColor.withOpacity(0.2), _filterColor.withOpacity(0.1)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.pie_chart_rounded,
                    color: _filterColor,
                    size: 18, // ✅ FIXED: Smaller icon
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Spending Breakdown',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 16, // ✅ FIXED: Consistent font size
                  ),
                ),
              ],
            ),
          ),

          // Pie Chart with proper centering
          Expanded( // ✅ FIXED: Use Expanded for chart area
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20), // ✅ FIXED: Added horizontal padding
              child: Center( // ✅ FIXED: Center the chart
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final availableHeight = constraints.maxHeight - 20; // ✅ FIXED: Account for padding
                    final availableWidth = constraints.maxWidth;
                    final chartSize = (availableHeight < availableWidth ? availableHeight : availableWidth) * 0.8; // ✅ FIXED: Proper sizing

                    return SizedBox(
                      width: chartSize,
                      height: chartSize,
                      child: TransactionPieChart(
                        transactions: _recent.where((t) => t.type == TransactionType.debit).toList(),
                        categories: _categories,
                        maxWidth: chartSize,
                        maxHeight: chartSize,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Bottom spacing
          const SizedBox(height: 20),
        ],
      ),
    );
  }


  Widget _buildTrendChartSection() {
    return Container(
      key: const ValueKey('trend_chart'),
      height: 320,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _filterColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _filterColor.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spending Trend',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TransactionBarChart(
                transactions: _recent.where((t) => t.type == TransactionType.debit).toList(),
                period: _selectedPeriod,
                maxHeight: 240,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyAnalysis() {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _filterColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.pie_chart_outline_rounded,
                size: 48,
                color: _filterColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No spending data',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Start making transactions to see analysis',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  /* ────────────────────── Enhanced Category Breakdown ───────────────────── */
  Widget _buildEnhancedCategoryBreakdown() {
    final sortedCategories = _categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _filterColor.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _filterColor.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Category Breakdown',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (_uncategorizedTransactions.isNotEmpty)
                    Material(
                      color: _filterColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: _showBulkCategorization,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.category_rounded,
                                color: _filterColor,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Categorize All',
                                style: TextStyle(
                                  color: _filterColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (sortedCategories.isEmpty)
              _buildEmptyCategoryBreakdown()
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 20),
                itemCount: sortedCategories.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor,
                  indent: 20,
                  endIndent: 20,
                ),
                itemBuilder: (context, index) {
                  final entry = sortedCategories[index];
                  final category = _categories.firstWhere(
                        (c) => c.id == entry.key,
                    orElse: () => Category(
                      id: entry.key,
                      name: entry.key == 'default_uncategorized' ? 'Uncategorized' : entry.key,
                      description: 'Category',
                      type: 'expense',
                      icon: Icons.category_rounded,
                      color: Colors.grey,
                    ),
                  );

                  final percentage = _spent > 0 ? (entry.value / _spent * 100).clamp(0, 100) : 0.0;
                  final transactionCount = _categoryTransactionCounts[entry.key] ?? 0;

                  return _buildEnhancedCategoryItem(
                    category,
                    entry.value.toDouble(),
                    percentage.toDouble(),
                    transactionCount,
                    index,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedCategoryItem(Category category, double amount, double percentage, int count, int index) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallItem = constraints.maxWidth < 350;

        return AnimatedContainer(
          duration: Duration(milliseconds: 200 + (index * 50)),
          curve: Curves.easeOutBack,
          child: Container(
            padding: EdgeInsets.all(isSmallItem ? 16 : 20),
            child: Row(
              children: [
                Container(
                  width: isSmallItem ? 48 : 56,
                  height: isSmallItem ? 48 : 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        category.color.withOpacity(0.9),
                        category.color.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: category.color.withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    category.icon,
                    color: Colors.white,
                    size: isSmallItem ? 24 : 28,
                  ),
                ),
                SizedBox(width: isSmallItem ? 16 : 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              category.name,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                                fontSize: isSmallItem ? 16 : null,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallItem ? 12 : 16,
                              vertical: isSmallItem ? 6 : 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [category.color.withOpacity(0.15), category.color.withOpacity(0.08)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: category.color.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '₹${amount.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: isSmallItem ? 14 : 16,
                                fontWeight: FontWeight.w800,
                                color: category.color,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isSmallItem ? 8 : 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: category.color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.receipt_long_rounded,
                                  size: isSmallItem ? 14 : 16,
                                  color: category.color,
                                ),
                              ),
                              SizedBox(width: isSmallItem ? 6 : 8),
                              Text(
                                '$count transaction${count != 1 ? 's' : ''}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  fontSize: isSmallItem ? 12 : null,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallItem ? 10 : 12,
                              vertical: isSmallItem ? 4 : 6,
                            ),
                            decoration: BoxDecoration(
                              color: percentage >= 20
                                  ? AppTheme.darkOrangeRed.withOpacity(0.1)
                                  : percentage >= 10
                                  ? AppTheme.warningOrange.withOpacity(0.1)
                                  : AppTheme.vibrantGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: percentage >= 20
                                    ? AppTheme.darkOrangeRed.withOpacity(0.3)
                                    : percentage >= 10
                                    ? AppTheme.warningOrange.withOpacity(0.3)
                                    : AppTheme.vibrantGreen.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  percentage >= 20
                                      ? Icons.trending_up_rounded
                                      : percentage >= 10
                                      ? Icons.trending_flat_rounded
                                      : Icons.trending_down_rounded,
                                  size: isSmallItem ? 12 : 14,
                                  color: percentage >= 20
                                      ? AppTheme.darkOrangeRed
                                      : percentage >= 10
                                      ? AppTheme.warningOrange
                                      : AppTheme.vibrantGreen,
                                ),
                                SizedBox(width: isSmallItem ? 3 : 4),
                                Text(
                                  '${percentage.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: isSmallItem ? 10 : 12,
                                    fontWeight: FontWeight.w600,
                                    color: percentage >= 20
                                        ? AppTheme.darkOrangeRed
                                        : percentage >= 10
                                        ? AppTheme.warningOrange
                                        : AppTheme.vibrantGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isSmallItem ? 12 : 16),
                      Stack(
                        children: [
                          Container(
                            height: isSmallItem ? 8 : 10,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.outline.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          AnimatedContainer(
                            duration: Duration(milliseconds: 800 + (index * 150)),
                            curve: Curves.easeOutCubic,
                            height: isSmallItem ? 8 : 10,
                            width: constraints.maxWidth * 0.65 * (percentage / 100),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  category.color,
                                  category.color.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(5),
                              boxShadow: [
                                BoxShadow(
                                  color: category.color.withOpacity(0.4),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyCategoryBreakdown() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _filterColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.category_rounded,
              size: 40,
              color: _filterColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No categories',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(.7),
            ),
          ),
        ],
      ),
    );
  }

  /* ────────────────────── Enhanced Loading Widget ───────────────────── */
  Widget _buildLoadingWidget() {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.background,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 150,
                height: 150,
                child: Lottie.asset(
                  'assets/animations/sync_loading.json',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_filterColor, _filterColor.withOpacity(0.7)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.sync_rounded,
                        size: 60,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'Loading your financial data...',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: _filterColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 200,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Stack(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 1000),
                      width: 200,
                      height: 4,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_filterColor, _filterColor.withOpacity(0.7)],
                        ),
                        borderRadius: BorderRadius.circular(2),
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

  /* ────────────────────── Bulk Categorization ───────────────────── */
  void _showBulkCategorization() {
    if (_uncategorizedTransactions.isEmpty) return;

    if (_settings.getBool('haptic_feedback', true)) {
      _settings.triggerHaptic(HapticFeedbackType.selection);
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7, // ✅ FIXED: Reduced initial size
        maxChildSize: 0.85,    // ✅ FIXED: Reduced max size
        minChildSize: 0.4,
        builder: (context, scrollController) => Container(
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
            mainAxisSize: MainAxisSize.min, // ✅ FIXED: Added mainAxisSize.min
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

              // Header with reduced padding
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 15), // ✅ FIXED: Reduced padding
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10), // ✅ FIXED: Reduced padding
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_filterColor, _filterColor.withOpacity(0.7)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.category_rounded,
                        color: Colors.white,
                        size: 18, // ✅ FIXED: Smaller icon
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min, // ✅ FIXED: Added mainAxisSize.min
                        children: [
                          Text(
                            'Categorize Transactions',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith( // ✅ FIXED: Smaller title
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_uncategorizedTransactions.length} items need categorization',
                            style: Theme.of(context).textTheme.bodySmall, // ✅ FIXED: Smaller subtitle
                          ),
                        ],
                      ),
                    ),
                    Material(
                      color: _filterColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10), // ✅ FIXED: Smaller radius
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: _autoCategorizePendingTransactions,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // ✅ FIXED: Reduced padding
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome_rounded, color: _filterColor, size: 14), // ✅ FIXED: Smaller icon
                              const SizedBox(width: 6),
                              Text(
                                'Auto',
                                style: TextStyle(
                                  color: _filterColor,
                                  fontSize: 12, // ✅ FIXED: Smaller font
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // List with proper constraints
              Expanded( // ✅ FIXED: Use Expanded instead of Flexible
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20), // ✅ FIXED: Reduced top padding
                  itemCount: _uncategorizedTransactions.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8), // ✅ FIXED: Reduced spacing
                  itemBuilder: (context, index) {
                    final transaction = _uncategorizedTransactions[index];
                    return _buildUncategorizedTransactionItem(transaction);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildUncategorizedTransactionItem(Transaction transaction) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallItem = constraints.maxWidth < 350;

        return Container(
          padding: EdgeInsets.all(isSmallItem ? 10 : 12), // ✅ FIXED: Reduced padding
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getTransactionColor(transaction).withOpacity(0.2),
              width: 1,
            ),
          ),
          child: IntrinsicHeight( // ✅ FIXED: Added IntrinsicHeight
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isSmallItem ? 6 : 8), // ✅ FIXED: Reduced padding
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_getTransactionColor(transaction), _getTransactionColor(transaction).withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(8), // ✅ FIXED: Smaller radius
                  ),
                  child: Icon(
                    transaction.type == TransactionType.debit
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    color: Colors.white,
                    size: isSmallItem ? 12 : 14, // ✅ FIXED: Smaller icon
                  ),
                ),
                SizedBox(width: isSmallItem ? 8 : 10), // ✅ FIXED: Reduced spacing
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min, // ✅ FIXED: Added mainAxisSize.min
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              transaction.merchant,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith( // ✅ FIXED: Smaller font
                                fontWeight: FontWeight.w600,
                                fontSize: isSmallItem ? 13 : 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_isDebitCard(transaction) || _isCreditCard(transaction)) ...[
                            const SizedBox(width: 6), // ✅ FIXED: Reduced spacing
                            _getCardImage(transaction),
                          ],
                        ],
                      ),
                      SizedBox(height: isSmallItem ? 2 : 4), // ✅ FIXED: Reduced spacing
                      Row(
                        children: [
                          Icon(
                            _getTransactionIcon(transaction),
                            size: 10, // ✅ FIXED: Smaller icon
                            color: _getTransactionColor(transaction),
                          ),
                          const SizedBox(width: 4),
                          Flexible( // ✅ FIXED: Wrap in Flexible
                            child: Text(
                              '₹${transaction.amount.toStringAsFixed(0)} • ${Helpers.formatDate(transaction.dateTime)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: isSmallItem ? 10 : 11, // ✅ FIXED: Smaller font
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: isSmallItem ? 6 : 8), // ✅ FIXED: Reduced spacing
                Material(
                  color: _getTransactionColor(transaction).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6), // ✅ FIXED: Smaller radius
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => _categorizeTransaction(transaction),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallItem ? 8 : 10, // ✅ FIXED: Reduced padding
                        vertical: isSmallItem ? 4 : 6,
                      ),
                      child: Text(
                        'Categorize',
                        style: TextStyle(
                          color: _getTransactionColor(transaction),
                          fontSize: isSmallItem ? 10 : 11, // ✅ FIXED: Smaller font
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _categorizeTransaction(Transaction transaction) {
    Navigator.pop(context);

    showDialog(
      context: context,
      builder: (context) => TransactionPopup(
        transaction: transaction,
        onSave: (categorizedTransaction) async {
          try {
            await _store.saveTransaction(categorizedTransaction);

            if (categorizedTransaction.categoryId.isNotEmpty) {
              await _categoryService.assignTransactionToCategory(
                categorizedTransaction.id,
                categorizedTransaction.categoryId,
              );
            }

            await _loadData(forceRefresh: true);
            print('✅ Transaction categorized successfully');
          } catch (e) {
            print('❌ Error categorizing transaction: $e');
          }
        },
      ),
    );
  }

  Future<void> _autoCategorizePendingTransactions() async {
    if (_uncategorizedTransactions.isEmpty) return;

    if (_settings.getBool('haptic_feedback', true)) {
      _settings.triggerHaptic(HapticFeedbackType.impact);
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                child: Lottie.asset(
                  'assets/animations/sync_loading.json',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(_filterColor),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Auto-categorizing transactions...',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

      int categorizedCount = 0;
      for (int i = 0; i < _uncategorizedTransactions.length && i < 10; i++) {
        final transaction = _uncategorizedTransactions[i];

        String categoryId = _predictCategoryFromMerchant(transaction.merchant);

        if (categoryId.isNotEmpty) {
          final updatedTransaction = Transaction(
            id: transaction.id,
            amount: transaction.amount,
            type: transaction.type,
            merchant: transaction.merchant,
            sender: transaction.sender,
            dateTime: transaction.dateTime,
            originalMessage: transaction.originalMessage,
            categoryId: categoryId,
            isCategorized: true,
            method: transaction.method,
            confidence: transaction.confidence,
            metadata: transaction.metadata,
          );

          await _store.saveTransaction(updatedTransaction);
          await _categoryService.assignTransactionToCategory(transaction.id, categoryId);
          categorizedCount++;
        }

        await Future.delayed(const Duration(milliseconds: 100));
      }

      if (mounted) Navigator.of(context).pop();

      await _loadData(forceRefresh: true);

      if (mounted) Navigator.of(context).pop();

      if (mounted && categorizedCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Auto-categorized $categorizedCount transactions!'),
                ),
              ],
            ),
            backgroundColor: AppTheme.vibrantGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        if (_settings.getBool('haptic_feedback', true)) {
          _settings.triggerHaptic(HapticFeedbackType.success);
        }
      }

    } catch (e) {
      if (mounted) Navigator.of(context).pop();

      print('❌ Error in auto categorization: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Auto categorization failed: ${e.toString()}'),
            backgroundColor: AppTheme.darkOrangeRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _predictCategoryFromMerchant(String merchant) {
    final merchantLower = merchant.toLowerCase();

    // Food & Dining
    if (merchantLower.contains('swiggy') ||
        merchantLower.contains('zomato') ||
        merchantLower.contains('restaurant') ||
        merchantLower.contains('cafe') ||
        merchantLower.contains('dominos') ||
        merchantLower.contains('kfc') ||
        merchantLower.contains('mcdonald') ||
        merchantLower.contains('pizza') ||
        merchantLower.contains('food') ||
        merchantLower.contains('dining')) {
      return 'food_dining';
    }

    // Transportation
    if (merchantLower.contains('uber') ||
        merchantLower.contains('ola') ||
        merchantLower.contains('metro') ||
        merchantLower.contains('petrol') ||
        merchantLower.contains('fuel') ||
        merchantLower.contains('bpcl') ||
        merchantLower.contains('iocl') ||
        merchantLower.contains('hpcl') ||
        merchantLower.contains('taxi') ||
        merchantLower.contains('rapido') ||
        merchantLower.contains('transport')) {
      return 'transportation';
    }

    // Shopping
    if (merchantLower.contains('amazon') ||
        merchantLower.contains('flipkart') ||
        merchantLower.contains('myntra') ||
        merchantLower.contains('nykaa') ||
        merchantLower.contains('mall') ||
        merchantLower.contains('store') ||
        merchantLower.contains('shopping') ||
        merchantLower.contains('mart') ||
        merchantLower.contains('retail')) {
      return 'shopping';
    }

    // Entertainment
    if (merchantLower.contains('netflix') ||
        merchantLower.contains('spotify') ||
        merchantLower.contains('youtube') ||
        merchantLower.contains('movie') ||
        merchantLower.contains('cinema') ||
        merchantLower.contains('pvr') ||
        merchantLower.contains('inox') ||
        merchantLower.contains('entertainment') ||
        merchantLower.contains('gaming')) {
      return 'entertainment';
    }

    // Utilities & Bills
    if (merchantLower.contains('electricity') ||
        merchantLower.contains('water') ||
        merchantLower.contains('gas') ||
        merchantLower.contains('internet') ||
        merchantLower.contains('mobile') ||
        merchantLower.contains('jio') ||
        merchantLower.contains('airtel') ||
        merchantLower.contains('vi') ||
        merchantLower.contains('bsnl') ||
        merchantLower.contains('bill') ||
        merchantLower.contains('recharge')) {
      return 'utilities';
    }

    // Healthcare
    if (merchantLower.contains('hospital') ||
        merchantLower.contains('pharmacy') ||
        merchantLower.contains('medical') ||
        merchantLower.contains('doctor') ||
        merchantLower.contains('apollo') ||
        merchantLower.contains('medplus') ||
        merchantLower.contains('health')) {
      return 'healthcare';
    }

    // Education
    if (merchantLower.contains('school') ||
        merchantLower.contains('college') ||
        merchantLower.contains('university') ||
        merchantLower.contains('course') ||
        merchantLower.contains('education') ||
        merchantLower.contains('tuition') ||
        merchantLower.contains('training')) {
      return 'education';
    }

    return '';
  }
}


