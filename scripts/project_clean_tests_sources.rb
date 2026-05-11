#!/usr/bin/env ruby
# Removes app-target source files duplicated into isaprepTests Sources phase.
# Root cause: legacy project setup registered every app file in the tests
# target too. Modern XCTest bundles only compile their own test files and
# reach app internals via `@testable import isaprep`.
require 'xcodeproj'

PROJECT_PATH = File.expand_path('../isaprep.xcodeproj', __dir__)
project = Xcodeproj::Project.open(PROJECT_PATH)

app_target = project.targets.find { |t| t.name == 'isaprep' }
tests_target = project.targets.find { |t| t.name == 'isaprepTests' }
abort 'targets missing' unless app_target && tests_target

app_paths = app_target.source_build_phase.files_references.map { |r| r.real_path.to_s }.to_set

removed = 0
tests_target.source_build_phase.files.dup.each do |bf|
  ref = bf.file_ref
  next unless ref
  # Keep only files that physically live under isaprepTests/.
  path = ref.real_path.to_s
  if path.include?('/isaprepTests/') && path.end_with?('.swift')
    next
  end
  # Everything else is an app-source leak. Drop from the build phase
  # (keep the PBXFileReference — it's the app target's).
  tests_target.source_build_phase.remove_build_file(bf)
  removed += 1
end

project.save
puts "OK: stripped #{removed} entries from isaprepTests Sources phase."
