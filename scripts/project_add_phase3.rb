#!/usr/bin/env ruby
# Registers Phase 3 files into isaprep.xcodeproj.
# Idempotent — safe to re-run.
require 'xcodeproj'

PROJECT_PATH = File.expand_path('../isaprep.xcodeproj', __dir__)
REPO_ROOT = File.expand_path('..', __dir__)

NEW_SWIFT_FILES = [
  'isaprep/Presentation/Components/CountdownView.swift',
  'isaprep/Presentation/Components/ScoreGaugeView.swift',
  'isaprep/Presentation/Components/ProgressRingView.swift',
  'isaprep/Presentation/Components/AnswerOptionButton.swift',
  'isaprep/Presentation/Components/QuestionCardView.swift',
  'isaprep/Presentation/Components/CategoryProgressRow.swift',
  'isaprep/Features/LicenseSelect/LicenseSelectView.swift',
  'isaprep/Features/StateSelect/StateSelectView.swift',
  'isaprep/Features/CategoryList/CategoryListView.swift',
  'isaprep/Features/PracticeTestList/PracticeTestListView.swift',
  'isaprep/Features/QuizSession/QuizSessionView.swift',
  'isaprep/Features/QuizSession/QuizSessionViewModel.swift',
  'isaprep/Features/QuizResult/QuizResultView.swift',
  'isaprep/Features/ReviewSession/ReviewSessionView.swift',
  'isaprep/Features/Home/HomeViewModel.swift',
].freeze

NEW_TEST_FILES = [
  'isaprepTests/QuizSessionViewModelTests.swift',
].freeze

project = Xcodeproj::Project.open(PROJECT_PATH)
app_target = project.targets.find { |t| t.name == 'isaprep' } or abort 'no isaprep target'
test_target = project.targets.find { |t| t.name == 'isaprepTests' } or abort 'no isaprepTests target'
main_group = project.main_group['isaprep'] || project.main_group
tests_group = project.main_group['isaprepTests'] || project.main_group

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
