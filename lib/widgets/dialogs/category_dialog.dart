// lib/widgets/dialogs/category_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/category.dart';
import '../../theme/theme.dart';

class CategoryDialog extends StatefulWidget {
  final Category? category;
  final Function(Category) onSave;

  const CategoryDialog({
    super.key,
    this.category,
    required this.onSave,
  });

  @override
  State<CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedType = 'expense';
  IconData _selectedIcon = Icons.category_rounded;
  Color _selectedColor = const Color(0xFF2196F3);

  // Predefined colors for user selection
  final List<Color> _availableColors = [
    const Color(0xFFF44336), // Red
    const Color(0xFFE91E63), // Pink
    const Color(0xFF9C27B0), // Purple
    const Color(0xFF673AB7), // Deep Purple
    const Color(0xFF3F51B5), // Indigo
    const Color(0xFF2196F3), // Blue
    const Color(0xFF03A9F4), // Light Blue
    const Color(0xFF00BCD4), // Cyan
    const Color(0xFF009688), // Teal
    const Color(0xFF4CAF50), // Green
    const Color(0xFF8BC34A), // Light Green
    const Color(0xFFCDDC39), // Lime
    const Color(0xFFFFC107), // Amber
    const Color(0xFFFF9800), // Orange
    const Color(0xFFFF5722), // Deep Orange
    const Color(0xFF795548), // Brown
  ];

  // Predefined icons for user selection
  final List<IconData> _availableIcons = [
    Icons.restaurant_rounded,
    Icons.directions_car_rounded,
    Icons.shopping_bag_rounded,
    Icons.movie_rounded,
    Icons.receipt_rounded,
    Icons.health_and_safety_rounded,
    Icons.school_rounded,
    Icons.work_rounded,
    Icons.trending_up_rounded,
    Icons.home_rounded,
    Icons.fitness_center_rounded,
    Icons.flight_rounded,
    Icons.phone_rounded,
    Icons.computer_rounded,
    Icons.music_note_rounded,
    Icons.sports_soccer_rounded,
    Icons.local_cafe_rounded,
    Icons.local_gas_station_rounded,
    Icons.local_grocery_store_rounded,
    Icons.apartment_rounded,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _descriptionController.text = widget.category!.description;
      _selectedType = widget.category!.type;
      _selectedIcon = widget.category!.icon;
      _selectedColor = widget.category!.color;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveCategory() {
    if (_formKey.currentState!.validate()) {
      final category = Category(
        id: widget.category?.id ?? 'custom_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        icon: _selectedIcon,
        color: _selectedColor,
        isDefault: widget.category?.isDefault ?? false,
      );

      widget.onSave(category);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        decoration: BoxDecoration(
          color: AppTheme.cardDarkGray,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: _selectedColor.withOpacity(0.3),
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with preview
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _selectedColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: _selectedColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          _selectedIcon,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          widget.category == null ? 'Add Category' : 'Edit Category',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Name Field
                  TextFormField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Category Name',
                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _selectedColor),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a category name';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Description Field
                  TextFormField(
                    controller: _descriptionController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _selectedColor),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Type Selection
                  Text(
                    'Type',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTypeButton('income', 'Income', AppTheme.vibrantGreen),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTypeButton('expense', 'Expense', AppTheme.darkOrangeRed),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Color Selection
                  Text(
                    'Color',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableColors.map((color) => _buildColorButton(color)).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Icon Selection
                  Text(
                    'Icon',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _availableIcons.map((icon) => _buildIconButton(icon)).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveCategory,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            widget.category == null ? 'Add' : 'Save',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton(String type, String label, Color color) {
    final isSelected = _selectedType == type;

    return Container(
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(colors: [color, color.withOpacity(0.7)])
            : null,
        color: isSelected ? null : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? color : Colors.white.withOpacity(0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedType = type);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorButton(Color color) {
    final isSelected = _selectedColor == color;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedColor = color);
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : null,
      ),
    );
  }

  Widget _buildIconButton(IconData icon) {
    final isSelected = _selectedIcon == icon;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedIcon = icon);
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? _selectedColor : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? _selectedColor : Colors.white.withOpacity(0.2),
          ),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
          size: 20,
        ),
      ),
    );
  }
}
