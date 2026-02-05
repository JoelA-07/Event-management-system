import 'package:flutter/material.dart';
import '../models/hall_model.dart';
import '../utils/theme.dart';

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
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hall Image with Hero Animation
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Hero(
                tag: 'hall-img-${hall.id}',
              child: Image.network(
              // If the URL starts with 'http', it's an old placeholder, use it directly.
              // If it starts with '/uploads', it's a real file, so add your Laptop's IP.
              hall.imageUrl.startsWith('http') 
                  ? hall.imageUrl 
                  : "http://192.168.1.5:5000${hall.imageUrl}", // <--- USE YOUR ACTUAL LAPTOP IP HERE
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
                      Text(
                        hall.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "₹${hall.pricePerDay}",
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: AppTheme.accentColor),
                      const SizedBox(width: 5),
                      Text(hall.location, style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(width: 15),
                      const Icon(Icons.people, size: 16, color: AppTheme.accentColor),
                      const SizedBox(width: 5),
                      Text("${hall.capacity} Guests", style: TextStyle(color: Colors.grey[600])),
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