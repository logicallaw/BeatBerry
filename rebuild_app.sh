#!/bin/bash

# Define app path
APP_PATH="BeatBerry.app"
RESOURCES_PATH="$APP_PATH/Contents/Resources"

echo "Updating BeatBerry.app..."

# Check if App exists
if [ ! -d "$APP_PATH" ]; then
    echo "Error: $APP_PATH not found!"
    exit 1
fi

# Copy files
echo "Copying source files to $RESOURCES_PATH..."
cp gui.py "$RESOURCES_PATH/"
cp main.py "$RESOURCES_PATH/"
cp start.sh "$RESOURCES_PATH/"
cp environment.yml "$RESOURCES_PATH/"

# Make sure scripts are executable
chmod +x "$RESOURCES_PATH/start.sh"

echo "Done! BeatBerry.app has been updated."
