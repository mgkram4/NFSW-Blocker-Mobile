import json
import logging
import os
import shutil
import smtplib
import subprocess
import threading
import time
from datetime import datetime
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from typing import Dict, List

import cv2
import numpy as np
from flask import Flask, jsonify, request
from flask_cors import CORS
from mss import mss
from nudenet import NudeDetector
from ultralytics import YOLO
from werkzeug.utils import secure_filename

app = Flask(__name__)
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
CORS(app)

UPLOAD_FOLDER = 'uploads'
SCREENSHOTS_FOLDER = 'screenshots'
ADB_PATH = "/opt/homebrew/bin/adb"
DETECTION_LOG_FILE = 'detection_log.json'
MESSAGE_LOG_FILE = 'message_log.json'
NO_HISTORY_LOG_FILE = 'noHistory.json'

for folder in [UPLOAD_FOLDER, SCREENSHOTS_FOLDER]:
    if not os.path.exists(folder):
        os.makedirs(folder)

app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

is_recording = False
recording_thread = None
termination_event = threading.Event()

nude_detector = NudeDetector()
yolo_model = YOLO('yolov8n.pt')



PROBLEMATIC_CLASSES = ['person', 'gun', 'knife', 'wine glass', 'bottle', 'pistol', 'rifle', 'shotgun', 'ammunition', 'holster', 'cigarette', 'syringe', 'pills']

# Email configuration
SMTP_SERVER = 'smtp-mail.outlook.com'
SMTP_PORT = 587
SENDER_EMAIL = 'sendSMScode@outlook.com'
SENDER_PASSWORD = 'wwapldfnxgcbtokx'
RECIPIENT_EMAIL = 'sendSMScode@outlook.com'

def find_simctl():
    # Try using shutil.which to find xcrun in PATH
    xcrun_path = shutil.which('xcrun')
    
    if xcrun_path:
        logging.info(f"Found xcrun at: {xcrun_path}")
        return f"{xcrun_path} simctl"
    
    # If not found in PATH, try common locations
    common_locations = [
        "/usr/bin/xcrun",
        "/Applications/Xcode.app/Contents/Developer/usr/bin/xcrun",
        "/Library/Developer/CommandLineTools/usr/bin/xcrun"
    ]
    
    for location in common_locations:
        if os.path.exists(location):
            logging.info(f"Found xcrun at: {location}")
            return f"{location} simctl"

    logging.error("Could not find xcrun. iOS simulator control will not be available.")
    return None

SIMCTL_PATH = find_simctl()

if SIMCTL_PATH is None:
    logging.warning("simctl not found. iOS simulator control will not be available.")
else:
    logging.info(f"Using simctl at: {SIMCTL_PATH}")


def send_email(subject, body):
    try:
        message = MIMEMultipart()
        message['From'] = SENDER_EMAIL
        message['To'] = RECIPIENT_EMAIL
        message['Subject'] = subject
        message.attach(MIMEText(body, 'plain'))

        with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
            server.starttls()
            server.login(SENDER_EMAIL, SENDER_PASSWORD)
            server.send_message(message)
        
        log_message("Email sent: " + subject)
        logging.info(f"Email sent: {subject}")
    except Exception as e:
        logging.error(f"Error sending email: {str(e)}")
        log_message(f"Failed to send email: {subject}. Error: {str(e)}")

def log_message(message: str):
    try:
        if os.path.exists(MESSAGE_LOG_FILE):
            with open(MESSAGE_LOG_FILE, 'r') as f:
                log = json.load(f)
        else:
            log = []

        log_entry = {
            'timestamp': datetime.now().isoformat(),
            'message': message
        }
        log.append(log_entry)

        with open(MESSAGE_LOG_FILE, 'w') as f:
            json.dump(log, f, indent=2)

        logging.info(f"Message logged: {log_entry}")
    except Exception as e:
        logging.error(f"Error logging message: {str(e)}")

def log_detection(image_path: str, detected_content: Dict):
    try:
        if os.path.exists(DETECTION_LOG_FILE):
            with open(DETECTION_LOG_FILE, 'r') as f:
                log = json.load(f)
        else:
            log = []

        log_entry = {
            'timestamp': datetime.now().isoformat(),
            'image_path': image_path,
            'detected_content': detected_content
        }
        log.append(log_entry)

        with open(DETECTION_LOG_FILE, 'w') as f:
            json.dump(log, f, indent=2)

        logging.info(f"Detection logged: {log_entry}")
    except Exception as e:
        logging.error(f"Error logging detection: {str(e)}")

