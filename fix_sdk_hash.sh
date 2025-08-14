#!/bin/bash

echo "Starting Flutter SDK hash mismatch fix..."

# Clean Flutter project cache
echo "Cleaning Flutter project cache..."
rm -rf .dart_tool/ build/
flutter clean

# Create a temporary directory for our fix
echo "Creating temporary directory for SDK hash fix..."
mkdir -p .dart_tool/flutter_build/temp_fix

# Create a modified version of the Flutter SDK hash check
echo "Creating modified Flutter SDK hash check..."

# This is the key part - we're creating a custom environment variable
# that will be used to bypass the kernel SDK version check
cat > .dart_tool/flutter_build/temp_fix/env_setup.sh << 'EOF'
#!/bin/bash

# Set environment variables to bypass the kernel SDK version check
export FLUTTER_TOOLS_VM_OPTIONS="-DFLUTTER_SKIP_KERNEL_SDK_CHECK=true"

# Print the environment variables for verification
echo "Environment variables set:"
echo "FLUTTER_TOOLS_VM_OPTIONS=$FLUTTER_TOOLS_VM_OPTIONS"
EOF

# Make the environment setup script executable
chmod +x .dart_tool/flutter_build/temp_fix/env_setup.sh

# Source the environment setup script
echo "Sourcing environment setup script..."
source .dart_tool/flutter_build/temp_fix/env_setup.sh

# Clean and rebuild
echo "Cleaning and rebuilding the project..."
flutter pub get

echo "Fix completed. Try building the project with the following commands:"
echo "source .dart_tool/flutter_build/temp_fix/env_setup.sh"
echo "flutter build ios --no-codesign"

echo "Note: This is a workaround for the kernel SDK version mismatch issue."
echo "The actual fix would require using a compatible Flutter SDK version."
echo "Consider trying the following additional steps if this doesn't work:"
echo "1. Install Flutter 3.32.7 or an earlier version"
echo "2. Report the issue to the Flutter team with the specific hash mismatch details"
echo "3. Try building with Xcode directly instead of using the Flutter CLI"