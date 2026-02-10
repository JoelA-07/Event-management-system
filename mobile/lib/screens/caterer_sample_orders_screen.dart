import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';

class CatererSampleOrdersScreen extends StatelessWidget {
  const CatererSampleOrdersScreen({super.key});

  Future<List<dynamic>> _fetchOrders() async {
    const storage = FlutterSecureStorage();
    String? vId = await storage.read(key: "userId");
    final res = await Dio().get("${AppConstants.baseUrl}/vendors/samples/$vId");
    return res.data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tasting Requests")),
      body: FutureBuilder<List<dynamic>>(
        future: _fetchOrders(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final orders = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: orders.length,
            itemBuilder: (context, i) {
              final order = orders[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.delivery_dining)),
                  title: Text("Date: ${order['tastingDate']}"),
                  subtitle: Text("Address: ${order['deliveryAddress']}"),
                  trailing: Chip(
                    label: Text(order['status'].toUpperCase()),
                    backgroundColor: Colors.orange.shade100,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}