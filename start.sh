#!/bin/bash

# Configuration
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$PROJECT_DIR/backend"
FRONTEND_DIR="$PROJECT_DIR/medicoplilot"
VENV_DIR="$PROJECT_DIR/.venv"

echo "==============================================="
echo "        Starting MediCoPilot...                "
echo "==============================================="

# Function to handle cleanup on script exit
cleanup() {
    echo ""
    echo "Stopping services..."
    
    # Kill frontend if started (flutter run might spawn subprocesses)
    if [ -n "$FRONTEND_PID" ]; then
        echo "Stopping frontend (PID: $FRONTEND_PID)..."
        kill -TERM $FRONTEND_PID 2>/dev/null
    fi

    # Kill backend
    if [ -n "$BACKEND_PID" ]; then
        echo "Stopping backend (PID: $BACKEND_PID)..."
        kill -TERM $BACKEND_PID 2>/dev/null
    fi
    
    echo "Services stopped."
    exit 0
}

# Register cleanup function to handle CTRL+C and termination signals
trap cleanup SIGINT SIGTERM EXIT

# 1. Start the Backend
echo "-> Starting Backend (FastAPI)..."
cd "$BACKEND_DIR" || { echo "Error: Backend directory not found!"; exit 1; }

# Activate virtual environment if it exists
if [ -d "$VENV_DIR" ]; then
    echo "   Using virtual environment at $VENV_DIR"
    source "$VENV_DIR/bin/activate"
else
    echo "   Warning: No virtual environment found at $VENV_DIR"
fi

# Run backend in background
python main.py &
BACKEND_PID=$!
echo "   Backend started with PID $BACKEND_PID"

# Wait a moment to ensure backend initializes
sleep 2

# Check if backend is still running
if ! kill -0 $BACKEND_PID 2>/dev/null; then
    echo "Error: Backend failed to start!"
    exit 1
fi

# 2. Start the Frontend
echo "-> Starting Frontend (Flutter)..."
cd "$FRONTEND_DIR" || { echo "Error: Frontend directory not found!"; cleanup; exit 1; }

# Run flutter linux app (assuming linux desktop app)
# We run this in the foreground so the script stays alive and we see flutter logs
flutter run -d linux
