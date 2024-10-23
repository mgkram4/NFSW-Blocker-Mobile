import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Updated apiBaseUrl definition
final String apiBaseUrl = kIsWeb
    ? 'http://localhost:5000'
    : Platform.isAndroid
        ? 'http://10.0.2.2:5000'
        : 'http://localhost:5000';

class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<dynamic> detections = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDetections();
  }

  Future<void> fetchDetections() async {
    setState(() {
      isLoading = true;
    });
    try {
      print('Attempting to connect to: $apiBaseUrl/get_detections');
      final response = await http
          .get(Uri.parse('$apiBaseUrl/get_detections'))
          .timeout(const Duration(seconds: 10));
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      if (response.statusCode == 200) {
        setState(() {
          detections = json.decode(response.body);

          isLoading = false;
        });
      } else {
        throw Exception('Failed to load detections: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching detections: $e');
      setState(() {
        isLoading = false;
      });
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Text(
                'Failed to fetch detections. Please check your connection and try again.'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.history, size: 28, color: Colors.white),
            SizedBox(width: 10),
            Text(
              'History',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.black,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
                itemCount: detections.length,
                itemBuilder: (context, index) {
                  final detection = detections[index];
                  return VideoResultCard(
                    videoName: 'Detection ${index + 1}',
                    result: detection['detected_content']['nude'].isNotEmpty ||
                            detection['detected_content']['yolo'].isNotEmpty
                        ? 'Explicit'
                        : 'Safe',
                    date: detection['timestamp']
                        .split('T')[0], // Assuming ISO format date
                    analysisResults:
                        _formatAnalysisResults(detection['detected_content']),
                    ratings: {
                      "UNKNOWN": "Not Rated",
                      "LIKELY": "Likely",
                      "VERY_UNLIKELY": "Very Unlikely",
                    },
                    onTap: () {
                      // Handle tap on video result
                      print('Tapped on detection: ${detection['image_path']}');
                    },
                  );
                },
              ),
            ),
    );
  }

  bool noHistory = false;

  Map<String, String> _formatAnalysisResults(
      Map<String, dynamic> detectedContent) {
    Map<String, String> results = {};
    if (detectedContent['nude'].isNotEmpty) {
      results['Nude'] = detectedContent['nude'][0]['class'];
    }
    if (detectedContent['yolo'].isNotEmpty) {
      results['Object'] = detectedContent['yolo'][0]['class'];
    } else {
      noHistory = true;
    }
    return results;
  }
}

class VideoResultCard extends StatelessWidget {
  final String videoName;
  final String result;
  final String date;
  final Map<String, String> analysisResults;
  final Map<String, String> ratings;
  final VoidCallback onTap;

  const VideoResultCard({
    super.key,
    required this.videoName,
    required this.result,
    required this.date,
    required this.analysisResults,
    required this.ratings,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: const Color(0xFF1E1E1E),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.white, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    videoName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Icon(
                    Icons.history,
                    color: Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Date: $date',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Result: $result',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Icon(
                    result == 'Safe'
                        ? Icons.check_circle_outline
                        : Icons.warning,
                    color: result == 'Safe' ? Colors.green : Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: analysisResults.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${entry.key}:',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${entry.value} (${ratings['LIKELY'] ?? 'Unknown Rating'})',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
