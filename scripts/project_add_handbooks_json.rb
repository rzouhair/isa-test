#!/usr/bin/env ruby
# frozen_string_literal: true
# Adds isaprep/Resources/handbooks.json to Resources group + Copy-Bundle-Resources
# build phase for the `isaprep` target. Idempotent.

require 'xcodeproj'

PROJECT_PATH = File.expand_path('../isaprep.xcodeproj', __dir__)
RESOURCE_REL = 'handbooks.json'
TARGET_NAME  = 'isaprep'

project = Xcodeproj::Project.open(PROJECT_PATH)

main_group = project.main_group['isaprep'] || project.main_group
resources_group = main_group['Resources']
abort 'Resources group not found under isaprep/' unless resources_group

file_ref = resources_group.files.find { |f| f.path == RESOURCE_REL }
file_ref ||= resources_group.new_reference(RESOURCE_REL)

target = project.targets.find { |t| t.name == TARGET_NAME }
abort "Target #{TARGET_NAME} not found" unless target

phase = target.resources_build_phase
unless phase.files_references.include?(file_ref)
  phase.add_file_reference(file_ref, true)
  puts "Added #{RESOURCE_REL} to #{TARGET_NAME} resources phase"
else
  puts "#{RESOURCE_REL} already in #{TARGET_NAME} resources phase"
end

project.save
puts 'Saved project.'
