import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'models/pokemon.dart';
import 'services/pokemon_service.dart';

class TextRecognitionPage extends ConsumerStatefulWidget {
  const TextRecognitionPage({super.key});

  @override
  ConsumerState<TextRecognitionPage> createState() => _TextRecognitionPageState();
}

class _TextRecognitionPageState extends ConsumerState<TextRecognitionPage> {
  File? _image;
  String _recognizedText = '';
  bool _isBusy = false;
  List<({String line, Pokemon? pokemon})> _scanResults = [];

  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer();
  final PokemonService _pokemonService = PokemonService();

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _processImage(InputImage inputImage) async {
    if (_isBusy) return;
    _isBusy = true;
    _scanResults = [];

    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        throw UnimplementedError(
            'Text recognition is not supported on desktop platforms yet.');
      }
      final recognizedText = await _textRecognizer.processImage(inputImage);
      setState(() {
        _recognizedText = recognizedText.text;
      });
      print('--- Recognized Text Start ---');
      print(_recognizedText);
      print('--- Recognized Text End ---');

      // Process lines
      final lines = _recognizedText.split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      if (lines.isNotEmpty) {
        final futures = lines.map((line) async {
          String query;
          // Check if line contains a number (ID)
          final numberMatch = RegExp(r'\d+').firstMatch(line);
          if (numberMatch != null) {
            query = numberMatch.group(0)!;
          } else {
            // Fallback to first word
            query = line.split(RegExp(r'\s+')).first;
          }

          final pokemon = await _pokemonService.fetchPokemonDetails(query);
          return (line: line, pokemon: pokemon);
        });

        final results = await Future.wait(futures);
        
        if (mounted) {
           setState(() {
             _scanResults = results;
           });
        }
      }

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
        _recognizedText = '';
        _scanResults = [];
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

  Widget _buildPokemonCard(Pokemon pokemon) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              pokemon.name.toUpperCase(),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '#${pokemon.id}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            if (pokemon.imageUrl != null)
              Image.network(
                pokemon.imageUrl!,
                height: 150,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(
                    height: 150,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
              ),
            const SizedBox(height: 16),
            if (pokemon.types != null && pokemon.types!.isNotEmpty)
              Wrap(
                spacing: 8,
                children: pokemon.types!
                    .map((t) => Chip(
                          label: Text(t.toUpperCase()),
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        ))
                    .toList(),
              ),
            const SizedBox(height: 16),
            if (pokemon.stats != null) ...[
              const Divider(),
              const Text('Stats', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...pokemon.stats!.map((s) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          (s['name'] as String).toUpperCase(),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: LinearProgressIndicator(
                          value: (s['value'] as int) / 200, 
                          backgroundColor: Colors.grey[200],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${s['value']}'),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
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
                  height: 200,
                ),
                const SizedBox(height: 20),
              ] else
                const Icon(
                  Icons.camera_alt,
                  size: 80,
                  color: Colors.grey,
                ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _isBusy ? null : _captureImage,
                icon: const Icon(Icons.camera),
                label: Text(_isBusy ? 'Processing...' : 'Take Picture'),
              ),
              
              if (_scanResults.isNotEmpty) ...[
                 const SizedBox(height: 30),
                 ListView.separated(
                   shrinkWrap: true,
                   physics: const NeverScrollableScrollPhysics(),
                   itemCount: _scanResults.length,
                   separatorBuilder: (context, index) => const SizedBox(height: 16),
                   itemBuilder: (context, index) {
                     final result = _scanResults[index];
                     if (result.pokemon != null) {
                       return _buildPokemonCard(result.pokemon!);
                     } else {
                       return Card(
                         color: Colors.grey[900],
                         child: ListTile(
                           leading: const Icon(Icons.error_outline, color: Colors.red),
                           title: Text(
                             '"${result.line}" not recognized',
                             style: const TextStyle(color: Colors.white),
                           ),
                           subtitle: const Text(
                             'Could not match to a Pokemon name',
                             style: TextStyle(color: Colors.white70),
                           ),
                         ),
                       );
                     }
                   },
                 ),
              ] else if (_recognizedText.isNotEmpty) ...[
                 const SizedBox(height: 20),
                 const Text('Recognized Text (No processing results):'),
                 Text(_recognizedText, style: const TextStyle(fontStyle: FontStyle.italic)),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
