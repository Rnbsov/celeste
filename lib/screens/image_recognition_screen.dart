import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class ImageRecognitionScreen extends StatefulWidget {
  const ImageRecognitionScreen({super.key});

  @override
  State<ImageRecognitionScreen> createState() => _ImageRecognitionScreenState();
}

class _ImageRecognitionScreenState extends State<ImageRecognitionScreen> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isAnalyzing = false;
  List<String> _recognizedObjects = [];
  String _errorMessage = '';

  static const String apiKey = 'AIzaSyCFBOf9xt4R-YNco-kj93Qwu97wmcVJt-M';
  static const String apiUrl =
      'https://vision.googleapis.com/v1/images:annotate?key=$apiKey';

  Future<void> _getImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _recognizedObjects = [];
        _errorMessage = '';
      });

      _analyzeImage();
    }
  }

  Future<void> _analyzeImage() async {
    if (_imageFile == null) return;

    setState(() {
      _isAnalyzing = true;
      _errorMessage = '';
    });

    try {
      final fileSize = await _imageFile!.length();
      if (fileSize > 10 * 1024 * 1024) {
        throw Exception(
          'Image size exceeds 10MB limit. Please choose a smaller image.',
        );
      }

      final bytes = await _imageFile!.readAsBytes();
      final base64Image = base64Encode(bytes);

      final body = jsonEncode({
        "requests": [
          {
            "image": {"content": base64Image},
            "features": [
              {"type": "LABEL_DETECTION", "maxResults": 10},
              {"type": "OBJECT_LOCALIZATION", "maxResults": 10},
            ],
          },
        ],
      });

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        final List<String> labels = [];

        if (data['responses'][0].containsKey('labelAnnotations')) {
          final labelAnnotations = data['responses'][0]['labelAnnotations'];
          for (var label in labelAnnotations) {
            labels.add(
              "${label['description']} (${(label['score'] * 100).toStringAsFixed(1)}%)",
            );
          }
        }

        if (data['responses'][0].containsKey('localizedObjectAnnotations')) {
          final objectAnnotations =
              data['responses'][0]['localizedObjectAnnotations'];
          for (var object in objectAnnotations) {
            labels.add(
              "${object['name']} (${(object['score'] * 100).toStringAsFixed(1)}%)",
            );
          }
        }

        setState(() {
          _recognizedObjects = labels;
          _isAnalyzing = false;
        });
      } else {
        String errorDetails = '';
        try {
          final errorResponse = jsonDecode(response.body);
          errorDetails =
              errorResponse['error']['message'] ?? 'Unknown API error';
        } catch (e) {
          errorDetails =
              response.body.isEmpty
                  ? 'No error details available'
                  : response.body;
        }

        throw Exception(
          'Failed to analyze image (${response.statusCode}): $errorDetails',
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Image Recognition'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_imageFile != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _imageFile!,
                    height: 300,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: Text('No image selected')),
                ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _getImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Photo'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _getImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              if (_isAnalyzing)
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Analyzing image...'),
                    ],
                  ),
                ),

              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),

              if (_recognizedObjects.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'What\'s in this image:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...List.generate(
                  _recognizedObjects.length,
                  (index) => Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: const Icon(Icons.check_circle_outline),
                      title: Text(_recognizedObjects[index]),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
