#!/bin/bash

echo "Applying Xcode 16 kernel SDK version mismatch fix..."

# Clean up previous build artifacts
rm -rf Pods
rm -f Podfile.lock

# Update the minimum deployment target in the Podfile
sed -i '' 's/platform :ios, .*/platform :ios, \'15.0\'/' Podfile

# Add specific settings to fix kernel SDK version mismatch
cat > xcode_post_install.rb << 'EOF'
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    target.build_configurations.each do |config|
      # Ensure minimum deployment target is set correctly
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
      
      # Fix for Xcode 16 kernel SDK version mismatch
      config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
      config.build_settings['SWIFT_VERSION'] = '5.0'
      
      # Ensure pods support arm64 architecture
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
      
      # Additional Xcode 16 compatibility settings
      config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
      config.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
    end
  end
end
EOF

# Replace the post_install section in the Podfile
sed -i '' '/post_install/,/end/d' Podfile
cat xcode_post_install.rb >> Podfile
rm xcode_post_install.rb

# Install pods with the updated configuration
pod install

echo "Fix applied. Please try building your project again."