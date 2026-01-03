import os
import random
import subprocess
from flask import Flask, request, jsonify, render_template_string

app = Flask(__name__)

# --- CONFIGURATION ---
BASE_DIR = r"C:\kiosk_project"
SUMATRA_PATH = os.path.join(BASE_DIR, "SumatraPDF.exe")
UPLOAD_FOLDER = os.path.join(BASE_DIR, "temp_files")
EDGE_PATH = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

# Ensure directories exist
if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)

# Global OTP
current_otp = str(random.randint(1000, 9999))

# --- KIOSK UI (Web Dashboard) ---
@app.route('/')
def index():
    return render_template_string("""
        <!DOCTYPE html>
        <html>
        <head>
            <meta http-equiv="refresh" content="3">
            <title>Print Connect Terminal</title>
            <style>
                body { background:#0F172A; color:#22D3EE; text-align:center; font-family: 'Segoe UI', sans-serif; padding-top:100px; }
                .card { border:4px solid #22D3EE; display:inline-block; padding:50px; border-radius:40px; background:#1E293B; box-shadow: 0 0 60px rgba(34, 211, 238, 0.3); }
                h1 { letter-spacing:8px; margin:0; font-size: 2.5em; }
                .otp { font-size:140px; font-weight:bold; margin:30px 0; letter-spacing:20px; color: white; text-shadow: 0 0 30px #22D3EE; }
                .status { color:#4ADE80; font-weight:bold; font-size:24px; animation: blink 1.5s infinite; }
                @keyframes blink { 0% { opacity:1; } 50% { opacity:0.3; } 100% { opacity:1; } }
            </style>
        </head>
        <body>
            <div class="card">
                <h1>PRINT CONNECT</h1>
                <p style="color:white; opacity:0.7;">ENTER THIS OTP ON YOUR MOBILE</p>
                <div class="otp">{{ otp }}</div>
                <p class="status">● KIOSK READY</p>
            </div>
        </body>
        </html>
    """, otp=current_otp)

# --- API: PROCESS PRINT JOB ---
@app.route('/process_print', methods=['POST'])
def process():
    global current_otp
    try:
        user_otp = request.form.get('otp')
        # 'files' matches your Flutter ApiService key
        uploaded_files = request.files.getlist('files')

        print(f"Incoming Request: OTP={user_otp}, Files={len(uploaded_files)}")

        # 1. Verify OTP
        if user_otp != current_otp:
            print(f"❌ Access Denied: Invalid OTP {user_otp}")
            return jsonify({"error": "Invalid OTP"}), 401

        if not uploaded_files:
            return jsonify({"error": "No files uploaded"}), 400

        for f in uploaded_files:
            # Save file temporarily
            safe_name = f"job_{random.randint(1000, 9999)}.pdf"
            file_path = os.path.join(UPLOAD_FOLDER, safe_name)
            f.save(file_path)
            
            print(f"Processing Job: {file_path}")

            # STEP 1: Attempt Silent Print via SumatraPDF
            try:
                # -print-to-default: Sends to Windows default printer
                subprocess.run([
                    SUMATRA_PATH, 
                    "-print-to-default", 
                    "-silent", 
                    "-exit-on-print", 
                    file_path
                ], check=True, timeout=20)
                print("✅ Printed via SumatraPDF")
            
            except Exception as e:
                print(f"⚠️ Sumatra failed: {e}. Falling back to Edge...")
                
                # STEP 2: Fallback via Edge Kiosk Mode
                subprocess.run([
                    EDGE_PATH, 
                    '--kiosk-printing', 
                    '--print-to-default', 
                    os.path.abspath(file_path)
                ], shell=True)
                print("✅ Printed via Edge Fallback")

        # 2. Reset OTP for security after successful print
        current_otp = str(random.randint(1000, 9999))
        print(f"✨ Job Finished. New OTP: {current_otp}")
        
        return jsonify({"message": "Success", "new_otp": current_otp}), 200

    except Exception as e:
        print(f"🔥 Server Error: {e}")
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    # host='0.0.0.0' allows connections from Ngrok or Local Network
    app.run(host='0.0.0.0', port=5000, debug=False)