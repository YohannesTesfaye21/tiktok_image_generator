# 🚀 Deploy Backend to Render.com

This guide will help you deploy the TikTok Image Generator API to Render.com (free tier).

## 📋 Prerequisites

1. **GitHub Account** (free)
2. **Render Account** (free) - Sign up at https://render.com
3. **TikTok API Credentials** (already have these)

## 🔧 Step 1: Prepare Your Code

The backend is already prepared with:
- ✅ `render.yaml` - Render deployment configuration
- ✅ `requirements.txt` - Python dependencies
- ✅ `tiktok_image_generator.py` - Copied to backend directory
- ✅ Updated `api_server.py` - Works in deployed environment

## 📤 Step 2: Push to GitHub

1. **Initialize Git** (if not already done):
   ```bash
   cd /Users/m2pro/Desktop/tiktok/tiktok_image_app/backend
   git init
   git add .
   git commit -m "Initial commit: TikTok Image Generator API"
   ```

2. **Create GitHub Repository**:
   - Go to https://github.com/new
   - Create a new repository (e.g., `tiktok-image-api`)
   - **Don't** initialize with README

3. **Push to GitHub**:
   ```bash
   git remote add origin https://github.com/YOUR_USERNAME/tiktok-image-api.git
   git branch -M main
   git push -u origin main
   ```

## 🌐 Step 3: Deploy to Render

1. **Go to Render Dashboard**:
   - Visit https://dashboard.render.com
   - Sign up or log in

2. **Create New Web Service**:
   - Click "New +" → "Web Service"
   - Connect your GitHub account (if not already connected)
   - Select your repository: `tiktok-image-api`
   - Click "Connect"

3. **Configure Service**:
   - **Name**: `tiktok-image-api` (or any name you prefer)
   - **Region**: Choose closest to you (e.g., `Oregon (US West)`)
   - **Branch**: `main`
   - **Root Directory**: `backend` (important!)
   - **Runtime**: `Python 3`
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `gunicorn api_server:app`

4. **Set Environment Variables**:
   Click "Advanced" → "Add Environment Variable":
   
   ```
   TIKTOK_CLIENT_KEY = awexlvyuyzcvvisy
   TIKTOK_CLIENT_SECRET = ElIE4xE3HofwInmig2QC0ZaXU3YF7mSL
   TIKTOK_REDIRECT_URI = https://YOUR_SERVICE_NAME.onrender.com/auth/callback
   ```
   
   ⚠️ **Important**: Replace `YOUR_SERVICE_NAME` with your actual Render service name!

5. **Deploy**:
   - Click "Create Web Service"
   - Render will build and deploy your app
   - Wait 5-10 minutes for first deployment

## ✅ Step 4: Get Your Backend URL

After deployment:
- Your backend URL will be: `https://YOUR_SERVICE_NAME.onrender.com`
- Example: `https://tiktok-image-api.onrender.com`

## 📱 Step 5: Update Flutter App

Update the backend URL in your Flutter app:

1. **Open** `lib/services/image_generator_service.dart`
2. **Find** the `baseUrl`:
   ```dart
   static const String baseUrl = 'http://localhost:8000';
   ```
3. **Replace** with your Render URL:
   ```dart
   static const String baseUrl = 'https://YOUR_SERVICE_NAME.onrender.com';
   ```

4. **Also update** `lib/services/tiktok_service.dart`:
   ```dart
   static const String baseUrl = 'https://YOUR_SERVICE_NAME.onrender.com';
   ```

## 🔄 Step 6: Update TikTok OAuth Redirect URI

1. **Go to TikTok Developer Portal**:
   - Visit https://developers.tiktok.com
   - Go to your app settings

2. **Update Redirect URI**:
   - Add: `https://YOUR_SERVICE_NAME.onrender.com/auth/callback`
   - Save changes

## 🧪 Step 7: Test Deployment

1. **Test API Health**:
   - Visit: `https://YOUR_SERVICE_NAME.onrender.com/api/health` (if you add this endpoint)
   - Or test with your Flutter app

2. **Test Image Generation**:
   - Open Flutter app
   - Generate an image
   - Should work from anywhere now!

## ⚠️ Important Notes

### Free Tier Limitations:
- **Spins down after 15 minutes** of inactivity
- **First request** after spin-down takes ~30 seconds (cold start)
- **750 hours/month** free (enough for 24/7 if active)

### To Keep Service Active:
- Use a service like UptimeRobot (free) to ping your API every 10 minutes
- Or upgrade to paid plan for always-on

### Troubleshooting:

**Build Fails:**
- Check Render logs: Dashboard → Your Service → Logs
- Ensure `requirements.txt` has all dependencies
- Check Python version compatibility

**Import Errors:**
- Verify `tiktok_image_generator.py` is in `backend/` directory
- Check file paths in `api_server.py`

**OAuth Not Working:**
- Verify `TIKTOK_REDIRECT_URI` matches your Render URL
- Check TikTok Developer Portal redirect URI settings

## 🎉 Success!

Your backend is now deployed and accessible from anywhere!

**Next Steps:**
- Test the Flutter app with the new backend URL
- Monitor Render dashboard for usage
- Set up uptime monitoring (optional)

