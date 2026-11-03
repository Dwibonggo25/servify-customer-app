import 'package:flutter/material.dart';

final class ServiceItem {
  const ServiceItem({
    required this.id,
    required this.name,
    required this.shortDescription,
    required this.description,
    required this.category,
    required this.price,
    required this.durationMinutes,
    required this.rating,
    required this.reviewCount,
    required this.icon,
    required this.color,
    required this.includes,
  });

  final String id;
  final String name;
  final String shortDescription;
  final String description;
  final String category;
  final int price;
  final int durationMinutes;
  final double rating;
  final int reviewCount;
  final IconData icon;
  final Color color;
  final List<String> includes;
}
