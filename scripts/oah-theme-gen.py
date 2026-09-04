#!/usr/bin/env python3
import sys
import os
import tomllib
import re

def hex_to_rgb(hex_str):
    hex_str = hex_str.lstrip('#')
    if len(hex_str) == 6:
        return f"{int(hex_str[0:2], 16)}, {int(hex_str[2:4], 16)}, {int(hex_str[4:6], 16)}"
    return hex_str

def main():
    if len(sys.argv) < 3:
        print("Usage: oah-theme-gen.py <colors.toml> <template_dir>")
        sys.exit(1)

    colors_file = sys.argv[1]
    template_dir = sys.argv[2]

    with open(colors_file, 'rb') as f:
        theme = tomllib.load(f)

    colors = {}
    
    for k, v in theme.items():
        if isinstance(v, str):
            colors[k] = v

    # Mapping Omarchy fallbacks for variables like color8
    if 'color8' not in colors and 'muted' in colors:
        colors['color8'] = colors['muted']

    # Add derived colors
    for k, v in list(colors.items()):
        if v.startswith('#'):
            colors[f"{k}_strip"] = v.lstrip('#')
            colors[f"{k}_rgb"] = hex_to_rgb(v)

    def replace_match(match):
        key = match.group(1).strip()
        return colors.get(key, match.group(0))

    for root, dirs, files in os.walk(template_dir):
        for file in files:
            if file.endswith('.tpl'):
                tpl_path = os.path.join(root, file)
                out_path = tpl_path[:-4] # strip .tpl
                
                with open(tpl_path, 'r') as f:
                    content = f.read()

                new_content = re.sub(r'\{\{\s*([a-zA-Z0-9_]+)\s*\}\}', replace_match, content)

                with open(out_path, 'w') as f:
                    f.write(new_content)
                
                print(f"Generated {out_path}")

if __name__ == '__main__':
    main()
