#!/usr/bin/env ruby
# One-off fix: LearnLevelServiceTests.swift was registered with path=basename
# anchored at project root. Existing test files use path=isaprepTests/<name>.
# Align with that convention.
require 'xcodeproj'

PROJECT_PATH = File.expand_path('../isaprep.xcodeproj', __dir__)
project = Xcodeproj::Project.open(PROJECT_PATH)

project.files.each do |ref|
  base = ref.path.to_s
  next unless base == 'LearnLevelServiceTests.swift'
  ref.path = 'isaprepTests/LearnLevelServiceTests.swift'
  ref.name = 'LearnLevelServiceTests.swift'
  ref.source_tree = '<group>'
  puts "~ fixed path: #{ref.path}"
end

project.save
puts "OK: wrote #{PROJECT_PATH}"
