import 'dart:io';
import 'package:flutter/material.dart';
import 'package:junior_app/services/localization_extension.dart';
import 'package:junior_app/view_model/photo_library_view_model.dart';
import 'package:provider/provider.dart';

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('photos')),
        backgroundColor: Colors.blue.shade800,
      ),
      body: Consumer<GalleryViewModel>(
        builder: (context, galleryVM, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Pick Image Button
                ElevatedButton(
                  onPressed: galleryVM.pickImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  ),
                  child: Text(context.tr('pick_photo')),

                ),
                
                const SizedBox(height: 20),
                
                // Loading
                if (galleryVM.isLoading) 
                  const CircularProgressIndicator(),
                
                // Error
                if (galleryVM.error != null)
                  Text(
                    galleryVM.error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                
                // Selected Image
                if (galleryVM.selectedImage != null)
                  Expanded(
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(galleryVM.selectedImage!.path),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 300,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: galleryVM.clearImage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text(
                            'Clear Image',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (!galleryVM.isLoading && galleryVM.error == null)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.photo_library, size: 64, color: Colors.grey),
                        const SizedBox(height: 10),
                        Text(context.tr('no_photo_selected'),
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
