// lib/widgets/charts/bar_chart_widget.dart (COMPLETE ENHANCED VERSION)
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/transaction.dart';
import '../../theme/theme.dart';
import '../../utils/helpers.dart';

class TransactionBarChart extends StatefulWidget {
  final List<Transaction> transactions;
  final String period;
  final double maxHeight;

  const TransactionBarChart({
    Key? key,
    required this.transactions,
    required this.period,
    this.maxHeight = 250,
  }) : super(key: key);

  @override
  State<TransactionBarChart> createState() => _TransactionBarChartState();
}

class _TransactionBarChartState extends State<TransactionBarChart> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  Map<String, double> _chartData = {};
  double _maxY = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _calculateChartData();
  }

  @override
  void didUpdateWidget(TransactionBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.transactions != oldWidget.transactions || widget.period != oldWidget.period) {
      _calculateChartData();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _animationController.forward();
  }

  void _calculateChartData() {
    _chartData.clear();

    final now = DateTime.now();
    final debitTransactions = widget.transactions
        .where((t) => t.type == TransactionType.debit)
        .toList();

    switch (widget.period) {
      case 'Today':
        _calculateHourlyData(debitTransactions, now);
        break;
      case 'This Week':
        _calculateDailyData(debitTransactions, 7);
        break;
      case 'This Month':
        _calculateDailyData(debitTransactions, 30);
        break;
      case 'Last 3 Months':
        _calculateWeeklyData(debitTransactions, now);
        break;
      case 'This Year':
        _calculateMonthlyData(debitTransactions, now);
        break;
      default:
        _calculateDailyData(debitTransactions, 7);
    }

    _maxY = _chartData.values.isEmpty
        ? 100
        : (_chartData.values.reduce((a, b) => a > b ? a : b) * 1.2);
  }

  void _calculateHourlyData(List<Transaction> transactions, DateTime now) {
    for (int hour = 0; hour < 24; hour += 4) {
      final key = '${hour.toString().padLeft(2, '0')}:00';
      _chartData[key] = 0;
    }

    for (final transaction in transactions) {
      if (transaction.dateTime.day == now.day &&
          transaction.dateTime.month == now.month &&
          transaction.dateTime.year == now.year) {
        final hour = (transaction.dateTime.hour ~/ 4) * 4;
        final key = '${hour.toString().padLeft(2, '0')}:00';
        _chartData[key] = (_chartData[key] ?? 0) + transaction.amount;
      }
    }
  }

  void _calculateDailyData(List<Transaction> transactions, int days) {
    final now = DateTime.now();

    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final key = '${date.day}/${date.month}';
      _chartData[key] = 0;
    }

    for (final transaction in transactions) {
      final key = '${transaction.dateTime.day}/${transaction.dateTime.month}';
      if (_chartData.containsKey(key)) {
        _chartData[key] = (_chartData[key] ?? 0) + transaction.amount;
      }
    }
  }

  void _calculateWeeklyData(List<Transaction> transactions, DateTime now) {
    for (int week = 11; week >= 0; week--) {
      final weekStart = now.subtract(Duration(days: week * 7));
      final key = 'W${12 - week}';
      _chartData[key] = 0;
    }

    for (final transaction in transactions) {
      final weeksDiff = now.difference(transaction.dateTime).inDays ~/ 7;
      if (weeksDiff <= 11) {
        final key = 'W${12 - weeksDiff}';
        _chartData[key] = (_chartData[key] ?? 0) + transaction.amount;
      }
    }
  }

  void _calculateMonthlyData(List<Transaction> transactions, DateTime now) {
    for (int month = 1; month <= 12; month++) {
      final key = _getMonthName(month);
      _chartData[key] = 0;
    }

    for (final transaction in transactions) {
      if (transaction.dateTime.year == now.year) {
        final key = _getMonthName(transaction.dateTime.month);
        _chartData[key] = (_chartData[key] ?? 0) + transaction.amount;
      }
    }
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  List<BarChartGroupData> _generateBarGroups() {
    final entries = _chartData.entries.toList();

    return entries.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final amount = data.value;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: amount,
            color: AppTheme.vibrantBlue,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                AppTheme.vibrantBlue.withOpacity(0.7),
                AppTheme.vibrantBlue,
              ],
            ),
          ),
        ],
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_chartData.isEmpty || _chartData.values.every((v) => v == 0)) {
      return _buildEmptyState();
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: BarChart(
            BarChartData(
              maxY: _maxY,
              minY: 0,
              barGroups: _generateBarGroups(),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  tooltipBgColor: Theme.of(context).colorScheme.surface,
                  tooltipRoundedRadius: 8,
                  tooltipPadding: const EdgeInsets.all(8),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final entries = _chartData.entries.toList();
                    if (groupIndex >= entries.length) return null;

                    final entry = entries[groupIndex];
                    return BarTooltipItem(
                      '${entry.key}\n${Helpers.formatCurrency(rod.toY)}',
                      TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (value, meta) {
                      final entries = _chartData.entries.toList();
                      if (value.toInt() >= entries.length) return const Text('');

                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          entries[value.toInt()].key,
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        Helpers.formatCurrency(value),
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: _maxY / 5,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    strokeWidth: 1,
                  );
                },
              ),
              borderData: FlBorderData(show: false),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.vibrantBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bar_chart_rounded,
              size: 48,
              color: AppTheme.vibrantBlue,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No trend data',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Make some transactions to see spending trends',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
