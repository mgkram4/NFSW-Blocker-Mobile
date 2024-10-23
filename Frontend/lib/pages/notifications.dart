import 'dart:convert';
import 'dart:io';


// here

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Updated apiBaseUrl definition
final String apiBaseUrl = kIsWeb
    ? 'http://localhost:5000'
    : Platform.isAndroid
        ? 'http://10.0.2.2:5000'
        : 'http://localhost:5000';

class NotificationsPage extends StatefulWidget {
  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<dynamic> messages = [];
  List<dynamic> detections = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
    });
    try {
      print('Attempting to connect to: $apiBaseUrl/get_messages');
      final messagesResponse = await http
          .get(Uri.parse('$apiBaseUrl/get_messages'))
          .timeout(Duration(seconds: 10));
      print('Response status: ${messagesResponse.statusCode}');
      print('Response body: ${messagesResponse.body}');

      print('Attempting to connect to: $apiBaseUrl/get_detections');
      final detectionsResponse = await http
          .get(Uri.parse('$apiBaseUrl/get_detections'))
          .timeout(Duration(seconds: 10));
      print('Response status: ${detectionsResponse.statusCode}');
      print('Response body: ${detectionsResponse.body}');

      if (messagesResponse.statusCode == 200 &&
          detectionsResponse.statusCode == 200) {
        setState(() {
          messages = json.decode(messagesResponse.body);
          detections = json.decode(detectionsResponse.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        isLoading = false;
      });
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text(
                'Failed to fetch notifications. Please check your connection and try again.'),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
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
    User? user = FirebaseAuth.instance.currentUser;
    String? email = user?.email;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.notifications, size: 28, color: Colors.white),
            SizedBox(width: 10),
            Text(
              'Notifications',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/auth_page');
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchData,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView(
                  children: [
                    Text(
                      'Messages',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    SizedBox(height: 10),
                    ...messages.map((message) => NotificationCard(
                          title: message['message'],
                          subtitle: 'Sent: ${message['timestamp']}',
                          icon: Icons.email,
                          onTap: () {
                            // Handle tap on message
                          },
                        )),
                    SizedBox(height: 20),
                    Text(
                      'Detections',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    SizedBox(height: 10),
                    ...detections.map((detection) => NotificationCard(
                          title: 'Detection in ${detection['image_path']}',
                          subtitle: 'Detected: ${detection['timestamp']}',
                          icon: Icons.warning,
                          onTap: () {
                            // Show detection details
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text('Detection Details'),
                                  content: SingleChildScrollView(
                                    child: Text(json
                                        .encode(detection['detected_content'])),
                                  ),
                                  actions: <Widget>[
                                    TextButton(
                                      child: Text('Close'),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        )),
                  ],
                ),
              ),
            ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  NotificationCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: Colors.black,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Colors.white, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                icon,
                size: 40,
                color: Colors.white,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
