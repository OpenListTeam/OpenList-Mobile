#!/usr/bin/env ruby
# Script to add OpenList framework to Xcode project
# Uses xcodeproj gem for proper project file manipulation

require 'xcodeproj'

# Paths
script_dir = File.dirname(__FILE__)
ios_dir = File.dirname(script_dir)
project_path = File.join(ios_dir, 'Runner.xcodeproj')
frameworks_dir = File.join(ios_dir, 'Frameworks')

puts "=== Adding OpenList Framework to Xcode Project ==="
puts "Project: #{project_path}"
puts "Frameworks: #{frameworks_dir}"

# Check if frameworks directory exists
unless Dir.exist?(frameworks_dir)
  puts "Error: Frameworks directory not found at #{frameworks_dir}"
  exit 1
end

# Find xcframework files
xcframeworks = Dir.glob(File.join(frameworks_dir, '*.xcframework'))

if xcframeworks.empty?
  puts "Error: No .xcframework files found in #{frameworks_dir}"
  exit 1
end

puts "Found #{xcframeworks.size} framework(s):"
xcframeworks.each { |fw| puts "  - #{File.basename(fw)}" }

# Open Xcode project
project = Xcodeproj::Project.open(project_path)

# Get the main target (Runner)
target = project.targets.find { |t| t.name == 'Runner' }

unless target
  puts "Error: Could not find Runner target"
  exit 1
end

puts "Target found: #{target.name}"

# Get or create Frameworks group
frameworks_group = project.main_group['Frameworks'] || project.main_group.new_group('Frameworks')

# Process each xcframework
xcframeworks.each do |xcframework_path|
  framework_name = File.basename(xcframework_path)
  
  puts "\nProcessing: #{framework_name}"
  
  # Create relative path
  relative_path = "Frameworks/#{framework_name}"
  
  # Check if framework already added
  existing = frameworks_group.files.find { |f| f.path == relative_path }
  
  if existing
    puts "  Framework already added, skipping..."
    next
  end
  
  # Add framework file reference
  file_ref = frameworks_group.new_file(relative_path)
  
  # Add to frameworks build phase
  target.frameworks_build_phase.add_file_reference(file_ref)
  puts "  ✓ Added to Frameworks Build Phase"
  
  # Add to embed frameworks build phase
  embed_phase = target.build_phases.find { |phase| phase.is_a?(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase) && phase.name == 'Embed Frameworks' }
  
  if embed_phase
    build_file = embed_phase.add_file_reference(file_ref)
    build_file.settings = { 'ATTRIBUTES' => ['CodeSignOnCopy', 'RemoveHeadersOnCopy'] }
    puts "  ✓ Added to Embed Frameworks Phase"
  else
    puts "  Warning: Embed Frameworks phase not found"
  end
end

# Update build settings
puts "\nUpdating build settings..."

target.build_configurations.each do |config|
  # Add framework search path
  search_paths = config.build_settings['FRAMEWORK_SEARCH_PATHS'] || ['$(inherited)']
  search_paths = [search_paths] unless search_paths.is_a?(Array)
  
  unless search_paths.include?('$(PROJECT_DIR)/Frameworks')
    search_paths << '$(PROJECT_DIR)/Frameworks'
    config.build_settings['FRAMEWORK_SEARCH_PATHS'] = search_paths
    puts "  ✓ Added framework search path for #{config.name}"
  end
  
  # Ensure LD_RUNPATH_SEARCH_PATHS includes @executable_path/Frameworks
  runpath = config.build_settings['LD_RUNPATH_SEARCH_PATHS'] || []
  runpath = [runpath] unless runpath.is_a?(Array)
  
  unless runpath.include?('@executable_path/Frameworks')
    runpath << '@executable_path/Frameworks'
    config.build_settings['LD_RUNPATH_SEARCH_PATHS'] = runpath
    puts "  ✓ Updated LD_RUNPATH_SEARCH_PATHS for #{config.name}"
  end
end

# Save project
project.save
puts "\n✅ Project saved successfully!"
puts "\nFramework integration complete. The framework will be embedded in the app bundle."
