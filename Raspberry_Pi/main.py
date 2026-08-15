```python
import requests
import os
import time
import serial
from datetime import datetime
import firebase_admin
from firebase_admin import credentials, storage, db
import threading
import subprocess
import json
import atexit
import signal
import sys

# ========== إعدادات Firebase ==========
# ضع ملف Firebase Service Account على Raspberry Pi
# ولا ترفعه إلى GitHub.
FIREBASE_CREDENTIALS = os.getenv(
    "FIREBASE_CREDENTIALS",
    "firebase-service-account.json"
)

if not os.path.exists(FIREBASE_CREDENTIALS):
    raise FileNotFoundError(
        "Firebase credentials file was not found. "
        "Set FIREBASE_CREDENTIALS or place firebase-service-account.json "
        "in the Raspberry Pi project directory."
    )

cred = credentials.Certificate(FIREBASE_CREDENTIALS)

firebase_admin.initialize_app(cred, {
    "storageBucket": "emergency-system-2ae13.firebasestorage.app",
    "databaseURL": "https://emergency-system-2ae13-default-rtdb.firebaseio.com"
})

bucket = storage.bucket()
ref = db.reference("/")

# ========== إعدادات النظام ==========
API_URL = "https://emergency1-emergency-project.hf.space/predict"

# لا تضع رقم الهاتف مباشرة داخل GitHub.
# يمكن تعريفه على Raspberry Pi كمتغير بيئة:
# export EMERGENCY_PHONE="ATD+970XXXXXXXXX;\r"
PHONE_NUMBER = os.getenv("EMERGENCY_PHONE")

DEVICE_ID = "device1"
OFFLINE_QUEUE_FILE = "offline_queue.json"
OFFLINE_VIDEOS_DIR = "offline_videos"
SERIAL_PORT = "/dev/ttyUSB2"

os.makedirs(OFFLINE_VIDEOS_DIR, exist_ok=True)

serial_lock = threading.Lock()

DEFAULT_LOCATION = {
    "latitude": 32.2211,
    "longitude": 35.2544
}


# ========== نت الشريحة — تفعيل/تعطيل ==========

def enable_sim_internet():
    """يفعّل نت الشريحة لما ينقطع الـ WiFi."""
    try:
        os.system(
            "sudo nmcli connection up gsm 2>/dev/null || "
            "sudo nmcli connection add type gsm ifname '*' "
            "con-name gsm apn internet 2>/dev/null && "
            "sudo nmcli connection up gsm 2>/dev/null"
        )
        print("📶 تم تفعيل نت الشريحة")
    except Exception as e:
        print(f"❌ فشل تفعيل نت الشريحة: {e}")


def disable_sim_internet():
    """يعطّل نت الشريحة لما يرجع الـ WiFi."""
    try:
        os.system("sudo nmcli connection down gsm 2>/dev/null")
        print("📶 تم تعطيل نت الشريحة")
    except Exception as e:
        print(f"❌ فشل تعطيل نت الشريحة: {e}")


sim_internet_active = False


def check_and_switch_network():
    """يراقب النت ويبدّل تلقائياً بين WiFi والشريحة."""
    global sim_internet_active

    try:
        requests.get("https://www.google.com", timeout=2)

        # النت شغال
        if sim_internet_active:
            disable_sim_internet()
            sim_internet_active = False

    except Exception:
        # النت مقطوع — فعّل الشريحة
        if not sim_internet_active:
            enable_sim_internet()
            sim_internet_active = True
            time.sleep(5)


# ========== التحقق من الإنترنت ==========

def has_internet():
    try:
        requests.get("https://www.google.com", timeout=2)
        return True
    except Exception:
        return False


# ========== إدارة حالة الجهاز ==========

def set_device_status(status):
    try:
        location = get_gps_location()

        ref.child("devices").child(DEVICE_ID).update({
            "DeviceId": DEVICE_ID,
            "Status": status,
            "Location": "Nablus Street 1",
            "lastSeen": datetime.now().isoformat(),
            "latitude": location["latitude"],
            "longitude": location["longitude"]
        })

        print(f"📡 حالة الجهاز: {status}")

    except Exception as e:
        print(f"❌ فشل تحديث حالة الجهاز: {e}")


def on_exit():
    print("🔴 إيقاف النظام...")
    threading.Thread(
        target=set_device_status,
        args=("inactive",),
        daemon=True
    ).start()


def handle_signal(sig, frame):
    on_exit()
    sys.exit(0)


atexit.register(on_exit)
signal.signal(signal.SIGTERM, handle_signal)
signal.signal(signal.SIGINT, handle_signal)


# ========== تحويل الفيديو إلى MP4 ==========

def convert_to_mp4(input_file):
    output_file = input_file.replace(".h264", ".mp4")

    try:
        subprocess.run(
            [
                "ffmpeg",
                "-y",
                "-i",
                input_file,
                "-c:v",
                "copy",
                output_file
            ],
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )

        os.remove(input_file)

        print("✅ تم تحويل الفيديو إلى MP4")
        return output_file

    except Exception as e:
        print(f"❌ فشل تحويل الفيديو: {e}")
        return None


# ========== الطابور المحلي ==========

def load_offline_queue():
    if os.path.exists(OFFLINE_QUEUE_FILE):
        with open(OFFLINE_QUEUE_FILE, "r") as f:
            return json.load(f)

    return []


def save_offline_queue(queue):
    with open(OFFLINE_QUEUE_FILE, "w") as f:
        json.dump(queue, f, indent=2)


def add_to_offline_queue(incident_id, video_path, incident_data):
    queue = load_offline_queue()

    queue.append({
        "incident_id": incident_id,
        "video_path": video_path,
        "incident_data": incident_data,
        "timestamp": datetime.now().isoformat()
    })

    save_offline_queue(queue)

    print(f"💾 تم الحفظ محلياً: {incident_id}")


def upload_offline_queue():
    queue = load_offline_queue()

    if not queue:
        return

    print(f"📤 يوجد {len(queue)} حدث محفوظ، جاري الرفع...")

    remaining = []

    for item in queue:
        try:
            incident_id = item["incident_id"]
            video_path = item["video_path"]
            incident_data = item["incident_data"]

            ref.child("incidents").child(incident_id).set(
                incident_data
            )

            if video_path and os.path.exists(video_path):
                video_url = upload_to_storage(video_path)

                ref.child("incidents").child(incident_id).update({
                    "video": {
                        "videoUrl": video_url,
                        "duration": 5,
                        "format": "mp4",
                        "size": "~3.5MB"
                    }
                })

                os.remove(video_path)

                print(f"✅ تم رفع وحذف: {incident_id}")

        except Exception as e:
            print(
                f"❌ فشل رفع {item.get('incident_id')}: {e}"
            )
            remaining.append(item)

    save_offline_queue(remaining)


# ========== الدوال الأصلية ==========

def capture_image():
    os.system(
        "rpicam-still --vflip -o current.jpg"
    )


def send_to_ai():
    with open("current.jpg", "rb") as image_file:
        files = {
            "file": image_file
        }

        response = requests.post(
            API_URL,
            files=files,
            timeout=10
        )

    try:
        return response.json()
    except Exception:
        return {}


def get_event_type(result):
    if isinstance(result, dict):
        objects = result.get("objects", [])

        if "fire" in [o.lower() for o in objects]:
            return "fire"

        if "accident" in [o.lower() for o in objects]:
            return "accident"

    return "unknown"


def is_danger(result):
    if isinstance(result, dict):
        objects = result.get("objects", [])

        return any(
            o.lower() in ["fire", "accident"]
            for o in objects
        )

    return False


def has_face(result):
    if isinstance(result, dict):
        objects = result.get("objects", [])

        return "face" in [
            o.lower() for o in objects
        ]

    return False


def get_gps_location():
    with serial_lock:
        try:
            ser = serial.Serial(
                SERIAL_PORT,
                9600,
                timeout=1
            )

            ser.write(b"AT+CGPS=1\r")
            time.sleep(1)

            ser.write(b"AT+CGPSINFO\r")
            time.sleep(1)

            response = ser.read(200).decode(
                errors="ignore"
            )

            ser.close()

            if "+CGPSINFO:" in response:
                parts = (
                    response
                    .split("+CGPSINFO:")[1]
                    .split("\r")[0]
                    .strip()
                    .split(",")
                )

                if len(parts) >= 4 and parts[0]:
                    lat = (
                        float(parts[0][:2])
                        + float(parts[0][2:]) / 60
                    )

                    if parts[1] == "S":
                        lat = -lat

                    lon = (
                        float(parts[2][:3])
                        + float(parts[2][3:]) / 60
                    )

                    if parts[3] == "W":
                        lon = -lon

                    return {
                        "latitude": lat,
                        "longitude": lon
                    }

        except Exception as e:
            print(f"❌ فشل قراءة GPS: {e}")

    return DEFAULT_LOCATION


def upload_to_storage(file_path):
    blob = bucket.blob(
        f"incidents/{os.path.basename(file_path)}"
    )

    blob.upload_from_filename(file_path)
    blob.make_public()

    return blob.public_url


def make_call():
    if not PHONE_NUMBER:
        print(
            "⚠️ EMERGENCY_PHONE غير موجود. "
            "تم تخطي المكالمة."
        )
        return

    with serial_lock:
        try:
            ser = serial.Serial(
                SERIAL_PORT,
                9600,
                timeout=2
            )

            ser.write(
                PHONE_NUMBER.encode()
                if isinstance(PHONE_NUMBER, str)
                else PHONE_NUMBER
            )

            time.sleep(1)

            response = ser.read(200).decode(
                errors="ignore"
            )

            print(f"📞 رد الموديم: {response}")

            time.sleep(20)

            ser.write(b"ATH\r")

            print("✅ تم إنهاء المكالمة")

            ser.close()

        except Exception as e:
            print(f"❌ فشل الاتصال: {e}")


def play_alarm():
    os.system(
        "mpg123 alarm.mp3 > /dev/null 2>&1 &"
    )


# ========== إرسال البيانات فوراً ==========

def send_incident_data_instant(
    incident_id,
    incident_data
):
    if has_internet():
        try:
            ref.child("alerts").push({
                "status": "alert",
                "type": incident_data["type"].lower(),
                "time": incident_data["timestamp"]
            })

            ref.child("incidents").child(
                incident_id
            ).set(incident_data)

            print(
                f"⚡ تم إرسال البيانات: {incident_id}"
            )

        except Exception as e:
            print(f"❌ فشل الإرسال: {e}")

            add_to_offline_queue(
                incident_id,
                None,
                incident_data
            )

    else:
        add_to_offline_queue(
            incident_id,
            None,
            incident_data
        )


def update_location_background(incident_id):
    location = get_gps_location()

    try:
        ref.child("incidents").child(
            incident_id
        ).update({
            "location": location
        })

        print(
            f"📍 تم تحديث الموقع: {incident_id}"
        )

    except Exception as e:
        print(
            f"❌ فشل تحديث الموقع: {e}"
        )


# ========== معالجة الفيديو بالخلفية ==========

def process_video_background(
    video_h264,
    incident_id,
    incident_data,
    face_image
):
    time.sleep(6)

    video_mp4 = convert_to_mp4(
        video_h264
    )

    if face_image and has_internet():
        try:
            face_url = upload_to_storage(
                face_image
            )

            ref.child("incidents").child(
                incident_id
            ).update({
                "detectedFaces": [
                    {
                        "faceId": "face1",
                        "image": face_url
                    }
                ]
            })

            os.remove(face_image)

        except Exception as e:
            print(
                f"❌ فشل رفع الوجه: {e}"
            )

    if has_internet():
        try:
            if video_mp4:
                video_url = upload_to_storage(
                    video_mp4
                )

                ref.child("incidents").child(
                    incident_id
                ).update({
                    "video": {
                        "videoUrl": video_url,
                        "duration": 5,
                        "format": "mp4",
                        "size": "~3.5MB"
                    }
                })

                os.remove(video_mp4)

                print(
                    "✅ تم رفع الفيديو وحذفه"
                )

        except Exception as e:
            print(
                f"❌ فشل رفع الفيديو: {e}"
            )

            if video_mp4:
                local_path = os.path.join(
                    OFFLINE_VIDEOS_DIR,
                    os.path.basename(video_mp4)
                )

                os.rename(
                    video_mp4,
                    local_path
                )

                add_to_offline_queue(
                    incident_id,
                    local_path,
                    incident_data
                )

    else:
        if video_mp4:
            local_path = os.path.join(
                OFFLINE_VIDEOS_DIR,
                os.path.basename(video_mp4)
            )

            os.rename(
                video_mp4,
                local_path
            )

            add_to_offline_queue(
                incident_id,
                local_path,
                incident_data
            )


# ========== حفظ الحدث ==========

def save_event(result):
    now = datetime.now()

    timestamp = now.strftime(
        "%Y-%m-%d_%H-%M-%S"
    )

    incident_id = (
        f"INC-{now.strftime('%Y-%m-%d-%H%M%S')}"
    )

    video_h264 = (
        f"event_{timestamp}.h264"
    )

    event_type = get_event_type(result)

    os.system(
        f"rpicam-vid --vflip "
        f"-o {video_h264} "
        f"-t 5000 "
        f"> /dev/null 2>&1 &"
    )

    face_image = None

    if has_face(result):
        print("👤 تم اكتشاف وجه")

        face_image = (
            f"face_{timestamp}.jpg"
        )

        os.system(
            f"cp current.jpg {face_image}"
        )

    # إرسال البيانات فوراً بموقع افتراضي
    # بدون انتظار GPS
    incident_data = {
        "incidentId": incident_id,
        "type": event_type.upper(),
        "status": "ACTIVE",
        "timestamp": now.isoformat(),
        "location": DEFAULT_LOCATION,
        "deviceId": DEVICE_ID,
        "detectedFaces": []
    }

    threading.Thread(
        target=send_incident_data_instant,
        args=(
            incident_id,
            incident_data
        ),
        daemon=True
    ).start()

    # تحديث الموقع الحقيقي لاحقاً
    threading.Thread(
        target=update_location_background,
        args=(incident_id,),
        daemon=True
    ).start()

    # معالجة الفيديو بالخلفية
    threading.Thread(
        target=process_video_background,
        args=(
            video_h264,
            incident_id,
            incident_data,
            face_image
        ),
        daemon=True
    ).start()

    with open("events.txt", "a") as f:
        f.write(
            f"{timestamp} | "
            f"{incident_id} | "
            f"{event_type} | "
            f"{result}\n"
        )


# ========== الحلقة الرئيسية ==========

def main():
    print("🚀 النظام شغال...")

    # حالة الجهاز بالخلفية
    threading.Thread(
        target=set_device_status,
        args=("active",),
        daemon=True
    ).start()

    while True:

        # مراقبة النت والانتقال للشريحة
        threading.Thread(
            target=check_and_switch_network,
            daemon=True
        ).start()

        # رفع الأحداث المحفوظة
        threading.Thread(
            target=upload_offline_queue,
            daemon=True
        ).start()

        capture_image()

        try:
            result = send_to_ai()

        except Exception as e:
            print(
                f"⚠️ فشل الاتصال بالـ AI: {e}"
            )

            result = {}

        if is_danger(result):

            event_type = get_event_type(
                result
            )

            print(
                f"🚨 {event_type.upper()}!"
            )

            # المكالمة أولاً
            threading.Thread(
                target=make_call,
                daemon=True
            ).start()

            # باقي العمليات بالتوازي
            threading.Thread(
                target=play_alarm,
                daemon=True
            ).start()

            save_event(result)

            time.sleep(10)

        else:
            print("✅ طبيعي")

        time.sleep(3)


if __name__ == "__main__":
    main()
```

