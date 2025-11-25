import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  File? _image;
  bool _uploading = false;
  String? _error;

  final _supabase = supa.Supabase.instance.client;
  static const String bucketName = 'mobile'; // bucket di Supabase

  Future<void> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);

    if (picked != null) {
      setState(() {
        _image = File(picked.path);
        _error = null;
      });
    }
  }

  Future<void> uploadImage() async {
    if (_image == null) {
      setState(() => _error = "Pilih / ambil gambar dulu.");
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _error = "User tidak login.");
      return;
    }

    setState(() {
      _uploading = true;
      _error = null;
    });

    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final path = '${user.uid}/$fileName.jpg';

      // 1) Upload file ke Storage
      await _supabase.storage.from(bucketName).upload(path, _image!);

      // 2) Ambil URL public
      final publicUrl =
          _supabase.storage.from(bucketName).getPublicUrl(path);

      // 3) Simpan metadata ke tabel user_images
      await _supabase.from('user_images').insert({
        'uid': user.uid,
        'email': user.email,
        'image_url': publicUrl,
        // created_at pakai default now() di DB, jadi boleh tidak diisi
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload berhasil!')),
      );

      setState(() {
        _image = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _uploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_image != null)
                Image.file(
                  _image!,
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                )
              else
                const Text("Belum ada gambar terpilih"),

              const SizedBox(height: 16),

              if (_error != null)
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),

              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: () => pickImage(ImageSource.gallery),
                icon: const Icon(Icons.image),
                label: const Text("Pilih dari Galeri"),
              ),
              const SizedBox(height: 8),

              ElevatedButton.icon(
                onPressed: () => pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text("Ambil dari Kamera"),
              ),

              const SizedBox(height: 16),

              _uploading
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      onPressed: uploadImage,
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text("Upload ke Supabase"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
