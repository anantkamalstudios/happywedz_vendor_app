import 'package:flutter/material.dart';
import 'package:happy_weds_vendors/Screens/Project/CoverImage.dart';
import 'package:happy_weds_vendors/Screens/Project/vedioPage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

import 'Albums.dart';

void main() => runApp(MaterialApp(home: PortfolioPage()));

class PortfolioPage extends StatelessWidget {
  final List<Map<String, dynamic>> portfolioItems = [
    {
      "title": "Portfolio",
      "count": "65 Images",
      "icon": Icons.photo_album,
      "color": Colors.pinkAccent,
    },
    {
      "title": "Albums",
      "count": "3 Videos",
      "icon": Icons.videocam,
      "color": Colors.deepPurple,
    },
    {
      "title": "Videos",
      "count": "1 Image",
      "icon": Icons.image,
      "color": Colors.orange,
    },
    {
      "title": "Cover pic",
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
            subtitle: Text(item["count"], style: const TextStyle(color: Colors.grey)),
            trailing: Icon(Icons.cloud_upload, color: Colors.grey[600]),
            onTap: () {
              if (item["title"] == "Portfolio") {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddImagesPage(),
                  ),
                );
              } else if (item["title"] == "Albums") {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AlbumsPage(),
                  ),
                );
              } else if (item["title"] == "Videos") {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideosPage(),
                  ),
                );
              }
              else if (item["title"] == "Cover pic") {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CoverPicPage(),
                  ),
                );
              }

            },
          );
        },
      ),
    );
  }
}

class AddImagesPage extends StatefulWidget {
  @override
  _AddImagesPageState createState() => _AddImagesPageState();
}

class _AddImagesPageState extends State<AddImagesPage> {
  final ImagePicker _picker = ImagePicker();
  List<XFile> _images = [];
  List<int> _likes = [];
  String coverImagePath = "";

  @override
  void initState() {
    super.initState();
    _loadSavedImages();
    _loadCoverImage();
  }

  Future<void> _loadCoverImage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      coverImagePath = prefs.getString('cover_image_portfolio') ?? "";
    });
  }

  Future<void> _loadSavedImages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? paths = prefs.getStringList('saved_images');
    List<String>? likesStr = prefs.getStringList('saved_likes');

    if (paths != null) {
      setState(() {
        _images = paths.map((path) => XFile(path)).toList();
        if (likesStr != null && likesStr.length == paths.length) {
          _likes = likesStr.map((s) => int.tryParse(s) ?? 0).toList();
        } else {
          _likes = List.filled(paths.length, 0);
        }
      });
    }
  }

  Future<void> _pickCoverImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Save under drawer key
      await prefs.setString('coverImage', file.path);
      // Also save in portfolio key for portfolio page
      await prefs.setString('cover_image_portfolio', file.path);

      setState(() {
        coverImagePath = file.path; // Fixed variable name here
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cover image updated")),
      );
    }
  }

  Future<void> _saveImages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> paths = _images.map((img) => img.path).toList();
    List<String> likesStr = _likes.map((like) => like.toString()).toList();

    await prefs.setStringList('saved_images', paths);
    await prefs.setStringList('saved_likes', likesStr);
  }

  Future<void> _pickImages() async {
    final List<XFile>? selectedImages = await _picker.pickMultiImage();
    if (selectedImages != null && selectedImages.isNotEmpty) {
      setState(() {
        _images.addAll(selectedImages);
        _likes.addAll(List.filled(selectedImages.length, 0));
      });
      await _saveImages();
    }
  }

  void _onImageDeleted(int index) async {
    setState(() {
      _images.removeAt(index);
      _likes.removeAt(index);
    });
    await _saveImages();
  }

  void _onLikeImage(int index) async {
    setState(() {
      _likes[index]++;
    });
    await _saveImages();
  }

  void _deleteAllImages() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete All Images"),
        content: const Text("Are you sure you want to delete all images?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _images.clear();
                _likes.clear();
              });
              _saveImages();
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int totalTiles = _images.length + 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Portfolio"),
        backgroundColor: Colors.pinkAccent,
        flexibleSpace: coverImagePath.isNotEmpty
            ? Image.file(File(coverImagePath), fit: BoxFit.cover)
            : null,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _deleteAllImages();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'delete',
                child: Text("Delete All Images"),
              ),
            ],
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: totalTiles,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.0,
        ),
        itemBuilder: (context, index) {
          if (index == 0) {
            return GestureDetector(
              onTap: _pickImages,
              child: Container(
                color: Colors.grey.shade300,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, size: 40, color: Colors.grey),
                      SizedBox(height: 8),
                      Text("Add Images", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            );
          } else {
            final imgIndex = index - 1;
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ImagePreviewPage(
                      image: _images[imgIndex],
                      likes: _likes[imgIndex],
                      onLike: () {
                        _onLikeImage(imgIndex);
                        Navigator.pop(context);
                      },
                      onDelete: () {
                        _onImageDeleted(imgIndex);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                );
              },
              child: Image.file(
                File(_images[imgIndex].path),
                fit: BoxFit.cover,
              ),
            );
          }
        },
      ),
    );
  }
}

class ImagePreviewPage extends StatelessWidget {
  final XFile image;
  final int likes;
  final VoidCallback onLike;
  final VoidCallback onDelete;

  const ImagePreviewPage({
    Key? key,
    required this.image,
    required this.likes,
    required this.onLike,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          const SizedBox(height: 40),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Expanded(
            child: Center(
              child: Image.file(
                File(image.path),
                fit: BoxFit.contain,
                width: double.infinity,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              GestureDetector(
                onTap: onLike,
                child: Row(
                  children: [
                    const Icon(Icons.favorite_border, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      likes.toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Share clicked")),
                  );
                },
                child: const Icon(Icons.share, color: Colors.white),
              ),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(Icons.delete, color: Colors.red),
              ),
            ],
          ),
          const Divider(
            color: Colors.white,
            thickness: 1,
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: const [
                    Icon(Icons.account_circle, color: Colors.white),
                    SizedBox(height: 4),
                    Text("Make Cover Photo",
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
                Column(
                  children: const [
                    Icon(Icons.edit, color: Colors.white),
                    SizedBox(height: 4),
                    Text("Edit Photo",
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
