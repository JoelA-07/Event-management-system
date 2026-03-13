import 'package:flutter/material.dart';
import 'package:mobile/core/models/event_type_model.dart';

class EventTypes {
  static const List<EventTypeModel> all = [
    EventTypeModel(
      key: 'wedding',
      title: 'Wedding',
      imageUrl: 'https://images.unsplash.com/photo-1519741497674-611481863552?w=800',
      bannerGradient: LinearGradient(colors: [Color(0xFF7B1FA2), Color(0xFFAD1457)]),
      chipColor: Color(0xFFF3E5F5),
      icon: Icons.favorite,
    ),
    EventTypeModel(
      key: 'reception',
      title: 'Reception',
      imageUrl: 'https://images.unsplash.com/photo-1470337458703-46ad1756a187?w=800',
      bannerGradient: LinearGradient(colors: [Color(0xFF6A1B9A), Color(0xFFD81B60)]),
      chipColor: Color(0xFFFCE4EC),
      icon: Icons.celebration,
    ),
    EventTypeModel(
      key: 'birthday',
      title: 'Birthday',
      imageUrl: 'https://images.unsplash.com/photo-1530103043960-ef38714abb15?w=800',
      bannerGradient: LinearGradient(colors: [Color(0xFFE65100), Color(0xFFF57C00)]),
      chipColor: Color(0xFFFFF3E0),
      icon: Icons.cake,
    ),
    EventTypeModel(
      key: 'surprise',
      title: 'Surprise',
      imageUrl: 'https://images.unsplash.com/photo-1469371670807-013ccf25f16a?w=800',
      bannerGradient: LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF00838F)]),
      chipColor: Color(0xFFE1F5FE),
      icon: Icons.card_giftcard,
    ),
    EventTypeModel(
      key: 'outing',
      title: 'Outing',
      imageUrl: 'https://images.unsplash.com/photo-1526772662000-3f88f10405ff?w=800',
      bannerGradient: LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF00897B)]),
      chipColor: Color(0xFFE8F5E9),
      icon: Icons.landscape,
    ),
    EventTypeModel(
      key: 'funeral',
      title: 'Funeral',
      imageUrl: 'https://images.unsplash.com/photo-1524635962361-fb0b7e35f5b8?w=800',
      bannerGradient: LinearGradient(colors: [Color(0xFF37474F), Color(0xFF546E7A)]),
      chipColor: Color(0xFFECEFF1),
      icon: Icons.local_florist,
    ),
  ];
}
