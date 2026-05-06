import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

final profileImageControllerProvider =
    ChangeNotifierProvider.family<ProfileImageController, String>((ref, uid) {
      return ProfileImageController(uid: uid);
    });

class ProfileImageController extends ChangeNotifier {
  ProfileImageController({required this.uid}) {
    _loadImage();
  }

  final String uid;
  Uint8List? _imageBytes;
  bool _isPicking = false;

  Uint8List? get imageBytes => _imageBytes;
  bool get isPicking => _isPicking;

  String get _storageKey => 'profile_image_$uid';

  Future<void> _loadImage() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_storageKey);
    if (encoded == null || encoded.isEmpty) {
      return;
    }

    _imageBytes = base64Decode(encoded);
    notifyListeners();
  }

  Future<void> pickAndSave() async {
    if (_isPicking) return;
    _isPicking = true;
    notifyListeners();

    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        imageQuality: 82,
      );
      if (image == null) return;

      final bytes = await image.readAsBytes();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, base64Encode(bytes));
      _imageBytes = bytes;
      notifyListeners();
    } finally {
      _isPicking = false;
      notifyListeners();
    }
  }
}
