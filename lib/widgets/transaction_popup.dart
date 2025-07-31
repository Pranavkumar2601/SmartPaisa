// lib/widgets/transaction_popup.dart (COMPLETE ENHANCED VERSION - OVERFLOW FIXED)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/bank_transaction_method.dart';
import '../services/category_service.dart';
import '../services/settings_service.dart';
import '../models/haptic_feedback_type.dart';
import '../theme/theme.dart';
import '../utils/helpers.dart';

class TransactionPopup extends StatefulWidget {
  final Transaction transaction;
  final Function(Transaction) onSave;

  const TransactionPopup({
    Key? key,
    required this.transaction,
    required this.onSave,
  }) : super(key: key);

  @override
  State<TransactionPopup> createState() => _TransactionPopupState();
}

class _TransactionPopupState extends State<TransactionPopup> with TickerProviderStateMixin {
  final _categoryService = CategoryService.instance;
  final _settings = SettingsService.instance;

  late TextEditingController _merchantController;
  late TextEditingController _amountController;
  late TextEditingController _notesController;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  List<Category> _categories = [];
  String _selectedCategoryId = '';
  TransactionType _selectedType = TransactionType.debit;
  BankTransactionMethod? _selectedMethod;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeAnimations();
    _loadCategories();
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    _merchantController = TextEditingController(text: widget.transaction.merchant);
    _amountController = TextEditingController(text: widget.transaction.amount.toString());
    _notesController = TextEditingController();

