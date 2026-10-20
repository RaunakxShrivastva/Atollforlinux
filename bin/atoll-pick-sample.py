#!/usr/bin/env python3
"""Answer pixel-colour queries for the Atoll colour picker.

The picker freezes the screen into a PNG, then asks this helper for colours as
the pointer moves. Keeping the decoded image in memory avoids spawning
ImageMagick for every mouse event, which made the loupe lag.

Usage: atoll-pick-sample.py <png>
Queries arrive on stdin as "x y"; replies are "#RRGGBB" on stdout.
"""
import sys

from PIL import Image


def main():
    if len(sys.argv) != 2:
        sys.exit(2)
    image = Image.open(sys.argv[1]).convert("RGB")
    image.load()
    width, height = image.size
    pixels = image.load()

    for line in sys.stdin:
        parts = line.split()
        if len(parts) < 2:
            continue
        try:
            x, y = int(parts[0]), int(parts[1])
        except ValueError:
            continue
        if x < 0 or y < 0 or x >= width or y >= height:
            continue
        r, g, b = pixels[x, y]
        sys.stdout.write("#%02X%02X%02X\n" % (r, g, b))
        sys.stdout.flush()


if __name__ == "__main__":
    main()
