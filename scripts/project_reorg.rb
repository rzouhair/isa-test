#!/usr/bin/env ruby
# Moves Phase 2 + Phase 3 file references into their matching subgroups so
# Xcode's Navigator mirrors the on-disk folder structure.
# Creates intermediate PBXGroup nodes as needed. Idempotent.
require 'xcodeproj'

PROJECT_PATH = File.expand_path('../examprep.xcodeproj', __dir__)
REPO_ROOT = File.expand_path('..', __dir__)

FILES_TO_REORG = [
  # Phase 2
  'examprep/Domain/Models/UserExamProfile.swift',
  'examprep/Domain/Models/QuestionAttempt.swift',
  'examprep/Domain/Models/PracticeSession.swift',
  'examprep/Domain/Models/SessionAnswer.swift',
  'examprep/Domain/Models/BookmarkedQuestion.swift',
  'examprep/Domain/Models/StudyStreak.swift',
  'examprep/Domain/Models/Content/ContentDTOs.swift',
  'examprep/Data/DB/GRDBContentDatabase.swift',
  'examprep/Domain/Protocols/ContentRepositoryProtocol.swift',
  'examprep/Domain/Protocols/UserProgressRepositoryProtocol.swift',
  'examprep/Domain/Protocols/StatsRepositoryProtocol.swift',
  'examprep/Data/Repositories/GRDBContentRepository.swift',
  'examprep/Data/Repositories/SwiftDataUserProgressRepository.swift',
  'examprep/Data/Repositories/DefaultStatsRepository.swift',
  'examprep/Resources/exam_content.sqlite',
  # Phase 3
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

project = Xcodeproj::Project.open(PROJECT_PATH)
examprep_group = project.main_group['examprep'] or abort "examprep group missing"

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

  # rel is 'examprep/A/B/C.swift' — target group chain = A/B
  components = rel.split('/')
  components.shift                # drop leading 'examprep'
  components.pop                  # drop filename
  target_group = components.empty? ? examprep_group : find_or_create_group(examprep_group, components)

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