def no_history_detection(image_path: str, detected_content: Dict):
    try:
        if os.path.exists(NO_HISTORY_LOG_FILE):
            with open(NO_HISTORY_LOG_FILE, 'r') as f:
                log = json.load(f)
        else:
            log = []

        log_entry = {
            'timestamp': datetime.now().isoformat(),
            'image_path': image_path,
            'detected_content': detected_content
        }
        log.append(log_entry)

        with open(NO_HISTORY_LOG_FILE, 'w') as f:
            json.dump(log, f, indent=2)

        logging.info(f"Detection logged: {log_entry}")
    except Exception as e:
        logging.error(f"Error logging detection: {str(e)}")

def delete_existing_screenshots():
    try:
        shutil.rmtree(SCREENSHOTS_FOLDER)
        os.makedirs(SCREENSHOTS_FOLDER)
        logging.info(f"Deleted existing screenshots and recreated {SCREENSHOTS_FOLDER}")
    except Exception as e:
        logging.error(f"Error deleting screenshots: {str(e)}")

def start_screen_recording():
    global is_recording, recording_thread
    if is_recording:
        return

    delete_existing_screenshots()
    termination_event.clear()
    recording_thread = threading.Thread(target=screen_recording_thread)
    recording_thread.start()

def stop_screen_recording():
    global is_recording
    if not is_recording:
        return

    is_recording = False
    termination_event.set()
    if recording_thread and recording_thread != threading.current_thread():
        recording_thread.join(timeout=5)
    logging.info('Screen recording stopped')

def screen_recording_thread():
    global is_recording
    is_recording = True
    logging.info('Screen recording started')

    interval_seconds = 3
    screenshot_count = 0
    with mss() as sct:
        while is_recording and not termination_event.is_set():
            try:
                screenshot = sct.grab(sct.monitors[0])
                img = np.array(screenshot)
                img = cv2.cvtColor(img, cv2.COLOR_RGBA2RGB)
                screenshot_path = os.path.join(SCREENSHOTS_FOLDER, f'screenshot_{screenshot_count}.png')
                cv2.imwrite(screenshot_path, img)
                logging.info(f"Screenshot saved: {screenshot_path}")
                
                detected_content = analyze_image(screenshot_path)
                if detected_content:
                    logging.warning("Problematic content detected in screenshot.")
                    log_detection(screenshot_path, detected_content)
                    handle_explicit_content(screenshot_path, detected_content)
                    
                    break  # Stop taking screenshots
                
                screenshot_count += 1
                time.sleep(interval_seconds)
            except Exception as e:
                logging.error(f"Error in screen recording: {str(e)}")
                time.sleep(interval_seconds)

def analyze_image(image_path: str) -> Dict:
    detected_content = {'nude': [], 'yolo': []}
    try:
        nude_result = nude_detector.detect(image_path)
        
        for detection in nude_result:
            if detection['class'] in ['EXPOSED_GENITALIA', 'EXPOSED_BREAST_F', 'EXPOSED_BUTTOCKS'] and detection['score'] > 0.7:
                detected_content['nude'].append({
                    'class': detection['class'],
                    'score': detection['score']
                })
        
        yolo_results = yolo_model(image_path)
        
        for result in yolo_results:
            boxes = result.boxes
            for box in boxes:
                cls = int(box.cls[0])
                conf = float(box.conf[0])
                label = result.names[cls]
                if label in PROBLEMATIC_CLASSES and conf > 0.1:
                    detected_content['yolo'].append({
                        'class': label,
                        'confidence': conf
                    })
        
        if detected_content['nude'] or detected_content['yolo']:
            return detected_content
        
        return {}
    except Exception as e:
        logging.error(f"Error in analyzing image: {str(e)}")
        return {}

