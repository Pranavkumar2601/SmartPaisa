// lib/models/category.dart (COMPLETE FILE)
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class Category {
  final String id;
  final String name;
  final String description;
  final String type;
  final IconData icon;
  final Color color;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSystem;
  final bool isDeleted;

  Category({
    String? id,
    required this.name,
    required this.description,
    required this.type,
    required this.icon,
    required this.color,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSystem = false,
    this.isDeleted = false,
  }) : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Category copyWith({
    String? id,
    String? name,
    String? description,
    String? type,
    IconData? icon,
    Color? color,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSystem,
    bool? isDeleted,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSystem: isSystem ?? this.isSystem,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type,
      'iconCodePoint': icon.codePoint,
      'color': color.value,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'isSystem': isSystem,
      'isDeleted': isDeleted,
    };
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      type: json['type'] ?? 'expense',
      icon: IconData(json['iconCodePoint'] ?? Icons.category.codePoint, fontFamily: 'MaterialIcons'),
      color: Color(json['color'] ?? Colors.blue.value),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt']),
      isSystem: json['isSystem'] ?? false,
      isDeleted: json['isDeleted'] ?? false,
    );
  }

  static List<Category> getDefaultCategories() {
    return [
      Category(
        id: 'food_dining',
        name: 'Food & Dining',
        description: 'Restaurants, cafes, food delivery',
        type: 'expense',
        icon: Icons.restaurant_rounded,
        color: Colors.orange,
        isSystem: true,
      ),
      Category(
        id: 'transportation',
        name: 'Transportation',
        description: 'Fuel, taxi, metro, bus',
        type: 'expense',
        icon: Icons.directions_car_rounded,
        color: Colors.blue,
        isSystem: true,
      ),
      Category(
        id: 'shopping',
        name: 'Shopping',
        description: 'Online shopping, retail stores',
        type: 'expense',
        icon: Icons.shopping_bag_rounded,
        color: Colors.purple,
        isSystem: true,
      ),
      Category(
        id: 'entertainment',
        name: 'Entertainment',
        description: 'Movies, streaming, games',
        type: 'expense',
        icon: Icons.movie_rounded,
        color: Colors.pink,
        isSystem: true,
      ),
      Category(
        id: 'utilities',
        name: 'Utilities',
        description: 'Electricity, water, gas, internet',
        type: 'expense',
        icon: Icons.electrical_services_rounded,
        color: Colors.teal,
        isSystem: true,
      ),
      Category(
        id: 'default_uncategorized',
        name: 'Uncategorized',
        description: 'Transactions not yet categorized',
        type: 'expense',
        icon: Icons.help_outline_rounded,
        color: Colors.grey,
        isSystem: true,
      ),
    ];
  }

  // Add this method to your existing Category class:
  Map<String, dynamic> toMap() => toJson();

  // Add this factory method
  factory Category.fromMap(Map<String, dynamic> map) => Category.fromJson(map);

  @override
  String toString() {
    return 'Category{id: $id, name: $name, type: $type}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
