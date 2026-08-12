#!/usr/bin/env python3

import os
import sys
import argparse
import re
from typing import Dict, List, Optional, Tuple
import subprocess
from pathlib import Path

# ANSI color codes
COLORS = {
    'black': '\033[30m',
    'red': '\033[31m',
    'green': '\033[32m',
    'yellow': '\033[33m',
    'blue': '\033[34m',
    'magenta': '\033[35m',
    'cyan': '\033[36m',
    'white': '\033[37m',
    'bright_black': '\033[90m',
    'bright_red': '\033[91m',
    'bright_green': '\033[92m',
    'bright_yellow': '\033[93m',
    'bright_blue': '\033[94m',
    'bright_magenta': '\033[95m',
    'bright_cyan': '\033[96m',
    'bright_white': '\033[97m',
    'reset': '\033[0m'
}

# Background colors
BG_COLORS = {
    'black': '\033[40m',
    'red': '\033[41m',
    'green': '\033[42m',
    'yellow': '\033[43m',
    'blue': '\033[44m',
    'magenta': '\033[45m',
    'cyan': '\033[46m',
    'white': '\033[47m',
    'bright_black': '\033[100m',
    'bright_red': '\033[101m',
    'bright_green': '\033[102m',
    'bright_yellow': '\033[103m',
    'bright_blue': '\033[104m',
    'bright_magenta': '\033[105m',
    'bright_cyan': '\033[106m',
    'bright_white': '\033[107m'
}

class FLFFont:
    def __init__(self):
        self.height = 0
        self.baseline = 0
        self.max_length = 0
        self.old_layout = 0
        self.comment_lines = 0
        self.print_direction = 0
        self.num_chars = 0
        self.codetag_count = 0
        self.hardblank = ' '
        self.characters: Dict[str, List[str]] = {}
        self.smushing_rules = 0

    def load(self, font_path: str) -> bool:
        try:
            with open(font_path, 'r', encoding='utf-8', errors='replace') as f:
                content = f.read()
            
            lines = content.replace('\r\n', '\n').replace('\r', '\n').split('\n')
            
            if not lines or not lines[0].startswith('flf2a'):
                return False
                
            header = re.split(r'\s+', lines[0].strip())
            
            try:
                self.hardblank = header[0][5]
                self.height = int(header[1])
                self.baseline = int(header[2])
                self.max_length = int(header[3])
                self.old_layout = int(header[4])
                self.comment_lines = int(header[5])
                self.print_direction = int(header[6]) if len(header) > 6 else 0
                self.num_chars = int(header[7]) if len(header) > 7 else 256
                self.codetag_count = int(header[8]) if len(header) > 8 else 0
                self.smushing_rules = max(0, self.old_layout)
            except (IndexError, ValueError) as e:
                print(f"DEBUG: Error parsing header: {str(e)}", file=sys.stderr)
                return False
                
            lines = lines[1 + self.comment_lines:]
            current_char = 32  # ASCII space
            current_lines = []
            
            for line in lines:
                line = line.rstrip('\n')
                if not line:
                    continue
                    
                if line.endswith('@@'):
                    current_lines.append(line[:-2].replace(self.hardblank, ' '))
                    self.characters[chr(current_char)] = current_lines
                    current_lines = []
                    current_char += 1
                elif line.endswith('@'):
                    current_lines.append(line[:-1].replace(self.hardblank, ' '))
                else:
                    if current_lines and current_char <= 126:
                        current_lines.append(line.replace(self.hardblank, ' '))
            
            # Fill in missing ASCII characters with spaces
            for c in range(32, 127):
                if chr(c) not in self.characters:
                    self.characters[chr(c)] = [' ' * self.max_length] * self.height
            
            return True
            
        except Exception as e:
            print(f"DEBUG: Error loading font: {str(e)}", file=sys.stderr)
            return False

