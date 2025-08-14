#!/bin/bash

# Script to fix Xcode 16 kernel SDK version mismatch issues
echo "Fixing Xcode 16 kernel SDK version mismatch issues..."

# Clean Flutter build
cd ..
flutter clean

# Remove Pods directory and Podfile.lock
rm -rf Pods
rm -f Podfile.lock

# Update CocoaPods
gem install cocoapods

# Install pods with updated configuration
pod install

# Set required build settings for Xcode 16
xcodeproj="Runner.xcodeproj"
if [ -d "$xcodeproj" ]; then
  echo "Updating Xcode project settings..."
  
  # Create a temporary Ruby script to modify the Xcode project
  cat > update_project.rb << 'EOL'
  require 'xcodeproj'
  
  project_path = ARGV[0]
  project = Xcodeproj::Project.open(project_path)
  
  project.targets.each do |target|
    target.build_configurations.each do |config|
      # Disable user script sandboxing (required for Xcode 16)
      config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
      
      # Set deployment target
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
      
      # Ensure proper architecture settings
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
      
      # Add any other necessary settings for Xcode 16
      config.build_settings['DEAD_CODE_STRIPPING'] = 'YES'
      config.build_settings['ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES'] = 'YES'
    end
  end
  
  project.save
  puts "Project settings updated successfully!"
EOL
  
  # Run the Ruby script to update the project
  ruby update_project.rb "$xcodeproj"
  
  # Clean up
  rm update_project.rb
else
  echo "Error: Xcode project not found!"
  exit 1
fi

echo "Fix completed. Please try building your project again."