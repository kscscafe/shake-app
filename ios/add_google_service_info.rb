#!/usr/bin/env ruby
# Adds GoogleService-Info.plist to the Runner target's resources build phase.
# Idempotent: safe to run multiple times.

require 'xcodeproj'

project_path = File.expand_path('Runner.xcodeproj', __dir__)
plist_relative = 'Runner/GoogleService-Info.plist'
plist_abs = File.expand_path(plist_relative, __dir__)

abort("plist not found at #{plist_abs}") unless File.exist?(plist_abs)

project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'Runner' } || abort('Runner target not found')

runner_group = project.main_group['Runner'] || abort('Runner group not found')

# Check if reference already exists (by path) anywhere in the project
existing_ref = project.files.find { |f| f.path == 'GoogleService-Info.plist' || f.path&.end_with?('/GoogleService-Info.plist') }

if existing_ref.nil?
  existing_ref = runner_group.new_reference('GoogleService-Info.plist')
  puts "Added file reference under Runner group"
else
  puts "File reference already exists: #{existing_ref.path}"
end

# Ensure it's in the Resources build phase of the Runner target
resources_phase = target.resources_build_phase
already_in_phase = resources_phase.files_references.include?(existing_ref)

if already_in_phase
  puts 'Already in Resources build phase — nothing to do'
else
  resources_phase.add_file_reference(existing_ref, true)
  puts 'Added to Resources build phase'
end

project.save
puts "Saved #{project_path}"
