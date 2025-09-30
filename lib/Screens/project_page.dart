import 'package:flutter/material.dart';

class PortfolioPage extends StatelessWidget {
  final List<Map<String, dynamic>> portfolioItems = [
    {
      "title": "Albums",
      "count": "65 Images",
      "icon": Icons.photo_album,
      "color": Colors.pinkAccent,
    },
    {
      "title": "Videos",
      "count": "3 Videos",
      "icon": Icons.videocam,
      "color": Colors.deepPurple,
    },
    {
      "title": "Cover Pic",
      "count": "1 Image",
      "icon": Icons.image,
      "color": Colors.orange,
    },
    {
      "title": "Logo",
      "count": "1 Image",
      "icon": Icons.star,
      "color": Colors.blue,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Projects"),
        backgroundColor: Colors.pinkAccent,
      ),
      body: ListView.builder(
        itemCount: portfolioItems.length,
        itemBuilder: (context, index) {
          final item = portfolioItems[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: item["color"].withOpacity(0.1),
              child: Icon(item["icon"], color: item["color"]),
            ),
            title: Text(item["title"],
                style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Text(item["count"],
                style: const TextStyle(color: Colors.grey)),
            trailing: Icon(Icons.cloud_upload, color: Colors.grey[600]),
            onTap: () {
              // Handle upload action here
            },
          );
        },
      ),
    );
  }
}
