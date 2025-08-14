#!/usr/bin/env ruby

require 'xcodeproj'

project_path = 'Runner.xcodeproj'
puts "Opening project at #{project_path}..."

begin
  project = Xcodeproj::Project.open(project_path)
  
  puts "Updating build settings for Xcode 16 compatibility..."
  
  project.targets.each do |target|
    puts "Processing target: #{target.name}"
    
    target.build_configurations.each do |config|
      puts "  Updating configuration: #{config.name}"
      
      # Disable user script sandboxing (required for Xcode 16)
      config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
      
      # Set deployment target
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
      
      # Ensure proper architecture settings
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
      
      # Add any other necessary settings for Xcode 16
      config.build_settings['DEAD_CODE_STRIPPING'] = 'YES'
      
      # Fix for kernel SDK version mismatch
      config.build_settings['SWIFT_VERSION'] = '5.0'
    end
  end
  
  project.save
  puts "Project settings updated successfully!"
rescue => e
  puts "Error: #{e.message}"
  exit 1
end

puts "Fix completed. Please try building your project again."