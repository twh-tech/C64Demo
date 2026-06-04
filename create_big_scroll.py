#!/usr/bin/env python3
"""
C64 Scroll Text Generator
Converts an input string to two binary files (top and bottom rows)
for use with a custom C64 character set in a demo scroller.
Character set layout:
- All characters are 2 tiles HIGH
- 2-wide chars use 4 codes each: top-left, bottom-left, top-right, bottom-right
- 1-wide chars use 2 codes each: top, bottom
- 3-wide (W) uses 6 codes: tl, bl, tm, bm, tr, br
Order: ABCDEFGH JKLMNOPQRSTUVWXYZ1234567890I
         ^space here (1-wide), J and I are also 1-wide
"""
import sys

def build_char_map():
    charmap = {}
    order = "ABCDEFGH JKLMNOPQRSTUVWXYZ1234567890"
    code = 0
    for ch in order:
        if ch in (' ', 'J'):
            charmap[ch] = ([code], [code + 1])
            code += 2
        elif ch == 'W':
            charmap['W'] = ([code, code + 2, code + 4],
                            [code + 1, code + 3, code + 5])
            code += 6
        else:
            charmap[ch] = ([code, code + 2], [code + 1, code + 3])
            code += 4
    charmap['I'] = ([code], [code + 1])
    return charmap

CHARMAP = build_char_map()

def string_to_scroll_rows(text):
    top_row = []
    bottom_row = []
    boundary = []      # 0 = first column of a character, 1 = continuation
    for ch in text.upper():
        if ch not in CHARMAP:
            print(f"WARNING: Unknown character '{ch}' — skipping", file=sys.stderr)
            continue
        top_tiles, bottom_tiles = CHARMAP[ch]
        width = len(top_tiles)
        top_row.extend(top_tiles)
        bottom_row.extend(bottom_tiles)
        boundary.append(0)                  # first column of this char
        boundary.extend([1] * (width - 1))  # continuation columns (0 for 1-wide chars)
    return top_row, bottom_row, boundary

def save_binary(filename, data):
    with open(filename, 'wb') as f:
        f.write(bytes(data))
    print(f"Saved {len(data)} bytes to: {filename}")

def print_preview(text, top_row, bottom_row, boundary):
    print(f"\nInput:     {text.upper()}")
    print(f"Top row:   {' '.join(f'{b:02X}' for b in top_row)}")
    print(f"Bottom row:{' '.join(f'{b:02X}' for b in bottom_row)}")
    print(f"Boundary:  {' '.join(str(b) for b in boundary)}")
    print(f"Width:     {len(top_row)} tiles")

def main():
    # --- Edit these two values to change the output ---
    text   = "ABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZ"
    prefix = "scroll"
    # --------------------------------------------------
    top_row, bottom_row, boundary = string_to_scroll_rows(text)
    if not top_row:
        print("ERROR: No valid characters in input.", file=sys.stderr)
        sys.exit(1)
    top_file = f"{prefix}_top.bin"
    bot_file = f"{prefix}_bot.bin"
    bnd_file = f"{prefix}_bnd.bin"
    save_binary(top_file, top_row)
    save_binary(bot_file, bottom_row)
    save_binary(bnd_file, boundary)
    print_preview(text, top_row, bottom_row, boundary)

if __name__ == "__main__":
    main()
