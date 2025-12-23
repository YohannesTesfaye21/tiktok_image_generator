#!/bin/bash
# Build script with logging for Render deployment

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
python3 --version
echo ""

echo "📦 pip version:"
pip --version
echo ""

echo "📥 Installing requirements..."
pip install -r requirements.txt
echo ""

echo "✅ Installation complete!"
echo ""

echo "🔍 Verifying gunicorn installation:"
if command -v gunicorn &> /dev/null; then
    echo "✅ gunicorn is installed!"
    gunicorn --version
else
    echo "❌ gunicorn NOT FOUND!"
    echo "🔍 Checking pip list:"
    pip list | grep -i gunicorn || echo "gunicorn not in pip list"
    echo "🔍 Checking Python path:"
    python3 -c "import sys; print('\n'.join(sys.path))"
    exit 1
fi

echo ""
echo "=========================================="
echo "✅ BUILD SCRIPT COMPLETED SUCCESSFULLY"
echo "=========================================="

