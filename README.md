# NSFW Content Detection System

A comprehensive mobile application for real-time detection and prevention of NSFW (Not Safe for Work) content. The system combines Flutter frontend with a Python backend to monitor and analyze screen content, providing automatic intervention when inappropriate content is detected.

## Features

- Real-time screen monitoring and content analysis
- Multiple detection methods:
  - NudeNet for NSFW content detection
  - YOLO model for detecting problematic objects (weapons, drugs, etc.)
- Automatic emulator termination upon detection
- Email notifications for detected content
- Comprehensive logging system
- User authentication and dashboard interface
- History tracking and notifications

## Tech Stack

### Backend (Python)
- Flask web server with CORS support
- OpenCV for video processing
- NudeNet for NSFW content detection
- YOLO for object detection
- Support for both Android (ADB) and iOS (simctl) emulators
- SMTP email integration

### Frontend (Flutter)
- Firebase Authentication
- Material Design UI
- Responsive dashboard layout
- Real-time status monitoring
- Video upload and analysis capabilities

## Setup

### Prerequisites
- Python 3.12
- Flutter SDK
- Android SDK (for Android emulator support)
- Xcode (for iOS simulator support)
- Firebase project configuration

### Backend Setup
1. Install Python dependencies:
```bash
pip install -r requirements.txt
```

2. Configure environment variables:
- ADB_PATH: Path to Android Debug Bridge
- SMTP email settings in app.py

3. Start the Flask server:
```bash
python app.py
```

### Frontend Setup
1. Install Flutter dependencies:
```bash
flutter pub get
```

2. Configure Firebase:
- Add your Firebase configuration files
- Update Firebase settings in the project

3. Run the application:
```bash
flutter run
```

## API Endpoints

- `/start_recording` (POST): Start screen recording
- `/stop_recording` (POST): Stop screen recording
- `/analyze` (POST): Analyze uploaded video content
- `/get_detections` (GET): Retrieve detection history
- `/get_messages` (GET): Retrieve message logs
- `/check_action` (GET): Check current monitoring status
- `/status` (GET): Get system status

## Monitoring System

The system uses two primary detection methods:
1. **NudeNet Detection**: Identifies NSFW content with confidence scores
2. **YOLO Detection**: Identifies problematic objects like weapons, drugs, etc.

### Monitored Content Types
- NSFW imagery
- Weapons (guns, knives)
- Drug-related items
- Alcohol-related items
- Other problematic objects

## Security Features

- Automatic emulator termination upon detection
- Email notifications to administrators
- Comprehensive logging system
- User authentication
- Activity history tracking

## Dashboard Features

- Video scanning
- History viewing
- Notification center
- Real-time screen monitoring
- User authentication
- Clean, intuitive interface

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to your branch
5. Open a Pull Request

## License

This project is proprietary and confidential. All rights reserved.

## Support

For support, email [your-support-email] or create an issue in the repository.
