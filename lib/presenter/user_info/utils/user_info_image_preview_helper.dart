import 'dart:io';

import 'package:flutter/material.dart';

/// Opens a full-screen preview for a locally stored document image.
void showUserInfoImagePreview(
  BuildContext context, {
  required String imagePath,
  required String title,
}) {
  final file = File(imagePath);
  if (!file.existsSync()) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(content: Text('تعذر عرض الصورة')),
    );
    return;
  }

  Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => UserInfoImagePreviewPage(
        imageFile: file,
        title: title,
      ),
    ),
  );
}

class UserInfoImagePreviewPage extends StatelessWidget {
  const UserInfoImagePreviewPage({
    super.key,
    required this.imageFile,
    required this.title,
  });

  final File imageFile;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        body: Center(
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: Image.file(
              imageFile,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'تعذر عرض الصورة',
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