class ASCIIBanner:
    def __init__(self):
        self.font_dir = self.get_font_dir()
        self.font_cache: Dict[str, FLFFont] = {}
        self.default_font = 'Standard'
        self.terminal_width = self.get_terminal_width()
        
    def get_font_dir(self) -> str:
        paths = [
            os.path.join(os.environ.get('PREFIX', '/data/data/com.termux/files/usr'), 
                       'share', 'asciibanner', 'fonts'),
            os.path.join(os.environ.get('HOME', ''), '.local', 'share', 'asciibanner', 'fonts'),
            os.path.join(os.environ.get('HOME', ''), 'fonts'),
            '/data/data/com.termux/files/usr/share/figlet'
        ]
        
        for path in paths:
            if os.path.exists(path) and os.path.isdir(path):
                return path
        return paths[0]
        
    def get_terminal_width(self) -> int:
        try:
            return int(subprocess.check_output(['tput', 'cols']).decode().strip())
        except:
            return 80
    
    def load_font(self, font_name: str) -> Optional[FLFFont]:
        if font_name in self.font_cache:
            return self.font_cache[font_name]
            
        font_variations = [
            font_name,
            f"{font_name}.flf",
            font_name.lower(),
            font_name.upper(),
            font_name.title(),
            font_name.replace(' ', ''),
            font_name.replace(' ', '_')
        ]
        
        font_aliases = {
            'bloody': 'Bloody',
            'tickslant': 'tickslant',
            'slant': 'slant',
            'Standard': 'Standard',
            'block': 'block'
        }
        
        if font_name.lower() in font_aliases:
            font_variations.insert(0, font_aliases[font_name.lower()])
        
        for variation in set(font_variations):
            font_path = os.path.join(self.font_dir, variation)
            if os.path.exists(font_path):
                font = FLFFont()
                if font.load(font_path):
                    self.font_cache[font_name] = font
                    return font
                else:
                    print(f"Found but failed to load: {font_path}", file=sys.stderr)
            
            if variation.endswith('.flf'):
                base_name = variation[:-4]
                font_path = os.path.join(self.font_dir, base_name)
                if os.path.exists(font_path):
                    font = FLFFont()
                    if font.load(font_path):
                        self.font_cache[font_name] = font
                        return font
        
        print(f"Font '{font_name}' not found in: {self.font_dir}", file=sys.stderr)
        return None
    
    def list_fonts(self) -> List[str]:
        fonts = []
        try:
            for f in os.listdir(self.font_dir):
                if f.endswith('.flf') or not os.path.splitext(f)[1]:
                    fonts.append(os.path.splitext(f)[0])
        except FileNotFoundError:
            pass
        return sorted(set(fonts))
    
    def render_text(self, text: str, font: FLFFont, width: int = 0, kerning: bool = False,
                   color: Optional[str] = None, bg_color: Optional[str] = None) -> List[str]:
        if not text or not font.characters:
            return []
        
        lines = text.split('\n')
        rendered_lines = []
        
        for line in lines:
            char_blocks = []
            for c in line:
                char_blocks.append(font.characters.get(c, font.characters.get(' ')))
            
            if not char_blocks:
                continue
            
            rendered = []
            for i in range(font.height):
                line_parts = []
                for block in char_blocks:
                    if i < len(block):
                        line_parts.append(block[i])
                    else:
                        line_parts.append('')
                
                if kerning and font.smushing_rules > 0 and len(line_parts) > 1:
                    smushed_line = line_parts[0]
                    for j in range(1, len(line_parts)):
                        smushed_line = self.smush_chars(smushed_line, line_parts[j], font)
                    rendered_line = smushed_line
                else:
                    rendered_line = ''.join(line_parts)
                
                # Apply colors if specified
                if color or bg_color:
                    color_code = COLORS.get(color, '') if color else ''
                    bg_code = BG_COLORS.get(bg_color, '') if bg_color else ''
                    rendered_line = f"{color_code}{bg_code}{rendered_line}{COLORS['reset']}"
                
                rendered.append(rendered_line)
            
            rendered_lines.extend(rendered)
        
        if width > 0:
            wrapped_lines = []
            for line in rendered_lines:
                while len(line) > width:
                    wrapped_lines.append(line[:width])
                    line = line[width:]
                wrapped_lines.append(line)
            rendered_lines = wrapped_lines
        
        return rendered_lines
    
    def smush_chars(self, left: str, right: str, font: FLFFont) -> str:
        if not left or not right:
            return left + right
        
        overlap = 1
        smushed = left[:-overlap]
        
        left_char = left[-1] if len(left) > 0 else ' '
        right_char = right[0] if len(right) > 0 else ' '
        
        if left_char == ' ':
            smushed += right
        elif right_char == ' ':
            smushed += left[-overlap:] + right[overlap:]
        elif left_char == right_char:
            smushed += left_char + right[overlap:]
        else:
            smushed += left[-overlap:] + right
        
        return smushed
    
    def align_text(self, lines: List[str], width: int, alignment: str) -> List[str]:
        if alignment == 'center':
            return [line.center(width) for line in lines]
        elif alignment == 'right':
            return [line.rjust(width) for line in lines]
        return lines
    
    def preview_font(self, font_name: str, color: Optional[str] = None, bg_color: Optional[str] = None) -> bool:
        font = self.load_font(font_name)
        
        if not font:
            available_fonts = self.list_fonts()
            for available_font in available_fonts:
                if available_font.lower() == font_name.lower():
                    font = self.load_font(available_font)
                    break
        
        if not font:
            available = self.list_fonts()
            print(f"\nFont '{font_name}' not found. Available fonts:", file=sys.stderr)
            for f in available:
                print(f"  {f}")
            return False
        
        # Generate a clean preview
        sample_text = f"""ABCDEFGHIJKLM
NOPQRSTUVWXYZ
abcdefghijklm
nopqrstuvwxyz
1234567890
!@#$%^&*()_+
Font: {font_name}"""
        
        rendered = self.render_text(sample_text, font, self.terminal_width, False, color, bg_color)
        
        print(f"\nPreview of font '{font_name}':\n")
        for line in rendered:
            print(line)
        
        # Display font information
        font_path = self.get_font_path(font_name)
        print(f"\nFont information:")
        print(f"  Path: {font_path if font_path else 'Not found'}")
        print(f"  Height: {font.height} lines")
        print(f"  Max width: {font.max_length} chars")
        print(f"  Defined chars: {len(font.characters)}")
        print(f"  Smushing rules: {bin(font.smushing_rules)}")
        print()
        return True
    
    def get_font_path(self, font_name: str) -> Optional[str]:
        variations = [
            font_name,
            f"{font_name}.flf",
            font_name.lower(),
            font_name.upper(),
            font_name.title()
        ]
        
        for variation in variations:
            path = os.path.join(self.font_dir, variation)
            if os.path.exists(path):
                return path
        return None

