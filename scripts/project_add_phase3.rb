#!/usr/bin/env ruby
# Registers Phase 3 files into examprep.xcodeproj.
# Idempotent — safe to re-run.
require 'xcodeproj'

PROJECT_PATH = File.expand_path('../examprep.xcodeproj', __dir__)
REPO_ROOT = File.expand_path('..', __dir__)

NEW_SWIFT_FILES = [
  'examprep/Presentation/Components/CountdownView.swift',
  'examprep/Presentation/Components/ScoreGaugeView.swift',
  'examprep/Presentation/Components/ProgressRingView.swift',
  'examprep/Presentation/Components/AnswerOptionButton.swift',
  'examprep/Presentation/Components/QuestionCardView.swift',
  'examprep/Presentation/Components/CategoryProgressRow.swift',
  'examprep/Features/LicenseSelect/LicenseSelectView.swift',
  'examprep/Features/StateSelect/StateSelectView.swift',
  'examprep/Features/CategoryList/CategoryListView.swift',
  'examprep/Features/PracticeTestList/PracticeTestListView.swift',
  'examprep/Features/QuizSession/QuizSessionView.swift',
  'examprep/Features/QuizSession/QuizSessionViewModel.swift',
  'examprep/Features/QuizResult/QuizResultView.swift',
  'examprep/Features/ReviewSession/ReviewSessionView.swift',
  'examprep/Features/Home/HomeViewModel.swift',
].freeze

NEW_TEST_FILES = [
  'examprepTests/QuizSessionViewModelTests.swift',
].freeze

project = Xcodeproj::Project.open(PROJECT_PATH)
app_target = project.targets.find { |t| t.name == 'examprep' } or abort 'no examprep target'
test_target = project.targets.find { |t| t.name == 'examprepTests' } or abort 'no examprepTests target'
main_group = project.main_group['examprep'] || project.main_group
tests_group = project.main_group['examprepTests'] || project.main_group

def add_source(project, rel, group, target)
  abs = File.join(REPO_ROOT, rel)
  abort "missing file: #{abs}" unless File.exist?(abs)
  ref = project.files.find { |f| f.real_path.to_s == abs } || group.new_file(abs)
  phase = target.source_build_phase
  unless phase.files_references.include?(ref)
    phase.add_file_reference(ref, true)
    puts "+ sources: #{rel} (#{target.name})"
  end
end

NEW_SWIFT_FILES.each { |rel| add_source(project, rel, main_group, app_target) }
NEW_TEST_FILES.each  { |rel| add_source(project, rel, tests_group, test_target) }

project.save
puts "OK: wrote #{PROJECT_PATH}"
