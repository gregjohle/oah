#!/usr/bin/env python3
import sys
import os
import colorsys
import subprocess
from PIL import Image

def get_colors(image_path):
    try:
        img = Image.open(image_path).convert('RGB')
    except Exception as e:
        print(f"Error opening image {image_path}: {e}")
        return None
        
    img = img.resize((150, 150))
    q = img.quantize(colors=10, method=Image.Quantize.MEDIANCUT)
    palette = q.getpalette()
    
    colors = []
    for i in range(10):
        r, g, b = palette[i*3:i*3+3]
        colors.append((r, g, b))
    
    colors.sort(key=lambda c: colorsys.rgb_to_hsv(c[0]/255, c[1]/255, c[2]/255)[2])
    
    bg = colors[0]
    dark_bg = (max(0, bg[0]-10), max(0, bg[1]-10), max(0, bg[2]-10))
    fg = colors[-1]
    
    remaining = colors[1:-1]
    remaining.sort(key=lambda c: colorsys.rgb_to_hsv(c[0]/255, c[1]/255, c[2]/255)[1], reverse=True)
    
    accent = remaining[0] if remaining else fg
    red = remaining[1] if len(remaining) > 1 else accent
    green = remaining[2] if len(remaining) > 2 else accent
    blue = remaining[3] if len(remaining) > 3 else accent
    
    def to_hex(c):
        return f"#{c[0]:02x}{c[1]:02x}{c[2]:02x}"
        
    return {
        "mode": "dark",
        "background": to_hex(bg),
        "dark_background": to_hex(dark_bg),
        "foreground": to_hex(fg),
        "accent": to_hex(accent),
        "muted": to_hex(colors[1]),
        "red": to_hex(red),
        "green": to_hex(green),
        "yellow": to_hex(accent),
        "blue": to_hex(blue),
        "magenta": to_hex(red),
        "cyan": to_hex(green),
        "color8": to_hex(colors[1])
    }

def save_colors(colors_dict, out_path):
    if not colors_dict: return
    with open(out_path, "w") as f:
        for k, v in colors_dict.items():
            f.write(f'{k} = "{v}"\n')

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: oah-extract-colors.py <image_path> <theme_name>")
        sys.exit(1)
        
    img_path = sys.argv[1]
    theme_name = sys.argv[2]
    
    out_dir = f"themes/{theme_name}"
    os.makedirs(f"{out_dir}/backgrounds", exist_ok=True)
    
    if img_path.lower().endswith(".heic"):
        print(f"Unpacking HEIC wallpaper {img_path}...")
        subprocess.run(["timewall", "unpack", img_path, f"{out_dir}/backgrounds/"], check=True)
        os.system(f"cp '{img_path}' '{out_dir}/background.heic'")
        
        # generate a palette for each image
        first_img = None
        for file in sorted(os.listdir(f"{out_dir}/backgrounds/")):
            if file.endswith((".png", ".jpg", ".jpeg", ".webp")):
                base_name = os.path.splitext(file)[0]
                img_file = os.path.join(f"{out_dir}/backgrounds", file)
                
                if first_img is None:
                    first_img = img_file
                    
                colors = get_colors(img_file)
                save_colors(colors, f"{out_dir}/colors-{base_name}.toml")
                
        # save the master colors.toml using the first image
        if first_img:
            colors = get_colors(first_img)
            save_colors(colors, f"{out_dir}/colors.toml")
            os.system(f"cp '{first_img}' '{out_dir}/preview.jpg'")
    else:
        # Standard image
        os.system(f"cp '{img_path}' '{out_dir}/backgrounds/01-custom.jpg'")
        os.system(f"cp '{img_path}' '{out_dir}/preview.jpg'")
        colors = get_colors(img_path)
        save_colors(colors, f"{out_dir}/colors.toml")
            
    print(f"Theme {theme_name} generated successfully at {out_dir}")