def parse_color_args(color_str: Optional[str], bg_str: Optional[str]) -> Tuple[Optional[str], Optional[str]]:
    color = None
    bg_color = None
    
    if color_str:
        color = color_str.lower()
        if color not in COLORS and color != 'random':
            print(f"Invalid color '{color_str}'. Available colors:", file=sys.stderr)
            print(", ".join(COLORS.keys()), file=sys.stderr)
            color = None
    
    if bg_str:
        bg_color = bg_str.lower()
        if bg_color not in BG_COLORS:
            print(f"Invalid background color '{bg_str}'. Available colors:", file=sys.stderr)
            print(", ".join(BG_COLORS.keys()), file=sys.stderr)
            bg_color = None
    
    return color, bg_color

def main():
    banner = ASCIIBanner()
    
    parser = argparse.ArgumentParser(description='ASCIIBanner - FIGlet-compatible ASCII art generator with colors')
    parser.add_argument('text', nargs='?', default=None, help='Text to convert')
    parser.add_argument('-f', '--font', default='Standard', help='Font to use')
    parser.add_argument('-c', '--center', action='store_true', help='Center-align output')
    parser.add_argument('-r', '--right', action='store_true', help='Right-align output')
    parser.add_argument('-w', '--width', type=int, default=0, help='Output width')
    parser.add_argument('-o', '--output', help='Save output to file')
    parser.add_argument('-k', '--kerning', action='store_true', help='Enable kerning')
    parser.add_argument('--color', help='Text color (black, red, green, yellow, blue, magenta, cyan, white, bright_*)')
    parser.add_argument('--bg', help='Background color (same options as --color)')
    parser.add_argument('--random-color', action='store_true', help='Use random text color')
    parser.add_argument('--list-colors', action='store_true', help='List available colors')
    parser.add_argument('--list-fonts', action='store_true', help='List available fonts')
    parser.add_argument('--preview', metavar='FONT', help='Preview a specific font')
    
    args = parser.parse_args()
    
    if args.list_colors:
        print("Available text colors:")
        print(", ".join(COLORS.keys()))
        print("\nAvailable background colors:")
        print(", ".join(BG_COLORS.keys()))
        return
    
    if args.list_fonts:
        fonts = banner.list_fonts()
        if fonts:
            print("Available fonts:")
            for font in fonts:
                print(f"  {font}")
        else:
            print(f"No fonts found in: {banner.font_dir}")
        return
    
    if args.preview:
        color, bg_color = parse_color_args(args.color if not args.random_color else 'random', args.bg)
        if args.random_color:
            import random
            color = random.choice(list(COLORS.keys()))
        if not banner.preview_font(args.preview, color, bg_color):
            sys.exit(1)
        return
    
    alignment = 'left'
    if args.center:
        alignment = 'center'
    elif args.right:
        alignment = 'right'
    
    text = args.text
    if not text and not sys.stdin.isatty():
        text = sys.stdin.read().strip()
    
    if not text:
        parser.print_help()
        return
    
    font = banner.load_font(args.font)
    if not font:
        print(f"Using default font '{banner.default_font}'", file=sys.stderr)
        font = banner.load_font(banner.default_font)
        if not font:
            print("ERROR: Could not load any font", file=sys.stderr)
            sys.exit(1)
    
    color, bg_color = parse_color_args(args.color if not args.random_color else 'random', args.bg)
    if args.random_color:
        import random
        color = random.choice(list(COLORS.keys()))
    
    width = args.width if args.width > 0 else banner.terminal_width
    rendered = banner.render_text(text, font, width, args.kerning, color, bg_color)
    rendered = banner.align_text(rendered, width, alignment)
    output = '\n'.join(rendered)
    
    if args.output:
        try:
            with open(args.output, 'w') as f:
                f.write(output)
            print(f"Output saved to {args.output}")
        except IOError as e:
            print(f"Error saving file: {e}", file=sys.stderr)
            sys.exit(1)
    else:
        print(output)

if __name__ == '__main__':
    main()
