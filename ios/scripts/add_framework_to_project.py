#!/usr/bin/env python3
"""
Script to add xcframework to Xcode project.pbxproj file
Directly modifies the project file to include framework references
"""

import os
import sys
import re
import uuid
from pathlib import Path

def generate_uuid():
    """Generate a 24-character hex UUID like Xcode uses"""
    return uuid.uuid4().hex[:24].upper()

def find_frameworks(frameworks_dir):
    """Find all xcframework bundles"""
    if not os.path.exists(frameworks_dir):
        return []
    
    frameworks = []
    for item in os.listdir(frameworks_dir):
        if item.endswith('.xcframework'):
            frameworks.append(item)
    return frameworks

def add_framework_to_project(project_path, framework_name):
    """Add framework references to project.pbxproj"""
    
    with open(project_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Check if framework already exists
    if framework_name in content:
        print(f"  Framework '{framework_name}' already in project, skipping")
        return False
    
    print(f"  Adding '{framework_name}' to project...")
    
    # Generate UUIDs for various references
    fileref_uuid = generate_uuid()
    buildfile_uuid = generate_uuid()
    embed_uuid = generate_uuid()
    
    framework_basename = framework_name.replace('.xcframework', '')
    
    # 1. Add PBXFileReference
    fileref_section = re.search(r'/\* Begin PBXFileReference section \*/', content)
    if fileref_section:
        insert_pos = fileref_section.end()
        fileref_entry = f"\n\t\t{fileref_uuid} /* {framework_name} */ = {{isa = PBXFileReference; lastKnownFileType = wrapper.xcframework; name = {framework_name}; path = Frameworks/{framework_name}; sourceTree = \"<group>\"; }};"
        content = content[:insert_pos] + fileref_entry + content[insert_pos:]
        print(f"    ✓ Added PBXFileReference: {fileref_uuid}")
    
    # 2. Add to PBXBuildFile section
    buildfile_section = re.search(r'/\* Begin PBXBuildFile section \*/', content)
    if buildfile_section:
        insert_pos = buildfile_section.end()
        buildfile_entry = f"\n\t\t{buildfile_uuid} /* {framework_name} in Frameworks */ = {{isa = PBXBuildFile; fileRef = {fileref_uuid} /* {framework_name} */; }};"
        content = content[:insert_pos] + buildfile_entry + content[insert_pos:]
        print(f"    ✓ Added PBXBuildFile: {buildfile_uuid}")
    
    # 3. Add to Embed Frameworks PBXBuildFile
    embed_build = f"\n\t\t{embed_uuid} /* {framework_name} in Embed Frameworks */ = {{isa = PBXBuildFile; fileRef = {fileref_uuid} /* {framework_name} */; settings = {{ATTRIBUTES = (CodeSignOnCopy, RemoveHeadersOnCopy, ); }}; }};"
    if buildfile_section:
        insert_pos = buildfile_section.end()
        content = content[:insert_pos] + embed_build + content[insert_pos:]
        print(f"    ✓ Added Embed PBXBuildFile: {embed_uuid}")
    
    # 4. Add to PBXFrameworksBuildPhase files array
    framework_phase = re.search(r'97C146EB1CF9000F007C117D /\* Frameworks \*/ = \{[^}]*isa = PBXFrameworksBuildPhase;[^}]*files = \([^)]*\)', content)
    if framework_phase:
        files_match = re.search(r'files = \(([^)]*)\)', framework_phase.group())
        if files_match:
            files_pos = framework_phase.start() + files_match.end() - 1
            files_entry = f"\n\t\t\t\t{buildfile_uuid} /* {framework_name} in Frameworks */,"
            content = content[:files_pos] + files_entry + content[files_pos:]
            print(f"    ✓ Added to Frameworks build phase")
    
    # 5. Add to Embed Frameworks PBXCopyFilesBuildPhase
    embed_phase = re.search(r'9705A1C41CF9048500538489 /\* Embed Frameworks \*/ = \{[^}]*isa = PBXCopyFilesBuildPhase;[^}]*files = \([^)]*\)', content)
    if embed_phase:
        files_match = re.search(r'files = \(([^)]*)\)', embed_phase.group())
        if files_match:
            files_pos = embed_phase.start() + files_match.end() - 1
            files_entry = f"\n\t\t\t\t{embed_uuid} /* {framework_name} in Embed Frameworks */,"
            content = content[:files_pos] + files_entry + content[files_pos:]
            print(f"    ✓ Added to Embed Frameworks phase")
    
    # 6. Create or update Frameworks group
    # First, try to find existing Frameworks group
    frameworks_group = re.search(r'([A-F0-9]{24}) /\* Frameworks \*/ = \{[^}]*isa = PBXGroup;[^}]*children = \([^)]*\)', content)
    
    if frameworks_group:
        group_uuid = frameworks_group.group(1)
        children_match = re.search(r'children = \(([^)]*)\)', frameworks_group.group())
        if children_match:
            children_pos = frameworks_group.start() + children_match.end() - 1
            child_entry = f"\n\t\t\t\t{fileref_uuid} /* {framework_name} */,"
            content = content[:children_pos] + child_entry + content[children_pos:]
            print(f"    ✓ Added to Frameworks group")
    else:
        # Create Frameworks group if it doesn't exist
        print("    ! Frameworks group not found, may need manual intervention")
    
    # 7. Update FRAMEWORK_SEARCH_PATHS in build settings
    # This is more complex as there are multiple build configurations
    for config_name in ['Debug', 'Release', 'Profile']:
        config_pattern = rf'97C147[0-9A-F]{{2}}1CF9000F007C117D /\* {config_name} \*/ = \{{[^}}]*buildSettings = \{{[^}}]*\}};'
        config_match = re.search(config_pattern, content, re.DOTALL)
        
        if config_match:
            config_section = config_match.group()
            if 'FRAMEWORK_SEARCH_PATHS' not in config_section:
                # Add FRAMEWORK_SEARCH_PATHS
                settings_end = re.search(r'buildSettings = \{', config_section)
                if settings_end:
                    abs_pos = config_match.start() + settings_end.end()
                    search_path_entry = '\n\t\t\t\tFRAMEWORK_SEARCH_PATHS = (\n\t\t\t\t\t"$(inherited)",\n\t\t\t\t\t"$(PROJECT_DIR)/Frameworks",\n\t\t\t\t);'
                    content = content[:abs_pos] + search_path_entry + content[abs_pos:]
                    print(f"    ✓ Added FRAMEWORK_SEARCH_PATHS to {config_name}")
    
    # Write modified content
    with open(project_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    return True

def main():
    script_dir = Path(__file__).parent
    ios_dir = script_dir.parent
    frameworks_dir = ios_dir / 'Frameworks'
    project_path = ios_dir / 'Runner.xcodeproj' / 'project.pbxproj'
    
    print("=== Adding Frameworks to Xcode Project ===")
    print(f"Project: {project_path}")
    print(f"Frameworks dir: {frameworks_dir}")
    
    if not project_path.exists():
        print(f"Error: Project file not found at {project_path}")
        sys.exit(1)
    
    if not frameworks_dir.exists():
        print(f"Error: Frameworks directory not found at {frameworks_dir}")
        sys.exit(1)
    
    frameworks = find_frameworks(frameworks_dir)
    
    if not frameworks:
        print(f"Error: No xcframework files found in {frameworks_dir}")
        sys.exit(1)
    
    print(f"\nFound {len(frameworks)} framework(s):")
    for fw in frameworks:
        print(f"  - {fw}")
    
    # Backup original project file
    backup_path = str(project_path) + '.backup'
    import shutil
    shutil.copy(project_path, backup_path)
    print(f"\n✓ Created backup: {backup_path}")
    
    print("\nAdding frameworks to project...")
    modified = False
    for framework in frameworks:
        if add_framework_to_project(project_path, framework):
            modified = True
    
    if modified:
        print("\n✅ Project file updated successfully!")
        print("\nFrameworks will be embedded in the app bundle during build.")
    else:
        print("\n✓ No changes needed, frameworks already configured.")
    
    return 0

if __name__ == '__main__':
    sys.exit(main())
