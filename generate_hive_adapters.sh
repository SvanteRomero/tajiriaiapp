#!/bin/bash

# Exit on error
set -e

echo "Starting Hive adapter generation..."

# Check if flutter is available
if ! command -v flutter &> /dev/null; then
    echo "Error: Flutter is not installed or not in PATH"
    exit 1
fi

# Check if the pubspec.yaml exists
if [ ! -f "pubspec.yaml" ]; then
    echo "Error: pubspec.yaml not found. Are you in the right directory?"
    exit 1
fi

# Clean up any existing generated files
echo "Cleaning up existing generated files..."
find . -name "*.g.dart" -type f -delete

# Run the build_runner
echo "Generating Hive adapters..."
if flutter pub run build_runner build --delete-conflicting-outputs; then
    echo "Successfully generated Hive adapters"
    
    # Verify the generated files
    if [ -f "lib/models/hive/transaction_model.g.dart" ]; then
        echo "Verified: transaction_model.g.dart was generated"
    else
        echo "Error: transaction_model.g.dart was not generated"
        exit 1
    fi
else
    echo "Error: Failed to generate Hive adapters"
    exit 1
fi

echo "Hive adapter generation completed successfully"
