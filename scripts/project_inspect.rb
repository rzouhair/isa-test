#!/usr/bin/env ruby
# Diagnostic: print build-settings for test targets.
require 'xcodeproj'

PROJECT_PATH = File.expand_path('../isaprep.xcodeproj', __dir__)
project = Xcodeproj::Project.open(PROJECT_PATH)

keys = %w[TEST_HOST BUNDLE_LOADER TEST_TARGET_NAME PRODUCT_NAME TARGETED_DEVICE_FAMILY MACH_O_TYPE PRODUCT_BUNDLE_IDENTIFIER]

project.targets.each do |target|
  puts "=== #{target.name} ==="
  target.build_configurations.each do |cfg|
    puts "  [#{cfg.name}]"
    keys.each do |k|
      value = cfg.build_settings[k]
      puts "    #{k} = #{value.inspect}" unless value.nil?
    end
  end
end
