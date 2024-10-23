import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ImagePicker _picker = ImagePicker();
  File? videoFile;
  VideoPlayerController? _videoController;
  Map<String, dynamic> _analysisResults = {};
  bool _isLoading = false;

  Future<void> _pickVideo() async {
    try {
      final XFile? pickedFile =
          await _picker.pickVideo(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          videoFile = File(pickedFile.path);
          _analysisResults = {};
        });

        _videoController = VideoPlayerController.file(videoFile!)
          ..initialize().then((_) {
            setState(() {});
          });
      }
    } catch (e) {
      print("Error picking video: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking video. Please try again.')),
      );
    }
  }

  Future<void> _analyzeVideo() async {
    if (videoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a video file')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://10.0.2.2:5000/analyze'),
      );

      request.files
          .add(await http.MultipartFile.fromPath('file', videoFile!.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        setState(() {
          _analysisResults = jsonDecode(response.body);
        });
      } else {
        throw Exception('Failed to analyze video: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error analyzing video: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error analyzing video. Please try again.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Analyze Video'),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/auth_page');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildVideoPreview(),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _pickVideo,
              icon: Icon(Icons.video_library),
              label: Text('Choose Video'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.black,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _analyzeVideo,
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Analyze Video'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.black,
                padding: EdgeInsets.symmetric(vertical: 15),
              ),
            ),
            SizedBox(height: 20),
            if (_analysisResults.isNotEmpty) _buildAnalysisResult(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPreview() {
    return Card(
      elevation: 4,
      color: Colors.grey[100],
      child: Container(
        height: 200,
        child: videoFile != null
            ? _videoController!.value.isInitialized
                ? AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: VideoPlayer(_videoController!),
                  )
                : Center(child: CircularProgressIndicator(color: Colors.black))
            : Center(
                child: Text('No video selected',
                    style: TextStyle(color: Colors.grey[300]))),
      ),
    );
  }

  Widget _buildAnalysisResult() {
    return Card(
      elevation: 4,
      color: Colors.purple[50],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Analysis Result',
                style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            ..._analysisResults.entries.map((entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    '${entry.key}: ${entry.value}',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }
}
