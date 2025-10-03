import 'dart:io';

import 'package:flutter/material.dart';
import 'package:happy_weds_vendors/Screens/FAQs/Florists.dart';
import 'package:happy_weds_vendors/Screens/FAQs/Invites%20and%20Gifts.dart';
import 'package:happy_weds_vendors/Screens/FAQs/Makeup.dart';
import 'package:happy_weds_vendors/Screens/FAQs/Pandits.dart';
import 'package:happy_weds_vendors/Screens/profile_screen.dart';
import 'package:happy_weds_vendors/Screens/Project/project_page.dart';
import 'package:happy_weds_vendors/Screens/reviews.dart';
import 'package:happy_weds_vendors/Screens/stats.dart';
import 'package:happy_weds_vendors/Screens/view_plan_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'FAQs/Caterars.dart';
import 'FAQs/Music and dance.dart';
import 'FAQs/Photographer.dart';
import 'FAQs/Planning and decor.dart';
import 'FAQs/Venues.dart';
import 'answer_faq.dart';
import 'booking_screen.dart';
import 'drawer.dart';
import 'lead_screen.dart';
import 'link_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeTab(),
    const LeadsPage(),
    PortfolioPage(),
    const ReviewsPage(),
    const StatsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.pinkAccent,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Leads"),
          BottomNavigationBarItem(icon: Icon(Icons.pool_rounded), label: "Project"),
          BottomNavigationBarItem(icon: Icon(Icons.reviews_outlined), label: "Reviews"),
          BottomNavigationBarItem(icon: Icon(Icons.auto_graph), label: "Profile"),
        ],
      ),
    );
  }
}

// ---------------- Home Tab ----------------
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String _vendorTypeName = "";

  // Map vendor types to their FAQ screens
  final Map<String, Widget Function()> faqScreens = {
    "Photographers": () => const PhotographerFaqScreen(profileCompletion: 0.5),
    "venues": () => const VenuefaqScreen(profileCompletion: 0.5),
    "makeup": () => const MakeupFaqScreen(profileCompletion: 0.5),
    "planning and decor": () => DecorationAndPlanningfaq( profileCompletion: 0.5,),
    "caterers":  () => CaterarFaqScreen(profileCompletion: 0.5),
    "music and dance": () => MusicAndDanceFaq(profileCompletion: 0.5,),
    "invite and gift" : () => InviteAndGiftFaqScreen(profileCompletion: 0.5),
    "florists" : () => FloristsFaqScreen(profileCompletion: 0.5),
    "pandit": () => PanditFaqScreen(profileCompletion: 0.5),

  };

  @override
  void initState() {
    super.initState();
    _loadVendorType();
  }

  Future<void> _loadVendorType() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _vendorTypeName = prefs.getString('vendorTypeName') ?? "";
    });
    print("Logged in vendor type: $_vendorTypeName");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[300],
      appBar: AppBar(
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.pink[100],
        title: const Text("HappyWeds Business"),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      drawer: BusinessDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _profileCompletionCard(context, _vendorTypeName, faqScreens),
            _uploadAlbumCard(context),
            _getReviewsCard(context),
            _phoneUpdateCard(),
            _queriesCard(),
            _requestCallbackCard(),
            _membershipPlansCard(context),
          ],
        ),
      ),
    );
  }
}

// ---------------- Profile Completion Card ----------------
Widget _profileCompletionCard(BuildContext context, String vendorTypeName, Map<String, Widget Function()> faqScreens) {
  return _buildCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Complete your profile",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: 0.6,
          backgroundColor: Colors.grey[300],
          color: Colors.pinkAccent,
          minHeight: 6,
        ),
        const SizedBox(height: 12),
        _buildProfileTask(
          icon: Icons.question_answer_outlined,
          text: "Answer FAQs",
          onTap: () async {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            String vendorTypeName = prefs.getString('vendorTypeName') ?? "";
            vendorTypeName = vendorTypeName.trim().toLowerCase(); // <-- Add this line

            final faqScreens = {
              "photographers": () => const PhotographerFaqScreen(profileCompletion: 0.5),
              "venues": () => const VenuefaqScreen(profileCompletion: 0.5),
              "makeup": () => const MakeupFaqScreen(profileCompletion: 0.5),
              "planning and decor": () => DecorationAndPlanningfaq( profileCompletion: 0.5,),
              "caterers": () => CaterarFaqScreen(profileCompletion: 0.5),
              "music and dance": () => MusicAndDanceFaq(profileCompletion: 0.5),
              "invite and gift": () => InviteAndGiftFaqScreen(profileCompletion: 0.5),
              "florits": () => FloristsFaqScreen(profileCompletion: 0.5,),
              "pandits": () => PanditFaqScreen(profileCompletion: 0.5,),

            };

            final screenBuilder = faqScreens[vendorTypeName];

            if (screenBuilder != null) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => screenBuilder()),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("No FAQ screen available for your vendor type")),
              );
            }
          },
        ),

        _buildProfileTask(
          icon: Icons.link,
          text: "Link Facebook Page / Website",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LinkPageScreen()),
            );
          },
        ),
        _buildProfileTask(
          icon: Icons.photo_library_outlined,
          text: "Add Images to Portfolio",
          onTap: () {},
        ),
        _buildProfileTask(
          icon: Icons.reviews_outlined,
          text: "Get Clients to Review You",
          onTap: () {},
        ),
      ],
    ),
  );
}

