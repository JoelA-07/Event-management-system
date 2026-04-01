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
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<HallProvider>().loadHalls();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final provider = context.read<HallProvider>();
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!provider.isLoadingMore && provider.hasMore) {
        provider.loadMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hallProvider = context.watch<HallProvider>();

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
                            controller: _scrollController,
                            itemCount: filteredHalls.length + (hallProvider.isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= filteredHalls.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              }
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
