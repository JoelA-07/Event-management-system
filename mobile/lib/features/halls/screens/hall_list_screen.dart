import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile/features/halls/providers/hall_provider.dart';
import 'package:mobile/core/widgets/hall_card.dart';
import 'package:mobile/features/halls/screens/hall_detail_screen.dart';
import 'package:mobile/core/theme.dart';

class HallListScreen extends StatefulWidget {
  const HallListScreen({super.key});

  @override
  State<HallListScreen> createState() => _HallListScreenState();
}

class _HallListScreenState extends State<HallListScreen> {
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<HallProvider>().loadHalls();
    });
  }

  @override
  Widget build(BuildContext context) {
    final hallProvider = context.watch<HallProvider>();

    // Filtering logic for the search bar
    final filteredHalls = hallProvider.halls.where((hall) {
      return hall.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
             hall.location.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Explore Venues", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Column(
          children: [
            TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: const InputDecoration(
                hintText: "Search by name or location...",
                prefixIcon: Icon(Icons.travel_explore),
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: hallProvider.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                  : filteredHalls.isEmpty
                      ? const Center(child: Text("No halls found matching your search."))
                      : RefreshIndicator(
                          onRefresh: () => hallProvider.loadHalls(),
                          child: ListView.builder(
                            itemCount: filteredHalls.length,
                            itemBuilder: (context, index) {
                              return HallCard(
                                hall: filteredHalls[index],
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => HallDetailScreen(hall: filteredHalls[index]),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
