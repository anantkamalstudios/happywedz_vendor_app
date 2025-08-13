// import 'package:flutter/material.dart';
//
// class HomeScreen extends StatelessWidget {
//   const HomeScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(
//         backgroundColor: Colors.pinkAccent,
//         elevation: 0,
//         title: const Text(
//           "WedMeGood Business",
//           style: TextStyle(color: Colors.white),
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.notifications, color: Colors.white),
//             onPressed: () {},
//           ),
//           Padding(
//             padding: const EdgeInsets.only(right: 12),
//             child: CircleAvatar(
//               backgroundImage: AssetImage("assets/profile.jpg"),
//             ),
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Summary cards
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 _buildSummaryCard("Leads", "12", Icons.people, Colors.orange),
//                 _buildSummaryCard("Bookings", "5", Icons.event, Colors.green),
//                 _buildSummaryCard("Reviews", "20", Icons.star, Colors.blue),
//               ],
//             ),
//             const SizedBox(height: 20),
//
//             // New Leads section
//             const Text(
//               "New Leads",
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 12),
//             _buildLeadCard("Riya Sharma", "Wedding Photography", "2 hrs ago"),
//             _buildLeadCard("Amit Patel", "Venue Booking", "5 hrs ago"),
//             const SizedBox(height: 20),
//
//             // Analytics section
//             const Text(
//               "Analytics",
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 12),
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: const [
//                   _AnalyticsItem(label: "Profile Views", value: "1.2k"),
//                   _AnalyticsItem(label: "Enquiries", value: "350"),
//                   _AnalyticsItem(label: "Bookings", value: "75"),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         selectedItemColor: Colors.pinkAccent,
//         unselectedItemColor: Colors.grey,
//         items: const [
//           BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
//           BottomNavigationBarItem(icon: Icon(Icons.people), label: "Leads"),
//           BottomNavigationBarItem(icon: Icon(Icons.event), label: "Bookings"),
//           BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildSummaryCard(
//       String title, String value, IconData icon, Color color) {
//     return Expanded(
//       child: Container(
//         margin: const EdgeInsets.symmetric(horizontal: 4),
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Column(
//           children: [
//             Icon(icon, color: color, size: 30),
//             const SizedBox(height: 8),
//             Text(value,
//                 style:
//                 const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 4),
//             Text(title, style: TextStyle(color: Colors.grey[600])),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildLeadCard(String name, String service, String time) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Row(
//         children: [
//           CircleAvatar(
//             backgroundColor: Colors.pinkAccent,
//             child: Text(name[0], style: const TextStyle(color: Colors.white)),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
//                 Text(service, style: TextStyle(color: Colors.grey[600])),
//               ],
//             ),
//           ),
//           Text(time, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
//         ],
//       ),
//     );
//   }
// }
//
// class _AnalyticsItem extends StatelessWidget {
//   final String label;
//   final String value;
//   const _AnalyticsItem({required this.label, required this.value});
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Text(value,
//             style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//         const SizedBox(height: 4),
//         Text(label, style: TextStyle(color: Colors.grey[600])),
//       ],
//     );
//   }
// }

//
//
// import 'package:flutter/material.dart';
// import 'package:happy_weds_vendors/Screens/view_plan_screen.dart';
//
// import 'lead_screen.dart';
//
// class HomeFullScreen extends StatefulWidget {
//   const HomeFullScreen({super.key});
//
//   @override
//   State<HomeFullScreen> createState() => _HomeFullScreenState();
// }
//
// class _HomeFullScreenState extends State<HomeFullScreen> {
//   int _selectedIndex = 0;
//
//   final List<Widget> _pages = [
//     // const HomeTab(),
//     const LeadsScreen(),
//     // const BookingsScreen(),
//     // const ProfileScreen(),
//   ];
//
//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//   }
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(
//         backgroundColor: Colors.pinkAccent[200],
//         title: const Text("WedMeGood Business"),
//         actions: [
//           IconButton(
//               icon: const Icon(Icons.notifications, color: Colors.white),
//               onPressed: () {}),
//           Padding(
//             padding: const EdgeInsets.only(right: 12),
//             child: CircleAvatar(
//               backgroundImage: AssetImage("assets/profile.jpg"),
//             ),
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             _profileCompletionCard(context),
//             _uploadAlbumCard(),
//             _getReviewsCard(),
//             _phoneUpdateCard(),
//             _queriesCard(),
//             _requestCallbackCard(),
//             _membershipPlansCard(context),
//           ],
//         ),
//       ),
//
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _selectedIndex,
//         onTap: _onItemTapped,
//         selectedItemColor: Colors.pinkAccent,
//         unselectedItemColor: Colors.grey,
//         items: const [
//           BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
//           BottomNavigationBarItem(icon: Icon(Icons.people), label: "Leads"),
//           BottomNavigationBarItem(icon: Icon(Icons.event), label: "Bookings"),
//           BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
//         ],
//       ),
//     );
//   }
//
//   Widget _profileCompletionCard(BuildContext context) {
//     return _buildCard(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             "Complete your profile",
//             style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//           ),
//           const SizedBox(height: 8),
//           LinearProgressIndicator(
//             value: 0.6, // Example progress (60%)
//             backgroundColor: Colors.grey[300],
//             color: Colors.pinkAccent,
//             minHeight: 6,
//           ),
//           const SizedBox(height: 12),
//
//           // List of actions
//           _buildProfileTask(
//             icon: Icons.question_answer_outlined,
//             text: "Answer FAQs",
//             onTap: () {
//               // TODO: Navigate to FAQs screen
//             },
//           ),
//           _buildProfileTask(
//             icon: Icons.link,
//             text: "Link Facebook Page / Website",
//             onTap: () {
//               // TODO: Navigate to link page screen
//             },
//           ),
//           _buildProfileTask(
//             icon: Icons.photo_library_outlined,
//             text: "Add Images to Portfolio",
//             onTap: () {
//               // TODO: Navigate to portfolio upload screen
//             },
//           ),
//           _buildProfileTask(
//             icon: Icons.reviews_outlined,
//             text: "Get Clients to Review You",
//             onTap: () {
//               // TODO: Navigate to reviews request screen
//             },
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildProfileTask({
//     required IconData icon,
//     required String text,
//     required VoidCallback onTap,
//   }) {
//     return InkWell(
//       onTap: onTap,
//       child: Padding(
//         padding: const EdgeInsets.symmetric(vertical: 6),
//         child: Row(
//           children: [
//             Icon(icon, color: Colors.pinkAccent, size: 22),
//             const SizedBox(width: 10),
//             Expanded(
//               child: Text(
//                 text,
//                 style: const TextStyle(fontSize: 14),
//               ),
//             ),
//             const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _uploadAlbumCard() {
//     return _buildCard(
//       child: Row(
//         children: [
//           const Icon(Icons.photo_album, color: Colors.pinkAccent, size: 40),
//           const SizedBox(width: 12),
//           Expanded(
//             child: const Text("Upload your work album to attract more clients",
//                 style: TextStyle(fontSize: 14)),
//           ),
//           TextButton(
//             onPressed: () {},
//             child: const Text("Upload"),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _getReviewsCard() {
//     return _buildCard(
//       child: Row(
//         children: [
//           const Icon(Icons.star, color: Colors.orange, size: 40),
//           const SizedBox(width: 12),
//           Expanded(
//             child: const Text("Get more reviews to boost your profile ranking",
//                 style: TextStyle(fontSize: 14)),
//           ),
//           TextButton(
//             onPressed: () {},
//             child: const Text("Get Now"),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _phoneUpdateCard() {
//     final controller = TextEditingController();
//     return _buildCard(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text("Enter Number to Get Updates",
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//           const SizedBox(height: 8),
//           TextField(
//             controller: controller,
//             keyboardType: TextInputType.phone,
//             decoration: InputDecoration(
//               hintText: "Enter phone number",
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               contentPadding: const EdgeInsets.symmetric(horizontal: 12),
//             ),
//           ),
//           const SizedBox(height: 8),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.pinkAccent, minimumSize: Size.fromHeight(40)),
//             onPressed: () {},
//             child: const Text("Submit"),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _queriesCard() {
//     return _buildCard(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text("Queries",
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//           const Divider(),
//           ListTile(
//             leading: const CircleAvatar(child: Text("R")),
//             title: const Text("Riya Sharma"),
//             subtitle: const Text("Interested in Wedding Photography"),
//             trailing: const Text("2h ago"),
//           ),
//           ListTile(
//             leading: const CircleAvatar(child: Text("A")),
//             title: const Text("Amit Patel"),
//             subtitle: const Text("Venue Booking Enquiry"),
//             trailing: const Text("5h ago"),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _requestCallbackCard() {
//     return _buildCard(
//       color: Colors.pinkAccent,
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: const [
//           Text("Need help? Request a call back",
//               style: TextStyle(color: Colors.white, fontSize: 16)),
//           Icon(Icons.phone, color: Colors.white),
//         ],
//       ),
//     );
//   }
//
//   Widget _membershipPlansCard(BuildContext context) {
//     return _buildCard(
//       child: Row(
//         children: [
//           const Icon(Icons.card_membership, color: Colors.green, size: 40),
//           const SizedBox(width: 12),
//           Expanded(
//             child:  Text(
//                 "Upgrade to Premium Membership to get more leads & visibility",
//                 style: TextStyle(fontSize: 14)),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) =>
//                       ViewPlansScreen(),
//                 ),
//               );
//             },
//             child: const Text("View Plans"),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildCard({required Widget child, Color? color}) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: color ?? Colors.white,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: child,
//     );
//   }
// }


import 'dart:io';

import 'package:flutter/material.dart';
import 'package:happy_weds_vendors/Screens/profile_screen.dart';
import 'package:happy_weds_vendors/Screens/view_plan_screen.dart';
import 'package:image_picker/image_picker.dart';

import 'answer_faq.dart';
import 'booking_screen.dart';
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
    const LeadsScreen(),
    const BookingsScreen(),
    const ProfileScreen(),
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
          BottomNavigationBarItem(icon: Icon(Icons.event), label: "Bookings"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {

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
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: CircleAvatar(
              backgroundImage: AssetImage("assets/profile.jpg"),
            ),
          ),
        ],
      ),
        drawer: Drawer(
          child: Column(
            children: [
              UserAccountsDrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.pinkAccent,
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundImage: NetworkImage('https://example.com/profile.jpg'),
                ),
                accountName: Text('ABC', style: TextStyle(fontWeight: FontWeight.bold)),
                accountEmail: Text('abc@example.com'),
              ),

              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    ListTile(
                      leading: Icon(Icons.dashboard, color: Colors.pinkAccent),
                      title: Text('Dashboard'),
                      onTap: () {
                        // Navigate to dashboard screen
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.calendar_today, color: Colors.pinkAccent),
                      title: Text('Bookings'),
                      onTap: () {
                        // Navigate to bookings screen
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.people, color: Colors.pinkAccent),
                      title: Text('Customers'),
                      onTap: () {
                        // Navigate to customers screen
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.settings, color: Colors.pinkAccent),
                      title: Text('Settings'),
                      onTap: () {
                        // Navigate to settings screen
                      },
                    ),
                  ],
                ),
              ),

              Divider(),

              ListTile(
                leading: Icon(Icons.logout, color: Colors.pinkAccent),
                title: Text('Logout'),
                onTap: () {
                  // Handle logout
                },
              ),
            ],
          ),
        ),

        body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _profileCompletionCard(context),
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

Widget _profileCompletionCard(BuildContext context) {
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
          value: 0.6, // Example progress (60%)
          backgroundColor: Colors.grey[300],
          color: Colors.pinkAccent,
          minHeight: 6,
        ),
        const SizedBox(height: 12),

        // List of actions
        _buildProfileTask(
          icon: Icons.question_answer_outlined,
          text: "Answer FAQs",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AnswerFaqsScreen()),
            );
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

Widget _uploadAlbumCard(BuildContext context) {
  return _buildCard(
    child: Row(
      children: [
        const Icon(Icons.photo_album, color: Colors.pinkAccent, size: 40),
        const SizedBox(width: 12),
        Expanded(
          child: const Text(
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
        Expanded(
          child: const Text(
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
            minimumSize: Size.fromHeight(40),
          ),
          onPressed: () {},
          child: const Text("Submit"),
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
        ListTile(
          leading: const CircleAvatar(child: Text("R")),
          title: const Text("Riya Sharma"),
          subtitle: const Text("Interested in Wedding Planning"),
          trailing: const Text("2h ago"),
        ),
        ListTile(
          leading: const CircleAvatar(child: Text("A")),
          title: const Text("Amit Patel"),
          subtitle: const Text("Wedding Planner Booking Enquiry"),
          trailing: const Text("5h ago"),
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
        Expanded(
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
              onPressed: () {
                // Action to share or invite customers for reviews
              },
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
