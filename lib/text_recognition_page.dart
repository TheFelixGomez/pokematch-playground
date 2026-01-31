import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class TextRecognitionPage extends ConsumerStatefulWidget {
  const TextRecognitionPage({super.key});

  @override
  ConsumerState<TextRecognitionPage> createState() => _TextRecognitionPageState();
}

class _TextRecognitionPageState extends ConsumerState<TextRecognitionPage> {
  File? _image;
  String _recognizedText = '';
  bool _isBusy = false;

  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer();

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _processImage(InputImage inputImage) async {
    if (_isBusy) return;
    _isBusy = true;

    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        throw UnimplementedError(
            'Text recognition is not supported on desktop platforms yet.');
      }
      final recognizedText = await _textRecognizer.processImage(inputImage);
      setState(() {
        _recognizedText = recognizedText.text;
      });
      // Print to console as requested
      print('--- Recognized Text Start ---');
      print(_recognizedText);
      print('--- Recognized Text End ---');
    } catch (e) {
      print('Error processing image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _captureImage() async {
    try {
      final source = (Platform.isWindows || Platform.isLinux || Platform.isMacOS)
          ? ImageSource.gallery
          : ImageSource.camera;
          
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) return;

      setState(() {
        _image = File(image.path);
      });

      final inputImage = InputImage.fromFilePath(image.path);
      await _processImage(inputImage);
    } catch (e) {
      print('Error capturing image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error capturing image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_image != null) ...[
                Image.file(
                  _image!,
                  height: 300,
                ),
                const SizedBox(height: 20),
              ] else
                const Icon(
                  Icons.camera_alt,
                  size: 100,
                  color: Colors.grey,
                ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _isBusy ? null : _captureImage,
                icon: const Icon(Icons.camera),
                label: Text(_isBusy ? 'Processing...' : 'Take Picture'),
              ),
              if (_recognizedText.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'Recognized Text:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 10),
                Text(_recognizedText),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
