#!/usr/bin/env python3
"""
Add xcframework reference to Xcode project file (project.pbxproj)
This script directly modifies the pbxproj file to add framework references
"""

import os
import sys
import re
import uuid

def generate_uuid():
    """Generate a 24-character hex string similar to Xcode UUIDs"""
    return uuid.uuid4().hex[:24].upper()

def find_xcframeworks(frameworks_dir):
    """Find all xcframework directories"""
    if not os.path.exists(frameworks_dir):
        return []
    
    frameworks = []
    for item in os.listdir(frameworks_dir):
        if item.endswith('.xcframework'):
            frameworks.append(item)
    return frameworks

def read_pbxproj(pbxproj_path):
    """Read pbxproj file"""
    with open(pbxproj_path, 'r', encoding='utf-8') as f:
        return f.read()

def write_pbxproj(pbxproj_path, content):
    """Write pbxproj file"""
    with open(pbxproj_path, 'w', encoding='utf-8') as f:
        f.write(content)

def add_framework_to_project(pbxproj_content, framework_name):
    """Add framework references to pbxproj content"""
    
    # Generate UUIDs for the framework
    file_ref_uuid = generate_uuid()
    build_file_uuid = generate_uuid()
    embed_file_uuid = generate_uuid()
    
    # Check if framework already exists
    if framework_name in pbxproj_content:
        print(f"⚠️  Framework {framework_name} already exists in project")
        return pbxproj_content
    
    print(f"Adding {framework_name} to project...")
    
    # 1. Add PBXBuildFile section for Frameworks build phase
    build_file_section = f"\t\t{build_file_uuid} /* {framework_name} in Frameworks */ = {{isa = PBXBuildFile; fileRef = {file_ref_uuid} /* {framework_name} */; }};\n"
    
    # Find PBXBuildFile section and add our entry
    pbxproj_content = re.sub(
        r'(/\* Begin PBXBuildFile section \*/\n)',
        r'\1' + build_file_section,
        pbxproj_content,
        count=1
    )
    
    # 2. Add PBXBuildFile section for Embed Frameworks build phase
    embed_file_section = f"\t\t{embed_file_uuid} /* {framework_name} in Embed Frameworks */ = {{isa = PBXBuildFile; fileRef = {file_ref_uuid} /* {framework_name} */; settings = {{ATTRIBUTES = (CodeSignOnCopy, RemoveHeadersOnCopy, ); }}; }};\n"
    
    # Add embed file entry
    pbxproj_content = re.sub(
        r'(/\* Begin PBXBuildFile section \*/\n)',
        r'\1' + embed_file_section,
        pbxproj_content,
        count=1
    )
    
    # 3. Add PBXFileReference section
    file_ref_section = f"\t\t{file_ref_uuid} /* {framework_name} */ = {{isa = PBXFileReference; lastKnownFileType = wrapper.xcframework; name = {framework_name}; path = Frameworks/{framework_name}; sourceTree = \"<group>\"; }};\n"
    
    # Find PBXFileReference section and add our entry
    pbxproj_content = re.sub(
        r'(/\* End PBXContainerItemProxy section \*/\n)',
        r'\1\n/* Begin PBXFileReference section */\n' + file_ref_section if '/* Begin PBXFileReference section */' not in pbxproj_content else '',
        pbxproj_content,
        count=1
    )
    
    if '/* Begin PBXFileReference section */' in pbxproj_content:
        pbxproj_content = re.sub(
            r'(/\* Begin PBXFileReference section \*/\n)',
            r'\1' + file_ref_section,
            pbxproj_content,
            count=1
        )
    
    # 4. Add to Frameworks build phase (PBXFrameworksBuildPhase)
    frameworks_phase_pattern = r'(97C146EB1CF9000F007C117D /\* Frameworks \*/ = \{[^}]+files = \(\n)'
    frameworks_entry = f"\t\t\t\t{build_file_uuid} /* {framework_name} in Frameworks */,\n"
    
    pbxproj_content = re.sub(
        frameworks_phase_pattern,
        r'\1' + frameworks_entry,
        pbxproj_content,
        count=1
    )
    
    # 5. Add to Embed Frameworks phase (PBXCopyFilesBuildPhase)
    embed_phase_pattern = r'(9705A1C41CF9048500538489 /\* Embed Frameworks \*/ = \{[^}]+files = \(\n)'
    embed_entry = f"\t\t\t\t{embed_file_uuid} /* {framework_name} in Embed Frameworks */,\n"
    
    pbxproj_content = re.sub(
        embed_phase_pattern,
        r'\1' + embed_entry,
        pbxproj_content,
        count=1
    )
    
    # 6. Create or update Frameworks group
    # First, check if Frameworks group exists
    if 'name = Frameworks;' not in pbxproj_content:
        # Need to create Frameworks group
        frameworks_group_uuid = generate_uuid()
        frameworks_group = f"""
\t\t{frameworks_group_uuid} /* Frameworks */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{file_ref_uuid} /* {framework_name} */,
\t\t\t);
\t\t\tname = Frameworks;
\t\t\tpath = \"\";
\t\t\tsourceTree = \"<group>\";
\t\t}};
"""
        # Add to PBXGroup section
        pbxproj_content = re.sub(
            r'(/\* End PBXFileReference section \*/\n)',
            r'\1\n/* Begin PBXGroup section */\n' + frameworks_group if '/* Begin PBXGroup section */' not in pbxproj_content else '',
            pbxproj_content,
            count=1
        )
        
        if '/* Begin PBXGroup section */' in pbxproj_content:
            pbxproj_content = re.sub(
                r'(/\* Begin PBXGroup section \*/\n)',
                r'\1' + frameworks_group,
                pbxproj_content,
                count=1
            )
        
        # Add Frameworks group to main group
        main_group_pattern = r'(97C146E51CF9000F007C117D = \{[^}]+children = \([^)]+)'
        main_group_entry = f"\n\t\t\t\t{frameworks_group_uuid} /* Frameworks */,"
        
        pbxproj_content = re.sub(
            main_group_pattern,
            r'\1' + main_group_entry,
            pbxproj_content,
            count=1
        )
    else:
        # Frameworks group exists, just add file reference to it
        frameworks_group_pattern = r'(/\* Frameworks \*/ = \{[^}]+children = \(\n)'
        frameworks_group_entry = f"\t\t\t\t{file_ref_uuid} /* {framework_name} */,\n"
        
        pbxproj_content = re.sub(
            frameworks_group_pattern,
            r'\1' + frameworks_group_entry,
            pbxproj_content,
            count=1
        )
    
    print(f"✅ Added {framework_name} to project")
    return pbxproj_content

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    ios_dir = os.path.dirname(script_dir)
    frameworks_dir = os.path.join(ios_dir, 'Frameworks')
    pbxproj_path = os.path.join(ios_dir, 'Runner.xcodeproj', 'project.pbxproj')
    
    print(f"iOS directory: {ios_dir}")
    print(f"Frameworks directory: {frameworks_dir}")
    print(f"Project file: {pbxproj_path}")
    
    # Check if project file exists
    if not os.path.exists(pbxproj_path):
        print(f"❌ Error: project.pbxproj not found at {pbxproj_path}")
        sys.exit(1)
    
    # Find xcframeworks
    frameworks = find_xcframeworks(frameworks_dir)
    
    if not frameworks:
        print(f"⚠️  No xcframeworks found in {frameworks_dir}")
        print("This script should be run after xcframeworks are generated")
        sys.exit(0)
    
    print(f"\nFound {len(frameworks)} framework(s):")
    for fw in frameworks:
        print(f"  - {fw}")
    
    # Read project file
    print(f"\nReading {pbxproj_path}...")
    pbxproj_content = read_pbxproj(pbxproj_path)
    
    # Backup original file
    backup_path = pbxproj_path + '.backup'
    write_pbxproj(backup_path, pbxproj_content)
    print(f"Created backup at {backup_path}")
    
    # Add each framework
    modified = False
    for framework in frameworks:
        original_content = pbxproj_content
        pbxproj_content = add_framework_to_project(pbxproj_content, framework)
        if pbxproj_content != original_content:
            modified = True
    
    if modified:
        # Write modified project file
        write_pbxproj(pbxproj_path, pbxproj_content)
        print(f"\n✅ Project file updated successfully")
        print(f"Backup saved at: {backup_path}")
    else:
        print(f"\n✅ No changes needed")
        # Remove backup if no changes
        os.remove(backup_path)
    
    print("\nNote: You may need to clean and rebuild the project for changes to take effect")

if __name__ == '__main__':
    main()
