import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class GalleryViewModel with ChangeNotifier {
  XFile? _selectedImage;
  String? _error;
  bool _isLoading = false;

  XFile? get selectedImage => _selectedImage;
  String? get error => _error;
  bool get isLoading => _isLoading;

  Future<void> pickImage() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 90,
      );
      
      if (image != null) {
        _selectedImage = image;
        _error = null;
      }
    } catch (e) {
      _error = 'Error: $e';
      if (kDebugMode) {
        print('Image picker error: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearImage() {
    _selectedImage = null;
    _error = null;
    notifyListeners();
  }
}