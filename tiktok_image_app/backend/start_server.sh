#!/bin/bash
# Script to start the Flask API server

cd "$(dirname "$0")"
source venv/bin/activate
echo "Starting TikTok Image Generator API Server..."
echo "Server will be available at http://localhost:8000"
echo "Press Ctrl+C to stop"
python3 api_server.py

