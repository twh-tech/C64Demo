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
         ^space here (1-wide), I at end (1-wide)
"""

import sys

# ---------------------------------------------------------------------------
# Character map: char -> (top_tiles, bottom_tiles)
# Each tuple contains the screen codes for that row, left to right.
# ---------------------------------------------------------------------------

def build_char_map():
    charmap = {}

    # Characters in charset order (space and I are special, handled separately)
    order = "ABCDEFGH JKLMNOPQRSTUVWXYZ1234567890I"

    code = 0
    for ch in order:
        if ch == ' ':
            # 1-wide: top=code, bottom=code+1
            charmap[' '] = ([code], [code + 1])
            code += 2
        elif ch == 'I':
            # 1-wide: top=code, bottom=code+1
            charmap['I'] = ([code], [code + 1])
            code += 2
        elif ch == 'W':
            # 3-wide: tl, tm, tr on top; bl, bm, br on bottom
            charmap['W'] = ([code, code + 2, code + 4],
                            [code + 1, code + 3, code + 5])
            code += 6
        else:
            # 2-wide: top-left, top-right; bottom-left, bottom-right
            charmap[ch] = ([code, code + 2], [code + 1, code + 3])
            code += 4

    return charmap


CHARMAP = build_char_map()


def string_to_scroll_rows(text):
    """
    Convert input text to (top_row, bottom_row) lists of screen codes.
    Unknown characters are skipped with a warning.
    """
    top_row = []
    bottom_row = []

    for ch in text.upper():
        if ch not in CHARMAP:
            print(f"WARNING: Unknown character '{ch}' — skipping", file=sys.stderr)
            continue
        top_tiles, bottom_tiles = CHARMAP[ch]
        top_row.extend(top_tiles)
        bottom_row.extend(bottom_tiles)

    return top_row, bottom_row


def save_binary(filename, data):
    with open(filename, 'wb') as f:
        f.write(bytes(data))
    print(f"Saved {len(data)} bytes to: {filename}")


def print_preview(text, top_row, bottom_row):
    """Print a simple terminal preview using block characters."""
    print(f"\nInput:     {text.upper()}")
    print(f"Top row:   {' '.join(f'{b:02X}' for b in top_row)}")
    print(f"Bottom row:{' '.join(f'{b:02X}' for b in bottom_row)}")
    print(f"Width:     {len(top_row)} tiles")


def main():
    # --- Edit these two values to change the output ---
    text   = "    HELLO. THIS IS THE FIRST TEST OF THE CREATEBIGSCROLL PYTHON SCRIPT. I HOPE IT WORKS ABCDEFGHIJKLMNOPQRSTUVWXYZ 1234567890               "
    prefix = "scroll"
    # --------------------------------------------------

    top_row, bottom_row = string_to_scroll_rows(text)

    if not top_row:
        print("ERROR: No valid characters in input.", file=sys.stderr)
        sys.exit(1)

    top_file = f"{prefix}_top.bin"
    bot_file = f"{prefix}_bot.bin"

    save_binary(top_file, top_row)
    save_binary(bot_file, bottom_row)

    print_preview(text, top_row, bottom_row)


if __name__ == "__main__":
    main()
