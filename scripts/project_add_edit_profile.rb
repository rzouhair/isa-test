#!/usr/bin/env ruby
# Registers EditLicenseView + EditStateView into examprep target.
require 'xcodeproj'

PROJECT_PATH = File.expand_path('../examprep.xcodeproj', __dir__)
REPO_ROOT = File.expand_path('..', __dir__)

NEW_FILES = [
  'examprep/Features/Settings/EditLicenseView.swift',
  'examprep/Features/Settings/EditStateView.swift',
].freeze

project = Xcodeproj::Project.open(PROJECT_PATH)
app_target = project.targets.find { |t| t.name == 'examprep' } or abort 'examprep missing'
root = project.main_group['examprep'] or abort 'examprep group missing'

def find_or_create_group(root, components)
  components.inject(root) do |grp, name|
    found = grp.children.find { |c| c.is_a?(Xcodeproj::Project::Object::PBXGroup) && c.display_name == name }
    found || grp.new_group(name, name)
  end
end

NEW_FILES.each do |rel|
  abs = File.join(REPO_ROOT, rel)
  abort "missing: #{abs}" unless File.exist?(abs)
  components = rel.split('/'); components.shift; components.pop
  target_group = components.empty? ? root : find_or_create_group(root, components)
  ref = project.files.find { |f| f.real_path.to_s == abs } || begin
    r = target_group.new_file(abs)
    r.name = File.basename(rel); r.path = File.basename(rel); r.source_tree = '<group>'
    puts "+ file: #{rel}"
    r
  end
  phase = app_target.source_build_phase
  unless phase.files_references.include?(ref)
    phase.add_file_reference(ref, true)
    puts "+ sources: #{rel}"
  end
end

project.save
puts "OK"