def get_running_emulators() -> List[tuple]:
    emulators = []
    
    # Get Android emulators
    try:
        output = subprocess.run([ADB_PATH, 'devices'], capture_output=True, text=True, check=True)
        lines = output.stdout.strip().split('\n')[1:]
        emulators.extend([('android', line.split('\t')[0]) for line in lines if line.strip()])  
        logging.info(f"Found Android emulators: {emulators}")
    except subprocess.CalledProcessError as e:
        logging.error(f"Error getting Android emulator list: {str(e)}. Output: {e.stdout}")
    except FileNotFoundError:
        logging.error(f"ADB not found at {ADB_PATH}")

    # Get iOS simulators
    if SIMCTL_PATH:
        try:
            output = subprocess.run(SIMCTL_PATH.split() + ['list', 'devices'], capture_output=True, text=True, check=True)
            lines = output.stdout.strip().split('\n')
            for line in lines:
                if '(Booted)' in line:
                    device_id = line.split('(')[1].split(')')[0]
                    emulators.append(('ios', device_id))
            logging.info(f"Found iOS simulators: {[e for e in emulators if e[0] == 'ios']}")
        except subprocess.CalledProcessError as e:
            logging.error(f"Error getting iOS simulator list: {str(e)}. Output: {e.stdout}")
    else:
        logging.warning("simctl not found. Cannot check for iOS simulators.")

    return emulators

def terminate_emulator(emulator_type: str, device_id: str) -> bool:
    if emulator_type == 'android':
        return terminate_android_emulator(device_id)
    elif emulator_type == 'ios':
        return terminate_ios_simulator(device_id)
    else:
        logging.error(f"Unknown emulator type: {emulator_type}")
        return False

def terminate_android_emulator(device_id: str) -> bool:
    try:
        subprocess.run([ADB_PATH, '-s', device_id, 'emu', 'kill'], check=True, timeout=10)
        logging.info(f"Sent kill command to Android emulator {device_id}")
        
        for _ in range(5):
            time.sleep(1)
            if ('android', device_id) not in get_running_emulators():
                logging.info(f"Android emulator {device_id} successfully terminated")
                return True
        
        logging.warning(f"Failed to verify termination of Android emulator {device_id}")
        return False
    except subprocess.CalledProcessError as e:
        logging.error(f"Error executing ADB command for {device_id}: {str(e)}")
        return False
    except subprocess.TimeoutExpired:
        logging.error(f"Timeout while terminating Android emulator {device_id}")
        return False
    except FileNotFoundError:
        logging.error(f"ADB not found at {ADB_PATH}")
        return False

def terminate_ios_simulator(device_id: str) -> bool:
    if SIMCTL_PATH is None:
        logging.error("simctl not found. Cannot terminate iOS simulator.")
        return False

    try:
        result = subprocess.run(SIMCTL_PATH.split() + ['shutdown', device_id], capture_output=True, text=True, check=True, timeout=10)
        logging.info(f"Sent shutdown command to iOS simulator {device_id}. Output: {result.stdout}")
        
        # Wait for the simulator to shut down
        for _ in range(10):  # Increase wait time to 10 seconds
            time.sleep(1)
            # Check if the simulator is still running
            check_result = subprocess.run(SIMCTL_PATH.split() + ['list', 'devices'], capture_output=True, text=True, check=True)
            if device_id not in check_result.stdout:
                logging.info(f"iOS simulator {device_id} successfully terminated")
                return True
        
        logging.warning(f"Failed to verify termination of iOS simulator {device_id}")
        return False
    except subprocess.CalledProcessError as e:
        logging.error(f"Error executing simctl command for {device_id}: {str(e)}. Output: {e.stdout}")
        return False
    except subprocess.TimeoutExpired:
        logging.error(f"Timeout while terminating iOS simulator {device_id}")
        return False
    except Exception as e:
        logging.error(f"Unexpected error while terminating iOS simulator {device_id}: {str(e)}")
        return False

def handle_explicit_content(image_path: str, detected_content: Dict):
    logging.warning("Explicit content detected! Attempting to close the emulators.")
    emulators = get_running_emulators()
    logging.info(f"Running emulators before termination attempt: {emulators}")
    
    for emulator_type, emulator_id in emulators:
        if terminate_emulator(emulator_type, emulator_id):
            logging.info(f"Successfully terminated {emulator_type} emulator: {emulator_id}")
        else:
            logging.warning(f"Failed to terminate {emulator_type} emulator: {emulator_id}")
    
    # Check if any emulators are still running
    remaining_emulators = get_running_emulators()
    if remaining_emulators:
        logging.warning(f"Some emulators are still running after termination attempt: {remaining_emulators}")
    else:
        logging.info("All emulators have been terminated successfully.")

    # Send email notification
    subject = "Explicit Content Detected"
    body = f"Explicit content was detected in the image: {image_path}\n\nDetected content: {json.dumps(detected_content, indent=2)}\n\nEmulators before termination attempt: {emulators}\nRemaining emulators after termination attempt: {remaining_emulators}"
    send_email(subject, body)

