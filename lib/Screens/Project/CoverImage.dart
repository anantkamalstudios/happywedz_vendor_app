import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CoverPicPage extends StatefulWidget {
  @override
  _CoverPicPageState createState() => _CoverPicPageState();
}

class _CoverPicPageState extends State<CoverPicPage> {
  String coverImagePath = "";

  @override
  void initState() {
    super.initState();
    _loadCoverImage();
  }

  Future<void> _loadCoverImage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      coverImagePath = prefs.getString('cover_image_portfolio') ?? "";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cover Pic"),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: coverImagePath.isNotEmpty
            ? Image.file(File(coverImagePath), fit: BoxFit.cover)
            : const Text("No cover image set yet"),
      ),
    );
  }
}
