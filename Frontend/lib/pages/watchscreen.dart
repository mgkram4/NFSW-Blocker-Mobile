import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WatchScreenPage extends StatefulWidget {
  const WatchScreenPage({super.key});

  @override
  _WatchScreenPageState createState() => _WatchScreenPageState();
}

class _WatchScreenPageState extends State<WatchScreenPage> {
  late bool _isRecording = false; // Initialize with default value

  @override
  void initState() {
    super.initState();
    _loadRecordingState(); // Load initial recording state when widget initializes
  }

  // Function to load recording state from SharedPreferences
  void _loadRecordingState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isRecording =
          prefs.getBool('isRecording') ?? false; // Default value is false
    });
  }

  // Function to save recording state to SharedPreferences
  void _saveRecordingState(bool recording) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isRecording', recording);
  }

  // Function to send POST request to start screen recording
  void _startRecording() async {
    final urlStartRecording = Uri.parse(
        'http://127.0.0.1:5000/start_recording'); // Replace with your backend URL
    try {
      final response = await http.post(urlStartRecording);
      if (response.statusCode == 200) {
        setState(() {
          _isRecording = true;
          _saveRecordingState(true); // Save current recording state
        });
        print('Screen recording started');
      } else {
        print('Failed to start screen recording: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error starting screen recording: $e');
    }
  }

  // Function to send POST request to stop screen recording
  void _stopRecording() async {
    final urlStopRecording = Uri.parse(
        'http://127.0.0.1:5000/stop_recording'); // Replace with your backend URL
    try {
      final response = await http.post(urlStopRecording);
      if (response.statusCode == 200) {
        setState(() {
          _isRecording = false;
          _saveRecordingState(false); // Save current recording state
        });
        print('Screen recording stopped');
      } else {
        print('Failed to stop screen recording: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error stopping screen recording: $e');
    }
  }

  void _toggleRecording() {
    if (_isRecording) {
      _stopRecording();
    } else {
      _startRecording();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Watch Screen',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        iconTheme:
            const IconThemeData(color: Colors.white), // Back button color
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              // Implement logout logic here
              Navigator.pushReplacementNamed(context, '/auth_page');
            },
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(
              Icons.videocam, // You can replace this with any suitable icon
              size: 108,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            Card(
              color: const Color(0xFF1E1E1E),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: const BorderSide(color: Colors.white, width: 2),
              ),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Screen Recording Notice',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'If explicit content is detected, you will be notified and the app will be terminated.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: _toggleRecording,
              child: Container(
                width: 150,
                height: 50,
                decoration: BoxDecoration(
                  color: _isRecording ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    _isRecording ? 'Recording On' : 'Recording Off',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
