# Android Connection Guide

## Quick Fix for Android Emulator

The Android emulator should work automatically with `10.0.2.2:8000`. 

### Steps:

1. **Make sure backend is running:**
   ```bash
   cd backend
   source venv/bin/activate
   python api_server.py
   ```
   
   You should see: `Running on http://0.0.0.0:8000`

2. **Test connection from emulator:**
   - The app will automatically test connection before generating
   - If it fails, check the error message

## For Physical Android Device

If you're using a **physical Android device**, you need to use your computer's IP address instead of `10.0.2.2`.

### Find Your Computer's IP:

**Mac/Linux:**
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

**Windows:**
```cmd
ipconfig
```
Look for "IPv4 Address" under your WiFi adapter.

### Update the Code:

1. Open `lib/services/image_generator_service.dart`

2. Find this line (around line 13):
   ```dart
   return 'http://10.0.2.2:8000';  // Android emulator
   ```

3. Replace with your IP (example):
   ```dart
   return 'http://192.168.1.100:8000';  // Your computer's IP
   ```

4. **Important:** Make sure:
   - Your phone and computer are on the **same WiFi network**
   - Your computer's firewall allows connections on port 8000
   - The backend server is running

### Alternative: Use Custom URL

You can also set a custom URL programmatically:

```dart
ImageGeneratorService.customServerUrl = "http://YOUR_IP:8000";
```

## Troubleshooting

### "Cannot connect to server" Error

1. **Check if backend is running:**
   ```bash
   curl http://localhost:8000/api/health
   ```
   Should return: `{"status":"ok"}`

2. **For Emulator:**
   - Make sure backend is running on your computer
   - Backend should bind to `0.0.0.0` (which it does by default)

3. **For Physical Device:**
   - Check both devices are on same WiFi
   - Try pinging your computer from the phone
   - Check firewall settings
   - Make sure backend binds to `0.0.0.0:8000` (not just `localhost`)

### Backend Not Accessible?

The backend should already be configured to accept connections from any interface (`0.0.0.0`). If not, check `backend/api_server.py`:

```python
app.run(host='0.0.0.0', port=8000, debug=True)
```

This allows connections from any network interface, including the Android emulator.

## Quick Test

1. Start backend: `cd backend && python api_server.py`
2. From Android emulator/device, the app will test connection automatically
3. If connection test passes, you can generate images!

