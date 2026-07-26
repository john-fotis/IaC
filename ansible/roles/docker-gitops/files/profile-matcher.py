#!/usr/bin/env python3
"""
Profile matcher script for Docker Compose services.
Checks if a compose.yaml file matches the specified profile.
"""

import sys
import re

def check_profile_match(compose_content, target_profile):
    """
    Check if compose file matches target profile.
    Supports both inline array and YAML list formats.
    """
    # Check inline array format: profiles: [prod, dmz]
    inline_pattern = rf'profiles:\s*\[.*\b{target_profile}\b.*\]'
    if re.search(inline_pattern, compose_content, re.IGNORECASE):
        return True

    # Check YAML list format
    lines = compose_content.split('\n')
    in_profiles = False

    for line in lines:
        if re.match(r'\s*profiles:', line):
            in_profiles = True
            continue

        if in_profiles:
            # Check if line is a list item
            if re.match(r'\s*-\s*', line):
                profile_value = re.sub(r'^\s*-\s*', '', line).strip()
                if profile_value == target_profile:
                    return True
            # Exit profiles section if we hit a non-indented key
            elif re.match(r'^[^\s]', line):
                in_profiles = False

    return False

def main():
    """
    Reads a Docker Compose file and checks if it matches the target profile.
    """
    if len(sys.argv) < 2:
        print("ERROR: Profile argument required", file=sys.stderr)
        sys.exit(1)

    target_profile = sys.argv[1]

    # Read compose file from stdin
    compose_content = sys.stdin.read()

    # Check for profiles key existence
    if 'profiles:' not in compose_content.lower():
        print("NOMATCH: No profiles defined")
        sys.exit(0)

    if check_profile_match(compose_content, target_profile):
        print(f"MATCH: Profile '{target_profile}' found")
        sys.exit(0)
    else:
        print(f"NOMATCH: Profile '{target_profile}' not found")
        sys.exit(0)

if __name__ == "__main__":
    main()
