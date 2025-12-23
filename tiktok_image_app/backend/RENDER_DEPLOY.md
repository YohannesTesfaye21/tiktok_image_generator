# 🚀 Quick Render.com Deployment Guide

## Your GitHub Repo
**Repository**: `YohannesTesfaye21/tiktok_image_generator`  
**Branch**: `image_generator` (or `main`)  
**Backend Path**: `tiktok_image_app/backend`

## 📋 Step-by-Step Deployment

### 1. Push Deployment Files to GitHub

```bash
cd /Users/m2pro/Desktop/tiktok/tiktok_image_app/backend
git add render.yaml DEPLOYMENT.md .gitignore tiktok_image_generator.py api_server.py requirements.txt image_to_video.py tiktok_api.py tiktok_config.py
git commit -m "Add Render.com deployment configuration"
git push origin image_generator
```

### 2. Deploy to Render.com

1. **Go to Render Dashboard**: https://dashboard.render.com
   - Sign up or log in (free account)

2. **Create New Web Service**:
   - Click **"New +"** → **"Web Service"**
   - Connect GitHub (if not already connected)
   - Select repository: **`YohannesTesfaye21/tiktok_image_generator`**

3. **Configure Service**:
   - **Name**: `tiktok-image-api` (or any name)
   - **Region**: Choose closest (e.g., `Oregon (US West)`)
   - **Branch**: `image_generator` (or `main` if that's your main branch)
   - **Root Directory**: `tiktok_image_app/backend` ⚠️ **IMPORTANT!**
   - **Runtime**: `Python 3`
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `gunicorn api_server:app`

4. **Set Environment Variables**:
   Click **"Advanced"** → **"Add Environment Variable"**:
   
   ```
   TIKTOK_CLIENT_KEY = awexlvyuyzcvvisy
   TIKTOK_CLIENT_SECRET = ElIE4xE3HofwInmig2QC0ZaXU3YF7mSL
   TIKTOK_REDIRECT_URI = https://YOUR_SERVICE_NAME.onrender.com/auth/callback
   ```
   
   ⚠️ **Replace `YOUR_SERVICE_NAME`** with your actual Render service name!

5. **Deploy**:
   - Click **"Create Web Service"**
   - Wait 5-10 minutes for first deployment
   - Your URL will be: `https://YOUR_SERVICE_NAME.onrender.com`

### 3. Update TikTok OAuth Redirect URI

1. Go to **TikTok Developer Portal**: https://developers.tiktok.com
2. Open your app settings
3. Add redirect URI: `https://YOUR_SERVICE_NAME.onrender.com/auth/callback`
4. Save changes

### 4. Update Flutter App

Update backend URL in these files:

**`lib/services/image_generator_service.dart`**:
```dart
static const String baseUrl = 'https://YOUR_SERVICE_NAME.onrender.com';
```

**`lib/services/tiktok_service.dart`**:
```dart
static const String baseUrl = 'https://YOUR_SERVICE_NAME.onrender.com';
```

## ✅ Test Your Deployment

1. Visit: `https://YOUR_SERVICE_NAME.onrender.com/api/generate` (should show error, but confirms server is running)
2. Test from Flutter app - generate an image
3. Test TikTok OAuth flow

## ⚠️ Free Tier Notes

- **Spins down** after 15 minutes of inactivity
- **First request** after spin-down takes ~30 seconds (cold start)
- **750 hours/month** free (enough for 24/7 if active)

### Keep Service Active (Optional):
Use **UptimeRobot** (free) to ping your API every 10 minutes:
- URL: `https://YOUR_SERVICE_NAME.onrender.com`
- Interval: 10 minutes

## 🐛 Troubleshooting

**Build Fails?**
- Check Render logs: Dashboard → Your Service → Logs
- Verify `requirements.txt` has all dependencies
- Check Python version (3.12.0)

**Import Errors?**
- Verify `tiktok_image_generator.py` is in `backend/` directory
- Check file paths in `api_server.py`

**OAuth Not Working?**
- Verify `TIKTOK_REDIRECT_URI` matches your Render URL exactly
- Check TikTok Developer Portal redirect URI settings
- Ensure HTTPS (not HTTP) in redirect URI

## 🎉 Success!

Your backend is now live and accessible from anywhere!

