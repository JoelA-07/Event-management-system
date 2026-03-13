import 'package:flutter/material.dart';

class EventTypeModel {
  final String key;
  final String title;
  final String imageUrl;
  final LinearGradient bannerGradient;
  final Color chipColor;
  final IconData icon;

  const EventTypeModel({
    required this.key,
    required this.title,
    required this.imageUrl,
    required this.bannerGradient,
    required this.chipColor,
    required this.icon,
  });
}
