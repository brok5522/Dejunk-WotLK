#!/usr/bin/env python3
"""Read-only TOC/XML and optional real Lua 5.1 syntax audit. Never runs addon Lua."""
import argparse
import json
from pathlib import Path, PureWindowsPath
import re
import subprocess
import xml.etree.ElementTree as ET

BLOCKED = {'.git', '.aws', '.codex', '__pycache__', 'wtf', 'savedvariables'}
MODERN = re.compile(r'\b(?:C_Container|C_AddOns|C_Item|C_Timer|ItemLocation|Enum)\b|\bSettings\s*\.\s*Register\w*')


def safe_path(root, raw, relative=None):
    raw = str(raw).replace('\\', '/')
    if Path(raw).is_absolute() or PureWindowsPath(raw).is_absolute() or ':' in raw:
        raise ValueError('absolute/drive path is not allowed: ' + raw)
    lexical = (relative or root) / raw
    if any(part.is_symlink() for part in [lexical, *lexical.parents] if part != root):
        raise ValueError('symlinked package paths are not supported: ' + raw)
    result = lexical.resolve()
    if not result.is_relative_to(root):
        raise ValueError('path leaves addon directory: ' + raw)
    if any(part.casefold() in BLOCKED for part in result.relative_to(root).parts):
        raise ValueError('private/generated path is not allowed: ' + raw)
    return result


def load_graph(root, toc=None):
    root = Path(root).resolve()
    if not root.is_dir():
        raise ValueError('addon directory does not exist')
    if toc is None:
        preferred = root / (root.name + '.toc')
        choices = sorted(root.glob('*.toc'))
        if preferred.is_file():
            toc = preferred.name
        elif len(choices) == 1:
            toc = choices[0].name
        else:
            raise ValueError('select one TOC with --toc')
    toc_path = safe_path(root, toc)
    if toc_path.suffix.lower() != '.toc' or not toc_path.is_file():
        raise ValueError('TOC file does not exist or is not a .toc file')
    metadata, files, visited, active = {}, [], set(), set()

    def visit(path):
        if not path.is_file():
            raise ValueError('missing load-graph file: ' + str(path.relative_to(root)))
        if path in active:
            raise ValueError('cyclic XML include: ' + str(path.relative_to(root)))
        if path in visited:
            return
        if path.suffix.lower() not in {'.toc', '.lua', '.xml'}:
            raise ValueError('unexpected load-graph extension: ' + str(path.relative_to(root)))
        active.add(path)
        visited.add(path)
        files.append(path)
        if path.suffix.lower() == '.xml':
            document = ET.parse(path)
            for element in document.iter():
                tag = element.tag.rsplit('}', 1)[-1]
                if tag in {'Script', 'Include'} and element.get('file'):
                    visit(safe_path(root, element.get('file'), path.parent))
        active.remove(path)

    files.append(toc_path)
    visited.add(toc_path)
    for line in toc_path.read_text(encoding='utf-8-sig').splitlines():
        text = line.strip()
        if text.startswith('##') and ':' in text:
            key, value = text[2:].split(':', 1)
            metadata[key.strip()] = value.strip()
        elif text and not text.startswith('#'):
            visit(safe_path(root, text, toc_path.parent))
    return root, toc_path, metadata, files


def audit(root, toc=None, luac=None):
    report = {'errors': [], 'warnings': [], 'files': [], 'lua_syntax': 'not run'}
    try:
        root, toc_path, metadata, files = load_graph(root, toc)
        report['toc'] = str(toc_path.relative_to(root))
        report['metadata'] = metadata
        report['files'] = [str(path.relative_to(root)) for path in files]
        interfaces = re.findall(r'\d+', metadata.get('Interface', ''))
        if '30300' not in interfaces:
            report['errors'].append('Interface metadata does not include 30300')
        if len(interfaces) > 1:
            report['warnings'].append('Mixed client interfaces: verify distinct guarded execution paths')
        lua_files = [path for path in files if path.suffix.lower() == '.lua']
        for path in lua_files:
            for number, line in enumerate(path.read_text(encoding='utf-8-sig').splitlines(), 1):
                if line.lstrip().startswith('--'):
                    continue
                for match in MODERN.finditer(line):
                    report['warnings'].append(f'{path.relative_to(root)}:{number}: review {match.group(0)} on build 12340')
        if luac:
            version = subprocess.run([luac, '-v'], capture_output=True, text=True)
            output = version.stdout + version.stderr
            if version.returncode != 0 or not re.search(r'\bLua 5\.1(?:\D|$)', output):
                raise ValueError('--luac must identify itself as actual Lua 5.1')
            for path in lua_files:
                checked = subprocess.run([luac, '-p', str(path)], capture_output=True, text=True)
                if checked.returncode:
                    report['errors'].append(f'{path.relative_to(root)}: {checked.stderr.strip()}')
            report['lua_syntax'] = f'Lua 5.1 checked {len(lua_files)} loaded files'
        if any(path.suffix.lower() == '.xml' for path in files):
            report['warnings'].append('Inline XML handler Lua is not compiled by this auditor; review separately')
    except (ValueError, OSError, UnicodeError, ET.ParseError) as exc:
        report['errors'].append(str(exc))
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('addon_root', type=Path)
    parser.add_argument('--toc')
    parser.add_argument('--luac', help='actual luac5.1 executable; optional')
    parser.add_argument('--json', action='store_true')
    args = parser.parse_args()
    result = audit(args.addon_root, args.toc, args.luac)
    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        print('PASS' if not result['errors'] else 'FAIL', '- load graph:', len(result['files']), 'files')
        print('Syntax:', result['lua_syntax'])
        for text in result['warnings']:
            print('REVIEW:', text)
        for text in result['errors']:
            print('ERROR:', text)
        print('Native-client compatibility: NOT established by this audit')
    return 1 if result['errors'] else 0


if __name__ == '__main__':
    raise SystemExit(main())
