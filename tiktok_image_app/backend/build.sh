#!/bin/bash
# Build script with logging for Render deployment
# This script should be in the same directory as requirements.txt

set -e  # Exit on error

echo "=========================================="
echo "🔨 BUILD SCRIPT STARTING"
echo "=========================================="

echo "📂 Current directory:"
pwd
echo ""

echo "📋 Listing files in current directory:"
ls -la
echo ""

echo "📄 Checking if requirements.txt exists:"
if [ -f "requirements.txt" ]; then
    echo "✅ requirements.txt found!"
    echo "📝 Contents of requirements.txt:"
    cat requirements.txt
    echo ""
else
    echo "❌ requirements.txt NOT FOUND!"
    echo "🔍 Searching for requirements.txt:"
    find . -name "requirements.txt" 2>/dev/null || echo "No requirements.txt found anywhere"
    exit 1
fi

echo "🐍 Python version:"
python3 --version || python --version
echo ""

echo "📦 pip version:"
pip --version || pip3 --version
echo ""

echo "📥 Installing requirements..."
pip install -r requirements.txt || pip3 install -r requirements.txt
echo ""

echo "✅ Installation complete!"
echo ""

echo "🔍 Verifying gunicorn installation:"
if command -v gunicorn &> /dev/null; then
    echo "✅ gunicorn is installed!"
    gunicorn --version
elif python3 -m gunicorn --version &> /dev/null; then
    echo "✅ gunicorn is installed (via python3 -m)!"
    python3 -m gunicorn --version
else
    echo "❌ gunicorn NOT FOUND!"
    echo "🔍 Checking pip list:"
    pip list | grep -i gunicorn || pip3 list | grep -i gunicorn || echo "gunicorn not in pip list"
    echo "🔍 Checking Python path:"
    python3 -c "import sys; print('\n'.join(sys.path))" || python -c "import sys; print('\n'.join(sys.path))"
    echo "🔍 Trying to install gunicorn directly:"
    pip install gunicorn || pip3 install gunicorn
    echo "🔍 Verifying again:"
    command -v gunicorn && gunicorn --version || echo "Still not found"
fi

echo ""
echo "=========================================="
echo "✅ BUILD SCRIPT COMPLETED SUCCESSFULLY"
echo "=========================================="

