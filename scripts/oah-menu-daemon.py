#!/usr/bin/env python3
import sys
import os
import glob
import json
import re
import time

def fuzzy_match(pattern, string):
    if not pattern:
        return True
    pattern = pattern.lower()
    string = string.lower()
    pattern_idx = 0
    for char in string:
        if char == pattern[pattern_idx]:
            pattern_idx += 1
            if pattern_idx == len(pattern):
                return True
    return False

def load_apps():
    cache_file = "/tmp/oah-menu-cache.json"
    dirs_to_search = [
        "/usr/share/applications",
        os.path.expanduser("~/.local/share/applications")
    ]
    
    # Check if cache is fresh enough (e.g. 5 minutes)
    if os.path.exists(cache_file) and time.time() - os.path.getmtime(cache_file) < 300:
        try:
            with open(cache_file, 'r') as f:
                return json.load(f)
        except:
            pass
            
    apps = []
    desktop_files = []
    for d in dirs_to_search:
        if os.path.exists(d):
            desktop_files.extend(glob.glob(os.path.join(d, "**", "*.desktop"), recursive=True))
            
    for df in desktop_files:
        app_info = {'name': '', 'icon': '', 'exec': '', 'nodisplay': False}
        try:
            with open(df, 'r', encoding='utf-8') as f:
                in_desktop_entry = False
                for line in f:
                    line = line.strip()
                    if line == '[Desktop Entry]':
                        in_desktop_entry = True
                        continue
                    elif line.startswith('['):
                        in_desktop_entry = False
                    
                    if not in_desktop_entry:
                        continue
                    
                    if line.startswith('Name=') and not app_info['name']:
                        app_info['name'] = line.split('=', 1)[1]
                    elif line.startswith('Icon=') and not app_info['icon']:
                        app_info['icon'] = line.split('=', 1)[1]
                    elif line.startswith('Exec=') and not app_info['exec']:
                        exec_cmd = line.split('=', 1)[1]
                        exec_cmd = re.sub(r'%[a-zA-Z]', '', exec_cmd).strip()
                        app_info['exec'] = exec_cmd
                    elif line.startswith('NoDisplay='):
                        val = line.split('=', 1)[1].lower()
                        if val == 'true':
                            app_info['nodisplay'] = True
        except:
            pass
        
        if app_info['name'] and app_info['exec'] and not app_info['nodisplay']:
            apps.append(app_info)
            
    try:
        with open(cache_file, 'w') as f:
            json.dump(apps, f)
    except:
        pass
        
    return apps

def main():
    query = sys.argv[1] if len(sys.argv) > 1 else ""
    
    # Check if stdin is piped
    if not sys.stdin.isatty():
        # dmenu mode
        items = []
        for line in sys.stdin:
            line = line.strip()
            if not line: continue
            if fuzzy_match(query, line):
                items.append({
                    "name": line,
                    "icon": "",
                    "exec": line
                })
        print(json.dumps(items))
        return

    # Normal mode
    apps = load_apps()
    results = []
    for info in apps:
        if fuzzy_match(query, info['name']) or fuzzy_match(query, info['exec']):
            results.append(info)
            
    # Sort results
    results.sort(key=lambda x: (not x['name'].lower().startswith(query.lower()), x['name'].lower()))
    
    print(json.dumps(results[:15]))

if __name__ == "__main__":
    main()
