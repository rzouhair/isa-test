#!/usr/bin/env ruby
# Moves Phase 2 + Phase 3 file references into their matching subgroups so
# Xcode's Navigator mirrors the on-disk folder structure.
# Creates intermediate PBXGroup nodes as needed. Idempotent.
require 'xcodeproj'

PROJECT_PATH = File.expand_path('../isaprep.xcodeproj', __dir__)
REPO_ROOT = File.expand_path('..', __dir__)

FILES_TO_REORG = [
  # Phase 2
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
  'isaprep/Resources/exam_content.sqlite',
  # Phase 3
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

project = Xcodeproj::Project.open(PROJECT_PATH)
isaprep_group = project.main_group['isaprep'] or abort "isaprep group missing"

# Walk or create the subgroup chain `components` beneath `root`.
def find_or_create_group(root, components)
  components.inject(root) do |grp, name|
    found = grp.children.find { |c| c.is_a?(Xcodeproj::Project::Object::PBXGroup) && c.display_name == name }
    found || grp.new_group(name, name)
  end
end

moved = 0
FILES_TO_REORG.each do |rel|
  abs = File.join(REPO_ROOT, rel)
  ref = project.files.find { |f| f.real_path.to_s == abs }
  next unless ref

  # rel is 'isaprep/A/B/C.swift' — target group chain = A/B
  components = rel.split('/')
  components.shift                # drop leading 'isaprep'
  components.pop                  # drop filename
  target_group = components.empty? ? isaprep_group : find_or_create_group(isaprep_group, components)

  next if ref.parent == target_group

  # Move by detaching from current parent and attaching to the target group.
  ref.parent&.children&.delete(ref)
  target_group << ref

  # Normalize path representation so Xcode shows just the basename in the
  # navigator (path is relative to the containing group's folder on disk).
  ref.name = File.basename(rel)
  ref.path = File.basename(rel)
  ref.source_tree = '<group>'

  puts "~ #{rel} -> #{components.join('/')}"
  moved += 1
end

project.save
puts "OK: reorganized #{moved} file references."
