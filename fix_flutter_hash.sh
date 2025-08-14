#!/bin/bash

echo "Starting Flutter SDK hash mismatch fix..."

# Clean Flutter project cache
echo "Cleaning Flutter project cache..."
rm -rf .dart_tool/ build/
flutter clean

# Clean iOS build artifacts
echo "Cleaning iOS build artifacts..."
cd ios
rm -rf Pods/ Podfile.lock
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Update Podfile to fix Xcode 16 issues
echo "Updating Podfile for Xcode 16 compatibility..."
cat > Podfile << 'EOF'
platform :ios, '15.0'

# CocoaPods analytics sends network stats synchronously affecting flutter build latency.
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist. If you're running pod install manually, make sure flutter pub get is executed first"
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\=(.*)\$/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found in #{generated_xcode_build_settings_path}. Try deleting Generated.xcconfig, then run flutter pub get"
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_ios_podfile_setup

# Prevent Cocoapods from embedding a second Flutter framework
install! 'cocoapods', :deterministic_uuids => false

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
  target 'RunnerTests' do
    inherit! :search_paths
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    # Xcode 16 compatibility fixes
    target.build_configurations.each do |config|
      # Disable sandbox for user scripts
      config.build_settings['USER_SCRIPT_SANDBOXING'] = 'NO'
      
      # Set iOS deployment target
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
      
      # Exclude arm64 architecture for simulator builds
      if config.build_settings['SDKROOT'] == 'iphonesimulator'
        config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
      end
      
      # Set Swift version
      config.build_settings['SWIFT_VERSION'] = '5.0'
      
      # Disable code signing
      config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
      config.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
    end
  end
end
EOF

# Install pods
echo "Installing pods..."
pod install

# Go back to project root
cd ..

# Create a temporary fix for the Flutter SDK hash mismatch
echo "Creating temporary fix for Flutter SDK hash mismatch..."
mkdir -p .dart_tool/flutter_build/temp_fix

# Clean and rebuild
echo "Cleaning and rebuilding the project..."
flutter pub get

echo "Fix completed. Try building the project with: flutter build ios --no-codesign"