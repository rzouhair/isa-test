#!/usr/bin/env ruby
# Repairs post-rename residue in examprep.xcodeproj:
#   - removes examprep/Info.plist from test targets' Copy-Resources phase
#   - sets PRODUCT_NAME to examprep across all configurations
require 'xcodeproj'

PROJECT_PATH = File.expand_path('../examprep.xcodeproj', __dir__)

project = Xcodeproj::Project.open(PROJECT_PATH)

# 1. Drop stale Info.plist from test-target resources phases.
project.targets.each do |target|
  next unless target.name.end_with?('Tests')
  phase = target.resources_build_phase
  phase.files.dup.each do |bf|
    name = bf.file_ref&.path.to_s
    if name.end_with?('Info.plist')
      phase.remove_build_file(bf)
      puts "- resources: Info.plist from #{target.name}"
    end
  end
end

# 2. Force PRODUCT_NAME = examprep on the main app target.
app_target = project.targets.find { |t| t.name == 'examprep' }
app_target&.build_configurations&.each do |cfg|
  old = cfg.build_settings['PRODUCT_NAME']
  if old != 'examprep'
    cfg.build_settings['PRODUCT_NAME'] = 'examprep'
    puts "~ PRODUCT_NAME: #{old.inspect} -> \"examprep\" (#{cfg.name})"
  end
end

# 3. Fix stale TEST_HOST / BUNDLE_LOADER / TEST_TARGET_NAME in test targets.
project.targets.each do |target|
  next unless target.name.end_with?('Tests')
  target.build_configurations.each do |cfg|
    %w[TEST_HOST BUNDLE_LOADER].each do |key|
      value = cfg.build_settings[key]
      next unless value.is_a?(String) && value.include?('Poke')
      fixed = value.gsub('Poke.app/Poke', 'examprep.app/examprep').gsub('Poke', 'examprep')
      cfg.build_settings[key] = fixed
      puts "~ #{key}: #{value} -> #{fixed} (#{target.name}/#{cfg.name})"
    end

    # TEST_TARGET_NAME must point to the actual host target (examprep) so
    # Xcode wires module + framework resolution correctly.
    current = cfg.build_settings['TEST_TARGET_NAME']
    if current && current != 'examprep'
      cfg.build_settings['TEST_TARGET_NAME'] = 'examprep'
      puts "~ TEST_TARGET_NAME: #{current.inspect} -> \"examprep\" (#{target.name}/#{cfg.name})"
    end
  end
end

project.save
puts "OK: wrote #{PROJECT_PATH}"
