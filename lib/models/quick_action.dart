import 'package:flutter/material.dart';

class QuickActionModel {
  final String id;
  final String title;
  final IconData icon;
  final String route;
  final Color color;

  QuickActionModel({
    required this.id,
    required this.title,
    required this.icon,
    required this.route,
    required this.color,
  });
}