    _selectedCategoryId = widget.transaction.categoryId;
    _selectedType = widget.transaction.type;
    _selectedMethod = widget.transaction.method;
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
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
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);

    try {
      final categories = await _categoryService.getCategories();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading categories: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveTransaction() async {
    if (_isSaving) return;

    // Validate inputs
    if (_merchantController.text.trim().isEmpty) {
      _showError('Please enter a merchant name');
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showError('Please enter a valid amount');
      return;
    }

    if (_selectedCategoryId.isEmpty) {
      _showError('Please select a category');
      return;
    }

    setState(() => _isSaving = true);

    // Trigger haptic feedback
    if (_settings.getBool('haptic_feedback', true)) {
      _settings.triggerHaptic(HapticFeedbackType.impact);
    }

    try {
      final updatedTransaction = widget.transaction.copyWith(
        merchant: _merchantController.text.trim(),
        amount: amount,
        type: _selectedType,
        categoryId: _selectedCategoryId,
        isCategorized: true,
        method: _selectedMethod,
        metadata: {
          'edited_at': DateTime.now().toIso8601String(),
          'notes': _notesController.text.trim(),
        },
      );

      await Future.delayed(const Duration(milliseconds: 500)); // Visual feedback delay

      widget.onSave(updatedTransaction);

      // Success haptic feedback
      if (_settings.getBool('haptic_feedback', true)) {
        _settings.triggerHaptic(HapticFeedbackType.success);
      }

      if (mounted) Navigator.of(context).pop();

    } catch (e) {
      print('❌ Error saving transaction: $e');
      _showError('Failed to save transaction: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.darkOrangeRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    // Error haptic feedback
    if (_settings.getBool('haptic_feedback', true)) {
      _settings.triggerHaptic(HapticFeedbackType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenWidth > 600 ? 40 : 20, // ✅ FIXED: Responsive padding
        vertical: screenHeight > 700 ? 40 : 20,
      ),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: ConstrainedBox( // ✅ FIXED: Add ConstrainedBox
            constraints: BoxConstraints(
              maxHeight: screenHeight * 0.85, // ✅ FIXED: Limit to 85% of screen height
              maxWidth: screenWidth > 600 ? 500 : screenWidth * 0.9, // ✅ FIXED: Responsive width
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min, // ✅ FIXED: Important for preventing overflow
                children: [
                  _buildHeader(),
                  Flexible( // ✅ FIXED: Use Flexible instead of direct content
                    child: _buildContent(),
                  ),
                  _buildActions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 20), // ✅ FIXED: Reduced padding
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _selectedType == TransactionType.debit
                ? AppTheme.darkOrangeRed
                : AppTheme.vibrantGreen,
            _selectedType == TransactionType.debit
                ? AppTheme.darkOrangeRed.withOpacity(0.8)
                : AppTheme.vibrantGreen.withOpacity(0.8),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10), // ✅ FIXED: Reduced padding
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10), // ✅ FIXED: Smaller radius
            ),
            child: Icon(
              _selectedType == TransactionType.debit
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              color: Colors.white,
              size: 20, // ✅ FIXED: Smaller icon
            ),
          ),
          const SizedBox(width: 12), // ✅ FIXED: Reduced spacing
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // ✅ FIXED: Add mainAxisSize.min
              children: [
                Text(
                  'Edit Transaction',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: MediaQuery.of(context).size.width < 350 ? 16 : 18, // ✅ FIXED: Responsive font
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2), // ✅ FIXED: Reduced spacing
                Text(
                  Helpers.formatDate(widget.transaction.dateTime),
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: MediaQuery.of(context).size.width < 350 ? 12 : 14, // ✅ FIXED: Responsive font
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20), // ✅ FIXED: Smaller icon
            padding: EdgeInsets.zero, // ✅ FIXED: Remove padding
            constraints: const BoxConstraints(), // ✅ FIXED: Remove constraints
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.vibrantBlue),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading categories...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView( // ✅ FIXED: Make content scrollable
      padding: const EdgeInsets.all(20), // ✅ FIXED: Reduced padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // ✅ FIXED: Add mainAxisSize.min
        children: [
          _buildTransactionTypeSelector(),
          const SizedBox(height: 16), // ✅ FIXED: Reduced spacing
          _buildMerchantField(),
          const SizedBox(height: 16),
          _buildAmountField(),
          const SizedBox(height: 16),
          _buildCategorySelector(),
          const SizedBox(height: 16),
          _buildMethodSelector(),
          const SizedBox(height: 16),
          _buildNotesField(),
        ],
      ),
    );
  }

  Widget _buildTransactionTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // ✅ FIXED: Add mainAxisSize.min
      children: [
        Text(
          'Transaction Type',
          style: Theme.of(context).textTheme.titleSmall?.copyWith( // ✅ FIXED: Smaller title
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildTypeOption(
                'Expense',
                TransactionType.debit,
                Icons.arrow_upward_rounded,
                AppTheme.darkOrangeRed,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTypeOption(
                'Income',
                TransactionType.credit,
                Icons.arrow_downward_rounded,
                AppTheme.vibrantGreen,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeOption(String label, TransactionType type, IconData icon, Color color) {
    final isSelected = _selectedType == type;

    return GestureDetector(
      onTap: () {
        if (_settings.getBool('haptic_feedback', true)) {
          _settings.triggerHaptic(HapticFeedbackType.selection);
        }
        setState(() => _selectedType = type);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12), // ✅ FIXED: Reduced padding
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10), // ✅ FIXED: Smaller radius
          border: Border.all(
            color: isSelected ? color : Theme.of(context).colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // ✅ FIXED: Add mainAxisSize.min
          children: [
            Icon(
              icon,
              color: isSelected ? color : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              size: 18, // ✅ FIXED: Smaller icon
            ),
            const SizedBox(width: 6), // ✅ FIXED: Reduced spacing
            Flexible( // ✅ FIXED: Wrap text in Flexible
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 14, // ✅ FIXED: Smaller font
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMerchantField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // ✅ FIXED: Add mainAxisSize.min
      children: [
        Text(
          'Merchant',
          style: Theme.of(context).textTheme.titleSmall?.copyWith( // ✅ FIXED: Smaller title
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _merchantController,
          decoration: InputDecoration(
            hintText: 'Enter merchant name',
            prefixIcon: const Icon(Icons.store_rounded, size: 20), // ✅ FIXED: Smaller icon
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10), // ✅ FIXED: Smaller radius
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), // ✅ FIXED: Reduced padding
          ),
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(fontSize: 14), // ✅ FIXED: Smaller font
        ),
      ],
    );
  }

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // ✅ FIXED: Add mainAxisSize.min
      children: [
        Text(
          'Amount',
          style: Theme.of(context).textTheme.titleSmall?.copyWith( // ✅ FIXED: Smaller title
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _amountController,
          decoration: InputDecoration(
            hintText: 'Enter amount',
            prefixIcon: const Icon(Icons.currency_rupee_rounded, size: 20), // ✅ FIXED: Smaller icon
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10), // ✅ FIXED: Smaller radius
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), // ✅ FIXED: Reduced padding
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          style: const TextStyle(fontSize: 14), // ✅ FIXED: Smaller font
        ),
        const SizedBox(height: 4),
        Text(
          'Original Amount: ₹${widget.transaction.amount.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
            fontSize: 12, // ✅ FIXED: Smaller font
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // ✅ FIXED: Add mainAxisSize.min
      children: [
        Text(
          'Category',
          style: Theme.of(context).textTheme.titleSmall?.copyWith( // ✅ FIXED: Smaller title
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), // ✅ FIXED: Reduced padding
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            borderRadius: BorderRadius.circular(10), // ✅ FIXED: Smaller radius
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategoryId.isEmpty ? null : _selectedCategoryId,
              hint: const Text('Select a category', style: TextStyle(fontSize: 14)), // ✅ FIXED: Smaller font
              isExpanded: true,
              items: _categories.map((category) {
                return DropdownMenuItem<String>(
                  value: category.id,
                  child: Row(
                    mainAxisSize: MainAxisSize.min, // ✅ FIXED: Add mainAxisSize.min
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6), // ✅ FIXED: Reduced padding
                        decoration: BoxDecoration(
                          color: category.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6), // ✅ FIXED: Smaller radius
                        ),
                        child: Icon(
                          category.icon,
                          color: category.color,
                          size: 16, // ✅ FIXED: Smaller icon
                        ),
                      ),
                      const SizedBox(width: 10), // ✅ FIXED: Reduced spacing
                      Expanded(
                        child: Text(
                          category.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14, // ✅ FIXED: Smaller font
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (_settings.getBool('haptic_feedback', true)) {
                  _settings.triggerHaptic(HapticFeedbackType.selection);
                }
                setState(() => _selectedCategoryId = value ?? '');
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMethodSelector() {
    final methods = BankTransactionMethod.values;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // ✅ FIXED: Add mainAxisSize.min
      children: [
        Text(
          'Payment Method',
          style: Theme.of(context).textTheme.titleSmall?.copyWith( // ✅ FIXED: Smaller title
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6, // ✅ FIXED: Reduced spacing
          runSpacing: 6,
          children: methods.map((method) {
            final isSelected = _selectedMethod == method;

            return GestureDetector(
              onTap: () {
                if (_settings.getBool('haptic_feedback', true)) {
                  _settings.triggerHaptic(HapticFeedbackType.selection);
                }
                setState(() {
                  _selectedMethod = _selectedMethod == method ? null : method;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), // ✅ FIXED: Reduced padding
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.vibrantBlue.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6), // ✅ FIXED: Smaller radius
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.vibrantBlue
                        : Theme.of(context).colorScheme.outline,
                  ),
                ),
                child: Text(
                  method.displayName,
                  style: TextStyle(
                    color: isSelected
                        ? AppTheme.vibrantBlue
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 11, // ✅ FIXED: Smaller font
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // ✅ FIXED: Add mainAxisSize.min
      children: [
        Text(
          'Notes (Optional)',
          style: Theme.of(context).textTheme.titleSmall?.copyWith( // ✅ FIXED: Smaller title
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _notesController,
          decoration: InputDecoration(
            hintText: 'Add notes about this transaction',
            prefixIcon: const Icon(Icons.note_rounded, size: 20), // ✅ FIXED: Smaller icon
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10), // ✅ FIXED: Smaller radius
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), // ✅ FIXED: Reduced padding
          ),
          maxLines: 2, // ✅ FIXED: Reduced lines
          textCapitalization: TextCapitalization.sentences,
          style: const TextStyle(fontSize: 14), // ✅ FIXED: Smaller font
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20), // ✅ FIXED: Reduced padding
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background.withOpacity(0.5),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12), // ✅ FIXED: Reduced padding
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10), // ✅ FIXED: Smaller radius
                ),
              ),
              child: const Text('Cancel', style: TextStyle(fontSize: 14)), // ✅ FIXED: Smaller font
            ),
          ),
          const SizedBox(width: 12), // ✅ FIXED: Reduced spacing
          Expanded(
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveTransaction,
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedType == TransactionType.debit
                    ? AppTheme.darkOrangeRed
                    : AppTheme.vibrantGreen,
                padding: const EdgeInsets.symmetric(vertical: 12), // ✅ FIXED: Reduced padding
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10), // ✅ FIXED: Smaller radius
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                width: 16, // ✅ FIXED: Smaller loading indicator
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Text(
                'Save Changes',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14, // ✅ FIXED: Smaller font
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ FIXED: Add extension for BankTransactionMethod if not exists

