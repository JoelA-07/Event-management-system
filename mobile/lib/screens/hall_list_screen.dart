import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/hall_provider.dart';
import '../widgets/hall_card.dart';
import 'hall_detail_screen.dart';
import '../utils/theme.dart';

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
    // Fetch halls from backend as soon as the screen loads
    Future.microtask(() => context.read<HallProvider>().loadHalls());
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
        title: const Text("Explore Halls", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            // Attractive Search Bar
            TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: InputDecoration(
                hintText: "Search by name or location...",
                prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Hall List Logic
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