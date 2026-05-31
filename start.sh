#!/bin/bash

echo "Starting FoodApp Setup & Run Script..."

echo "1. Setting up Backend..."
cd backend || exit

# Install PHP dependencies
composer install

# Setup environment if it doesn't exist
if [ ! -f .env ]; then
    echo "Creating .env file and generating app key..."
    cp .env.example .env
    php artisan key:generate
fi

# Run migrations and create storage symlink
echo "Running database migrations..."
php artisan migrate --force

echo "Creating storage symlink..."
php artisan storage:link

echo "2. Setting up Frontend..."
cd ../frontend || exit

# Install Node dependencies
npm install

echo "3. Starting Servers..."
echo "Backend will run at: http://127.0.0.1:8000"
echo "Frontend will run at: http://localhost:5173"
echo "Press Ctrl+C to stop both servers."
echo "------------------------------------------------"

# Go to backend and start server in background
cd ../backend || exit
php artisan serve &
BACKEND_PID=$!

# Go to frontend and start server in background
cd ../frontend || exit
npm run dev &
FRONTEND_PID=$!

# Trap Ctrl+C (SIGINT) and kill both processes
trap "echo -e '\nStopping servers...'; kill $BACKEND_PID $FRONTEND_PID; exit 0" SIGINT SIGTERM EXIT

# Wait for background processes to finish
wait
