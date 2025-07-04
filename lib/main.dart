import 'dart:io'; // Required for File class
import 'dart:convert'; // Required for jsonDecode
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DR Prediction App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? _selectedImage; // State variable to hold the selected image file
  String _predictionResult =
      'No prediction yet'; // State variable for prediction result
  final ImagePicker _picker = ImagePicker(); // Instance of ImagePicker

  // Function to pick an image from the gallery
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _predictionResult =
            'No prediction yet'; // Reset prediction when a new image is selected
      });
    }
  }

  // Function to send the image for prediction and process the response
  Future<void> _sendImageForPrediction() async {
    if (_selectedImage == null) {
      setState(() {
        _predictionResult = 'Please select an image first.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first!')),
      );
      return;
    }

    // IMPORTANT: REPLACE THIS URL with the actual URL of your backend API
    // If running on a local Flask server, you might use 'http://10.0.2.2:5000/predict_dr' for Android emulator
    // or 'http://localhost:5000/predict_dr' for iOS simulator/web.
    final uri = Uri.parse('YOUR_BACKEND_API_URL/predict_dr');

    setState(() {
      _predictionResult = 'Sending image for prediction...';
    });

    try {
      // Create a multipart request
      var request = http.MultipartRequest('POST', uri);

      // Add the image file to the request
      request.files.add(await http.MultipartFile.fromPath(
        'image', // This 'image' key must match the name expected by your Flask backend
        _selectedImage!.path,
      ));

      // Send the request
      var response = await request.send();

      // Read the response stream and get the response body
      var responseBody = await response.stream.bytesToString();

      // Process the response
      if (response.statusCode == 200) {
        // Decode the JSON response body
        var jsonResponse = jsonDecode(responseBody);

        // Extract the prediction result using the key 'prediction'
        // Update the state variable with the extracted result
        setState(() {
          // Safely access the 'prediction' key, providing a default if not found
          _predictionResult =
              'Prediction: ${jsonResponse['prediction'] ?? 'N/A'}';
        });
      } else {
        // Handle errors for non-200 status codes
        setState(() {
          _predictionResult = 'Error: ${response.statusCode} - $responseBody';
        });
      }
    } catch (e) {
      // Handle any exceptions during the request (e.g., network issues)
      setState(() {
        _predictionResult = 'Request failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DR Prediction App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Display the selected image or a placeholder
            if (_selectedImage != null)
              SizedBox(
                height: 200, // Adjust height as needed
                child: Image.file(_selectedImage!,
                    fit: BoxFit
                        .contain), // Use BoxFit.contain for better image scaling
              )
            else
              Container(
                height: 200, // Keep consistent height
                color: Colors.grey[300],
                child: const Center(
                  child: Text(
                    'Select an image',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              ),

            // Add some spacing between the image display and the button
            const SizedBox(height: 20),

            // Button to pick an image
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image),
              label: const Text('Pick Image'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),

            const SizedBox(height: 20),

            // Button to trigger prediction
            ElevatedButton.icon(
              onPressed: _sendImageForPrediction, // Now calls the new function
              icon: const Icon(Icons.analytics),
              label: const Text('Predict DR'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: const TextStyle(fontSize: 16),
                backgroundColor: Colors.green, // Example styling
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 20),

            // Text widget to display the prediction result
            Text(
              'Prediction Result: $_predictionResult',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
