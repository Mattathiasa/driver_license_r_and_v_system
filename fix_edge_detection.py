import os
import re

# Path to the edge_detection package
package_path = os.path.join(
    os.environ['LOCALAPPDATA'],
    'Pub', 'Cache', 'hosted', 'pub.dev',
    'edge_detection-1.1.3', 'android', 'build.gradle'
)

print("=" * 50)
print(" Fixing edge_detection Package")
print("=" * 50)
print()

# Check if file exists
if not os.path.exists(package_path):
    print(f"[ERROR] Package not found at: {package_path}")
    print()
    print("Please make sure you've run 'flutter pub get' first.")
    input("Press Enter to exit...")
    exit(1)

print(f"Found package at: {package_path}")
print()

# Restore from backup if it exists
backup_path = package_path + '.backup'
if os.path.exists(backup_path):
    print("Restoring from backup...")
    with open(backup_path, 'r', encoding='utf-8') as f:
        original_content = f.read()
    
    with open(package_path, 'w', encoding='utf-8') as f:
        f.write(original_content)
    print("Restored from backup.")
else:
    print("Creating backup...")
    with open(package_path, 'r', encoding='utf-8') as f:
        original_content = f.read()
    
    with open(backup_path, 'w', encoding='utf-8') as f:
        f.write(original_content)
    print("Backup created.")

print()

# Read the current content
with open(package_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Check if namespace already exists (properly formatted)
if re.search(r'namespace\s+["\']com\.sample\.edgedetection["\']', content):
    print("Namespace already properly configured!")
else:
    print("Adding namespace to build.gradle...")
    
    # Add namespace after 'android {'
    modified_content = re.sub(
        r'(android\s*\{)',
        r'\1\n    namespace "com.sample.edgedetection"\n',
        content,
        count=1
    )
    
    # Write the modified content
    with open(package_path, 'w', encoding='utf-8') as f:
        f.write(modified_content)
    
    print("Namespace added successfully!")

print()
print("=" * 50)
print(" Fix Applied!")
print("=" * 50)
print()
print("Now run these commands in mobile-flutter folder:")
print("  flutter clean")
print("  flutter pub get")
print("  flutter build apk --debug")
print()
input("Press Enter to exit...")