@app.route('/start_recording', methods=['POST'])
def api_start_recording():
    start_screen_recording()
    return jsonify({"message": "Screen recording started."}), 200

@app.route('/stop_recording', methods=['POST'])
def api_stop_recording():
    stop_screen_recording()
    return jsonify({"message": "Screen recording stopped."}), 200

@app.route('/analyze', methods=['POST'])
def analyze_video():
    global is_recording

    if is_recording:
        return jsonify({"message": "Screen recording is active."}), 400

    if 'file' not in request.files:
        return jsonify({"error": "No file provided"}), 400

    file = request.files['file']
    filename = secure_filename(file.filename)
    filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)
    file.save(filepath)

    detected_content = analyze_video_file(filepath)

    if detected_content:
        log_detection(filepath, detected_content)
        handle_explicit_content(filepath, detected_content)
        # no_history_detection(filepath, detected_content)
        return jsonify({"message": "Problematic content detected.", "details": detected_content}), 200
    else:
        return jsonify({"message": "No problematic content detected."}), 200

def analyze_video_file(video_path: str) -> Dict:
    cap = cv2.VideoCapture(video_path)
    frame_count = 0
    detected_content = {'nude': [], 'yolo': []}
    
    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break
        
        frame_count += 1
        if frame_count % 30 == 0:  # Analyze every 30th frame
            frame_path = os.path.join(UPLOAD_FOLDER, f'temp_frame_{frame_count}.jpg')
            cv2.imwrite(frame_path, frame)
            
            frame_content = analyze_image(frame_path)
            if frame_content:
                detected_content['nude'].extend(frame_content.get('nude', []))
                detected_content['yolo'].extend(frame_content.get('yolo', []))
            
            os.remove(frame_path)
    
    cap.release()
    return detected_content if (detected_content['nude'] or detected_content['yolo']) else {}

@app.route('/get_detections', methods=['GET'])
def get_detections():
    try:
        if os.path.exists(DETECTION_LOG_FILE):
            with open(DETECTION_LOG_FILE, 'r') as f:
                log = json.load(f)
            return jsonify(log), 200
        else:
            return jsonify([]), 200
    except Exception as e:
        logging.error(f"Error retrieving detections: {str(e)}")
        return jsonify({"error": "Failed to retrieve detections"}), 500

@app.route('/get_messages', methods=['GET'])
def get_messages():
    try:
        if os.path.exists(MESSAGE_LOG_FILE):
            with open(MESSAGE_LOG_FILE, 'r') as f:
                log = json.load(f)
            return jsonify(log), 200
        else:
            return jsonify([]), 200
    except Exception as e:
        logging.error(f"Error retrieving messages: {str(e)}")
        return jsonify({"error": "Failed to retrieve messages"}), 500

@app.route('/check_action', methods=['GET'])
def check_action():
    global is_recording
    if not is_recording:
        return jsonify({"action": None}), 200
    
    # Check if there's any problematic content detected
    if os.path.exists(DETECTION_LOG_FILE):
        with open(DETECTION_LOG_FILE, 'r') as f:
            log = json.load(f)
        if log and log[-1]['detected_content']:
            return jsonify({"action": "disrupt"}), 200
    
    return jsonify({"action": None}), 200

@app.route('/status', methods=['GET'])
def get_status():
    global is_recording
    return jsonify({
        "is_recording": is_recording,
    }), 200

if __name__ == '__main__':
    logging.info(f"Current PATH: {os.environ.get('PATH')}")
    
    try:
        subprocess.run([ADB_PATH, "version"], check=True, capture_output=True, text=True)
        logging.info("ADB is accessible")
    except FileNotFoundError:
        logging.error(f"ADB not found at {ADB_PATH}")
    except subprocess.CalledProcessError as e:
        logging.error(f"Error running ADçB: {e}")
    
    if SIMCTL_PATH:
        try:
            subprocess.run(SIMCTL_PATH.split() + ["version"], check=True, capture_output=True, text=True)
            logging.info("simctl is accessible")
        except subprocess.CalledProcessError as e:
            logging.error(f"Error running simctl: {e}")
    else:
        logging.warning("simctl not found. iOS simulator control will not be available.")
    
    app.run(debug=False, host='0.0.0.0', port=5000)