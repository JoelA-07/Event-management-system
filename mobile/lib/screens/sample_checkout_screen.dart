import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart'; // Add this to pubspec.yaml for date formatting
import '../providers/sample_cart_provider.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';

class SampleCheckoutScreen extends StatefulWidget {
  const SampleCheckoutScreen({super.key});

  @override
  State<SampleCheckoutScreen> createState() => _SampleCheckoutScreenState();
}

class _SampleCheckoutScreenState extends State<SampleCheckoutScreen> {
  final TextEditingController _addressController = TextEditingController();
  DateTime? _selectedDate;
  bool _isProcessing = false;

  // Function to pick a delivery date for the samples
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 14)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _placeOrder() async {
    final cart = context.read<SampleCartProvider>();

    // 1. Validation
    if (_addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please provide a delivery address")),
      );
      return;
    }
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a tasting date")),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      const storage = FlutterSecureStorage();
      String? customerId = await storage.read(key: "userId");

      // 2. Prepare Data for Backend
      final response = await Dio().post(
        "${AppConstants.baseUrl}/vendors/order-sample",
        data: {
          "customerId": int.parse(customerId!),
          "deliveryAddress": _addressController.text.trim(),
          "tastingDate": DateFormat('yyyy-MM-dd').format(_selectedDate!),
          "items": cart.items.map((i) => {
            "menuId": i.menuId,
            "vendorId": i.vendorId,
            "packageName": i.name,
            "price": i.price,
          }).toList(),
        },
      );

      if (response.statusCode == 201) {
        // 3. Success Logic
        _showSuccessDialog();
        cart.clearCart();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error placing order. Please try again.")),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: const Text(
          "Tasting Session Booked!\nThe caterers will deliver the samples to your address on the selected date.",
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to dashboard
              },
              child: const Text("Done"),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<SampleCartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sample Tasting Cart"),
        centerTitle: true,
      ),
      body: cart.items.isEmpty
          ? const Center(child: Text("Your cart is empty"))
          : Column(
              children: [
                // LIST OF ITEMS
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(15),
                    itemCount: cart.items.length,
                    itemBuilder: (context, i) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const Icon(Icons.restaurant, color: AppTheme.primaryColor),
                        title: Text(cart.items[i].name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text("Sample Tasting Portion"),
                        trailing: Text("₹${cart.items[i].price}", style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                      ),
                    ),
                  ),
                ),

                // CHECKOUT DETAILS SECTION
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Delivery Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 15),
                      
                      // ADDRESS FIELD
                      TextField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: "Delivery Address",
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // DATE PICKER BUTTON
                      ListTile(
                        onTap: () => _selectDate(context),
                        tileColor: Colors.grey[100],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        leading: const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                        title: Text(_selectedDate == null 
                          ? "Select Delivery Date" 
                          : "Delivering on: ${DateFormat('dd MMM yyyy').format(_selectedDate!)}"),
                        trailing: const Icon(Icons.edit, size: 16),
                      ),

                      const SizedBox(height: 20),
                      
                      // TOTAL PRICE
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Total Amount", style: TextStyle(fontSize: 16)),
                          Text("₹${cart.totalPrice}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                        ],
                      ),
                      
                      const SizedBox(height: 20),

                      // FINAL BOOK BUTTON
                      _isProcessing
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: _placeOrder,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 55),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              ),
                              child: const Text("BOOK TASTING SESSION", style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                    ],
                  ),
                )
              ],
            ),
    );
  }
}