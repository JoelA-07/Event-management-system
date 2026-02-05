import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/theme.dart';
import '../../widgets/dashboard_header.dart';
import '../../providers/sample_cart_provider.dart';
import '../chatbot_screen.dart';
import '../my_booking_screen.dart';
import '../profile_screen.dart';
import '../hall_list_screen.dart';
import '../vendor_list_screen.dart';
import '../sample_checkout_screen.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});
  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      // 1. APP BAR WITH CART BADGE
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        title: const Text("Elite Events", 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
        actions: [
          Consumer<SampleCartProvider>(
            builder: (context, cart, child) {
              return Badge(
                label: Text(cart.items.length.toString()),
                isLabelVisible: cart.items.isNotEmpty,
                backgroundColor: AppTheme.accentColor,
                child: IconButton(
                  icon: const Icon(Icons.shopping_basket_outlined, color: Colors.white),
                  onPressed: () => Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (_) => const SampleCheckoutScreen())
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 15),
        ],
      ),
      
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            // 2. PERSONALIZED HEADER (Name & Subtitle)
            const DashboardHeader(subTitle: "FIND YOUR DREAM EVENT"),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  // 3. SEARCH BAR
                  _buildSearchBar(), 
                  const SizedBox(height: 30),
                  
                  // 4. CATEGORIES ROW
                  const Text("Explore Services", 
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  _buildCategoryRow(), 
                  
                  const SizedBox(height: 30),
                  
                  // 5. PROMO BANNER
                  _buildPromoBanner(),
                  
                  const SizedBox(height: 30),

                  // 6. FEATURED HALLS PREVIEW
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Featured Venues", 
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context, MaterialPageRoute(builder: (_) => const HallListScreen())),
                        child: const Text("See All"),
                      )
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildFeaturedHalls(),
                ],
              ),
            )
          ]
        ),
      ),

      // 7. AI CHATBOT FLOATING BUTTON
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.chat_bubble, color: Colors.white),
        onPressed: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const ChatbotScreen())),
      ),

      // 8. BOTTOM NAVIGATION BAR
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          if (index == 1) Navigator.push(context, MaterialPageRoute(builder: (_) => const MyBookingsScreen()));
          if (index == 3) Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Bookings'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: 'Saved'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  // SEARCH BAR WIDGET
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
      ),
      child: const Row(
        children: [
          Icon(Icons.search, color: AppTheme.primaryColor), 
          SizedBox(width: 10), 
          Text("Search halls, caterers...", style: TextStyle(color: Colors.grey))
        ]
      ),
    );
  }
  
  // CATEGORY ROW WIDGET (Halls, Photo, Catering, Design)
  Widget _buildCategoryRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _catItem(Icons.fort, "Halls", () => 
            Navigator.push(context, MaterialPageRoute(builder: (_) => const HallListScreen()))),
          _catItem(Icons.camera_alt, "Photo", () => 
            Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorListScreen(category: 'photographer')))),
          _catItem(Icons.restaurant, "Catering", () => 
            Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorListScreen(category: 'caterer')))),
          _catItem(Icons.edit_note, "Design", () => 
            Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorListScreen(category: 'designer')))),
        ],
      ),
    );
  }

  Widget _catItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(12), 
          border: Border.all(color: Colors.black12)
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.primaryColor), 
            const SizedBox(width: 8), 
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600))
          ]
        ),
      ),
    );
  }

  // PROMO BANNER WIDGET
  Widget _buildPromoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF6A1B9A), Color(0xFF8E24AA)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Wedding Bundle", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 5),
                Text("Get 20% off when you book Hall + Catering together.", 
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          Icon(Icons.auto_awesome, color: AppTheme.accentColor, size: 30),
        ],
      ),
    );
  }

  // FEATURED HALLS HORIZONTAL LIST
  Widget _buildFeaturedHalls() {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            width: 250,
            margin: const EdgeInsets.only(right: 15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: const DecorationImage(
                image: NetworkImage("https://images.unsplash.com/photo-1519167758481-83f550bb49b3?w=400"),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                ),
              ),
              padding: const EdgeInsets.all(15),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("The Grand Royale", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text("Chennai, Tamil Nadu", style: TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}