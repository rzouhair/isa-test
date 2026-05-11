#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Registers Phase 2 assets into isaprep.xcodeproj:
#   - Adds GRDB.swift SPM package dependency + product
#   - Registers new Swift source files in the `isaprep` target's Sources phase
#   - Registers exam_content.sqlite as a Copy-Bundle-Resources entry
#
# Idempotent — safe to re-run. Does not remove anything.
#
# Run with gem load paths explicit (Ruby 2.6 system interpreter):
#   ruby -I... scripts/project_add.rb
# The wrapper script below (bash) computes the -I flags automatically.

require 'xcodeproj'

PROJECT_PATH = File.expand_path('../isaprep.xcodeproj', __dir__)
REPO_ROOT = File.expand_path('..', __dir__)

NEW_SWIFT_FILES = [
  'isaprep/Domain/Models/UserExamProfile.swift',
  'isaprep/Domain/Models/QuestionAttempt.swift',
  'isaprep/Domain/Models/PracticeSession.swift',
  'isaprep/Domain/Models/SessionAnswer.swift',
  'isaprep/Domain/Models/BookmarkedQuestion.swift',
  'isaprep/Domain/Models/StudyStreak.swift',
  'isaprep/Domain/Models/Content/ContentDTOs.swift',
  'isaprep/Data/DB/GRDBContentDatabase.swift',
  'isaprep/Domain/Protocols/ContentRepositoryProtocol.swift',
  'isaprep/Domain/Protocols/UserProgressRepositoryProtocol.swift',
  'isaprep/Domain/Protocols/StatsRepositoryProtocol.swift',
  'isaprep/Data/Repositories/GRDBContentRepository.swift',
  'isaprep/Data/Repositories/SwiftDataUserProgressRepository.swift',
  'isaprep/Data/Repositories/DefaultStatsRepository.swift',
].freeze

NEW_TEST_FILES = [
  'isaprepTests/ContentRepositoryTests.swift',
  'isaprepTests/UserProgressRepositoryTests.swift',
  'isaprepTests/StatsRepositoryTests.swift',
].freeze

RESOURCE_FILES = [
  'isaprep/Resources/exam_content.sqlite',
].freeze

GRDB_PACKAGE_URL = 'https://github.com/groue/GRDB.swift'
GRDB_MIN_VERSION = '6.0.0'
GRDB_PRODUCT = 'GRDB'

def main
  project = Xcodeproj::Project.open(PROJECT_PATH)
  app_target = project.targets.find { |t| t.name == 'isaprep' } or abort 'isaprep target not found'
  test_target = project.targets.find { |t| t.name == 'isaprepTests' } or abort 'isaprepTests target not found'

  add_grdb_package!(project, app_target, test_target)

  # Source files live under the 'isaprep' group; tests under 'isaprepTests'.
  main_group = project.main_group['isaprep'] || project.main_group
  tests_group = project.main_group['isaprepTests'] || project.main_group

  NEW_SWIFT_FILES.each { |rel| ensure_source_in_target(project, rel, main_group, app_target) }
  NEW_TEST_FILES.each { |rel| ensure_source_in_target(project, rel, tests_group, test_target) }
  RESOURCE_FILES.each { |rel| ensure_resource_in_target(project, rel, main_group, app_target) }

  project.save
  puts "OK: wrote #{PROJECT_PATH}"
end

def ensure_source_in_target(project, rel_path, group, target)
  abs_path = File.join(REPO_ROOT, rel_path)
  abort "Missing source file: #{abs_path}" unless File.exist?(abs_path)

  file_ref = project.files.find { |f| f.real_path.to_s == abs_path }
  unless file_ref
    file_ref = group.new_file(abs_path)
    puts "+ file ref: #{rel_path}"
  end

  sources = target.source_build_phase
  unless sources.files_references.include?(file_ref)
    sources.add_file_reference(file_ref, true)
    puts "+ sources: #{rel_path} (#{target.name})"
  end
end

def ensure_resource_in_target(project, rel_path, group, target)
  abs_path = File.join(REPO_ROOT, rel_path)
  abort "Missing resource: #{abs_path}" unless File.exist?(abs_path)

  file_ref = project.files.find { |f| f.real_path.to_s == abs_path }
  unless file_ref
    file_ref = group.new_file(abs_path)
    puts "+ file ref: #{rel_path}"
  end

  resources = target.resources_build_phase
  unless resources.files_references.include?(file_ref)
    resources.add_file_reference(file_ref, true)
    puts "+ resources: #{rel_path}"
  end
end

def add_grdb_package!(project, *targets)
  existing_pkg = project.root_object.package_references.find do |p|
    p.respond_to?(:repositoryURL) && p.repositoryURL == GRDB_PACKAGE_URL
  end

  package = existing_pkg || begin
    pkg = project.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
    pkg.repositoryURL = GRDB_PACKAGE_URL
    pkg.requirement = { 'kind' => 'upToNextMajorVersion', 'minimumVersion' => GRDB_MIN_VERSION }
    project.root_object.package_references << pkg
    puts "+ SPM package: #{GRDB_PACKAGE_URL} (#{GRDB_MIN_VERSION}+)"
    pkg
  end

  targets.each do |target|
    already = target.package_product_dependencies.any? { |d| d.product_name == GRDB_PRODUCT }
    next if already

    dep = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
    dep.package = package
    dep.product_name = GRDB_PRODUCT
    target.package_product_dependencies << dep

    build_file = project.new(Xcodeproj::Project::Object::PBXBuildFile)
    build_file.product_ref = dep
    target.frameworks_build_phase.files << build_file

    puts "+ product dep: #{GRDB_PRODUCT} (#{target.name})"
  end
end

main
