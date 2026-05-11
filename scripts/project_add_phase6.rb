#!/usr/bin/env ruby
# Registers Phase 6 onboarding files.
require 'xcodeproj'

PROJECT_PATH = File.expand_path('../isaprep.xcodeproj', __dir__)
REPO_ROOT = File.expand_path('..', __dir__)

NEW_APP_FILES = [
  'isaprep/Features/OnboardingFlow/OnboardingHeroView.swift',
  'isaprep/Features/OnboardingFlow/OnboardingValueProp1View.swift',
  'isaprep/Features/OnboardingFlow/OnboardingValueProp2View.swift',
  'isaprep/Features/OnboardingFlow/OnboardingValueProp3View.swift',
  'isaprep/Features/OnboardingFlow/OnboardingLicenseStepView.swift',
  'isaprep/Features/OnboardingFlow/OnboardingStateStepView.swift',
  'isaprep/Features/OnboardingFlow/OnboardingExamDateStepView.swift',
  'isaprep/Features/OnboardingFlow/OnboardingNotificationsStepView.swift',
].freeze

project = Xcodeproj::Project.open(PROJECT_PATH)
app_target = project.targets.find { |t| t.name == 'isaprep' } or abort 'isaprep target missing'
isaprep_group = project.main_group['isaprep'] or abort 'isaprep group missing'

def find_or_create_group(root, components)
  components.inject(root) do |grp, name|
    found = grp.children.find { |c| c.is_a?(Xcodeproj::Project::Object::PBXGroup) && c.display_name == name }
    found || grp.new_group(name, name)
  end
end

def add(project, rel, root_group, target)
  abs = File.join(REPO_ROOT, rel)
  abort "missing: #{abs}" unless File.exist?(abs)

  components = rel.split('/')
  components.shift
  components.pop
  target_group = components.empty? ? root_group : find_or_create_group(root_group, components)

  ref = project.files.find { |f| f.real_path.to_s == abs }
  if ref.nil?
    ref = target_group.new_file(abs)
    ref.name = File.basename(rel)
    ref.path = File.basename(rel)
    ref.source_tree = '<group>'
    puts "+ file: #{rel}"
  elsif ref.parent != target_group
    ref.parent&.children&.delete(ref)
    target_group << ref
    ref.name = File.basename(rel)
    ref.path = File.basename(rel)
    ref.source_tree = '<group>'
    puts "~ moved: #{rel}"
  end

  phase = target.source_build_phase
  unless phase.files_references.include?(ref)
    phase.add_file_reference(ref, true)
    puts "+ sources: #{rel} (#{target.name})"
  end
end

NEW_APP_FILES.each { |rel| add(project, rel, isaprep_group, app_target) }

project.save
puts "OK"