Widget _buildProfileTask({
  required IconData icon,
  required String text,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.pinkAccent, size: 22),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
          const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
        ],
      ),
    ),
  );
}

// ---------------- Other Cards ----------------
Widget _uploadAlbumCard(BuildContext context) {
  return _buildCard(
    child: Row(
      children: [
        const Icon(Icons.photo_album, color: Colors.pinkAccent, size: 40),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            "Upload your work album to attract more clients",
            style: TextStyle(fontSize: 14),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UploadAlbumPage()),
            );
          },
          child: const Text("Upload"),
        ),
      ],
    ),
  );
}

Widget _getReviewsCard(BuildContext context) {
  return _buildCard(
    child: Row(
      children: [
        const Icon(Icons.star, color: Colors.orange, size: 40),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            "Get more reviews to boost your profile ranking",
            style: TextStyle(fontSize: 14),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GetNowPage()),
            );
          },
          child: const Text("Get Now"),
        ),
      ],
    ),
  );
}

Widget _phoneUpdateCard() {
  final controller = TextEditingController();
  return _buildCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Enter Number to Get Updates",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: "Enter phone number",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pinkAccent,
            minimumSize: const Size.fromHeight(40),
          ),
          onPressed: () {},
          child: const Text(
            "Submit",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    ),
  );
}

Widget _queriesCard() {
  return _buildCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Queries",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const Divider(),
        const ListTile(
          leading: CircleAvatar(child: Text("R")),
          title: Text("Riya Sharma"),
          subtitle: Text("Interested in Wedding Planning"),
          trailing: Text("2h ago"),
        ),
        const ListTile(
          leading: CircleAvatar(child: Text("A")),
          title: Text("Amit Patel"),
          subtitle: Text("Wedding Planner Booking Enquiry"),
          trailing: Text("5h ago"),
        ),
      ],
    ),
  );
}

Widget _requestCallbackCard() {
  return _buildCard(
    color: Colors.pinkAccent,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        Text(
          "Need help? Request a call back",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        Icon(Icons.phone, color: Colors.white),
      ],
    ),
  );
}

Widget _membershipPlansCard(BuildContext context) {
  return _buildCard(
    child: Row(
      children: [
        const Icon(Icons.card_membership, color: Colors.green, size: 40),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            "Upgrade to Premium Membership to get more leads & visibility",
            style: TextStyle(fontSize: 14),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ViewPlansScreen()),
            );
          },
          child: const Text("View Plans"),
        ),
      ],
    ),
  );
}

// ---------------- Generic Card ----------------
Widget _buildCard({required Widget child, Color? color}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(12),
    ),
    child: child,
  );
}

// ---------------- GetNowPage ----------------
class GetNowPage extends StatelessWidget {
  const GetNowPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Get Reviews"),
        backgroundColor: Colors.pinkAccent[100],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Boost Your Profile Ranking!",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.pinkAccent,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Getting more reviews helps improve your credibility and attracts more clients.\n\n"
                  "You can:\n"
                  "• Share your review link on social media\n"
                  "• Send direct invites to your customers\n"
                  "• Track your review progress",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () {},
              child: const Center(
                child: Text(
                  "Start Now",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- Upload Album Page ----------------
class UploadAlbumPage extends StatefulWidget {
  const UploadAlbumPage({super.key});

  @override
  State<UploadAlbumPage> createState() => _UploadAlbumPageState();
}

class _UploadAlbumPageState extends State<UploadAlbumPage> {
  final List<XFile> _selectedImages = [];

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pink[300],
        title: const Text("Upload Album"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add_photo_alternate, color: Colors.white),
              label: const Text("Select Photos", style: TextStyle(color: Colors.white)),
              onPressed: _pickImages,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _selectedImages.isEmpty
                  ? const Center(child: Text("No photos selected"))
                  : GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) {
                  return Image.file(
                    File(_selectedImages[index].path),
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            if (_selectedImages.isNotEmpty)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  // TODO: Upload logic here
                },
                child: const Text("Upload Album", style: TextStyle(color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }
}
