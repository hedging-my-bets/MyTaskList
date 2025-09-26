#!/usr/bin/env python3
"""
Convert all asset Contents.json files from 'universal' to 'iphone' idiom
for iPhone-only targeting compliance.
"""

import os
import json
import glob

def convert_contents_json_to_iphone(file_path):
    """Convert a Contents.json file from universal to iphone idiom"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)

        # Convert all universal idioms to iphone
        modified = False
        if 'images' in data:
            for image in data['images']:
                if image.get('idiom') == 'universal':
                    image['idiom'] = 'iphone'
                    modified = True
                    print(f"  Converted universal -> iphone in {file_path}")

        # Write back if modified
        if modified:
            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(data, f, indent=2)

        return modified

    except Exception as e:
        print(f"ERROR processing {file_path}: {e}")
        return False

def main():
    """Find and convert all Contents.json files in the project"""
    project_root = os.getcwd()

    # Find all Contents.json files
    pattern = os.path.join(project_root, "**", "Contents.json")
    files = glob.glob(pattern, recursive=True)

    print(f"Found {len(files)} Contents.json files to process:")

    total_converted = 0
    for file_path in files:
        print(f"\nProcessing: {file_path}")
        if convert_contents_json_to_iphone(file_path):
            total_converted += 1

    print(f"\nConversion complete! Modified {total_converted} files for iPhone-only targeting.")
    print("All assets now use 'iphone' idiom instead of 'universal'.")

if __name__ == "__main__":
    main()