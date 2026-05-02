#!/usr/bin/env ruby
# Removes the GRDB.swift SPM package + product dependencies from examprep.xcodeproj.
# Used after we switched Phase 2 to raw sqlite3 (no external dep) because the
# GRDB package's submodule clone was unreliable in this environment.
require 'xcodeproj'

PROJECT_PATH = File.expand_path('../examprep.xcodeproj', __dir__)
GRDB_URL = 'https://github.com/groue/GRDB.swift'

project = Xcodeproj::Project.open(PROJECT_PATH)

# 1. Remove product dependencies + their framework build files.
project.targets.each do |target|
  deps = target.package_product_dependencies.select { |d| d.product_name == 'GRDB' }
  next if deps.empty?

  deps.each do |dep|
    target.frameworks_build_phase.files.dup.each do |bf|
      if bf.respond_to?(:product_ref) && bf.product_ref == dep
        target.frameworks_build_phase.remove_build_file(bf)
        puts "- framework build file: GRDB (#{target.name})"
      end
    end
    target.package_product_dependencies.delete(dep)
    dep.remove_from_project
    puts "- product dep: GRDB (#{target.name})"
  end
end

# 2. Remove the package reference itself.
project.root_object.package_references.dup.each do |ref|
  if ref.respond_to?(:repositoryURL) && ref.repositoryURL == GRDB_URL
    project.root_object.package_references.delete(ref)
    ref.remove_from_project
    puts "- SPM package: #{GRDB_URL}"
  end
end

project.save
puts "OK: wrote #{PROJECT_PATH}"
