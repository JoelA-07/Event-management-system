import 'package:flutter/material.dart';
import 'package:mobile/features/halls/models/hall_model.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/core/constants.dart';

class HallCard extends StatelessWidget {
  final HallModel hall;
  final VoidCallback onTap;

  const HallCard({super.key, required this.hall, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10243C).withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Hero(
                tag: 'hall-img-${hall.id}',
                child: Image.network(
                  hall.imageUrl.startsWith('http')
                      ? hall.imageUrl
                      : "${AppConstants.baseUrl.replaceAll('/api', '')}${hall.imageUrl}",
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 180,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported, size: 50),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          hall.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        "Rs ${hall.pricePerDay.toStringAsFixed(0)}",
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: AppTheme.accentColor),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          hall.location,
                          style: TextStyle(color: Colors.blueGrey.shade600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.people, size: 16, color: AppTheme.accentColor),
                      const SizedBox(width: 5),
                      Text("${hall.capacity} Guests", style: TextStyle(color: Colors.blueGrey.shade600)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
