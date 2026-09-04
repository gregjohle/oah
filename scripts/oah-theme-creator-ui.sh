#!/bin/bash

case "$1" in
    open)
        eww update creator_image="" creator_name="custom-theme"
        eww open theme_creator
        ;;
    pick_image)
        IMG=$(zenity --file-selection --title="Select an Image" --file-filter="Images | *.png *.jpg *.jpeg *.webp")
        if [[ -n "$IMG" ]]; then
            eww update creator_image="$IMG"
            # Get quick preview colors to show in UI
            colors=$(python3 -c "
import colorsys, sys
from PIL import Image
try:
    img = Image.open('$IMG').convert('RGB').resize((150, 150))
    q = img.quantize(colors=4, method=Image.Quantize.MEDIANCUT)
    p = q.getpalette()
    for i in range(4):
        r, g, b = p[i*3:i*3+3]
        print(f'#{r:02x}{g:02x}{b:02x}')
except:
    pass
" 2>/dev/null)
            
            if [[ -n "$colors" ]]; then
                c1=$(echo "$colors" | sed -n '1p')
                c2=$(echo "$colors" | sed -n '2p')
                c3=$(echo "$colors" | sed -n '3p')
                c4=$(echo "$colors" | sed -n '4p')
                eww update creator_color1="$c1" creator_color2="$c2" creator_color3="$c3" creator_color4="$c4"
            fi
        fi
        ;;
    cancel)
        eww close theme_creator
        ;;
    save)
        IMG=$(eww get creator_image)
        NAME=$(eww get creator_name)
        NAME=$(echo "$NAME" | sed -E 's/<[^>]+>//g' | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
        
        if [[ -n "$IMG" && -n "$NAME" ]]; then
            "$(dirname "$0")/oah-extract-colors.py" "$IMG" "$NAME"
            eww close theme_creator
            # Apply it immediately
            "$(dirname "$0")/oah-theme-set.sh" "$NAME"
            zenity --info --text="Theme '$NAME' successfully created and applied!"
        fi
        ;;
esac
