#!/usr/bin/env python3
"""Offline Phase 0 foundation checks; intentionally no game/API execution."""
import csv
import json
from pathlib import Path
import re
import sys
from urllib.parse import unquote

ROOT = Path(__file__).resolve().parents[1]
errors = []
required = [
    'AGENTS.md', 'README.md', 'docs/ARCHITECTURE.md', 'docs/SAFETY.md',
    'docs/ROADMAP.md', 'docs/TESTING.md', 'docs/VALIDATION.md',
    'docs/PHASE0.fa.md', 'docs/REVIEW.fa.md', 'docs/PULL_REQUEST_PHASE0.md',
    'docs/research/UPSTREAM.md', 'docs/research/COMPATIBILITY.md',
    'docs/research/DEPENDENCIES.md', 'docs/research/SOURCES.md',
    'docs/research/source-manifest.json', 'docs/research/api-symbols.csv',
    'docs/adr/0001-original-client-and-safety-boundary.md',
    '.github/workflows/phase0.yml', '.github/PULL_REQUEST_TEMPLATE.md',
    '.editorconfig', '.gitignore',
]
required += [f'{p}/README.md' for p in (
    'src', 'src/compat', 'src/core', 'src/store', 'src/rules',
    'src/services', 'src/ui', 'locales', 'libs', 'tests',
)]
for name in required:
    if not (ROOT / name).is_file():
        errors.append(f'Missing deliverable: {name}')

# This scaffold is intentionally non-installable. Update this gate only after
# explicit approval of implementation and replace it with runtime validation.
for path in ROOT.rglob('*'):
    if '.git' in path.parts or '__pycache__' in path.parts:
        continue
    if path.is_file() and path.suffix.lower() in {'.lua', '.toc', '.xml', '.tga', '.blp'}:
        errors.append(f'Unexpected runtime/art asset in Phase 0: {path.relative_to(ROOT)}')

markdown_files = sorted(ROOT.rglob('*.md'))
link_count = 0
for path in markdown_files:
    text = path.read_text(encoding='utf-8')
    if not text.endswith('\n'):
        errors.append(f'Missing final newline: {path.relative_to(ROOT)}')
    for target in re.findall(r'\[[^\]]+\]\(([^)]+)\)', text):
        if re.match(r'^[a-zA-Z][a-zA-Z0-9+.-]*:', target) or target.startswith('#'):
            continue
        target = unquote(target.split('#', 1)[0].strip('<>'))
        dest = (path.parent / target).resolve()
        if not dest.is_relative_to(ROOT) or not dest.exists():
            errors.append(f'Broken or escaping link in {path.relative_to(ROOT)}: {target}')
        link_count += 1

manifest_path = ROOT / 'docs/research/source-manifest.json'
try:
    manifest = json.loads(manifest_path.read_text())
    sources = manifest['sources']
    if len(sources) != 2 or {s['id'] for s in sources} != {'dejunk', 'wotlk-framexml'}:
        errors.append('Expected two identified source snapshots')
    hash_count = 0
    for source in sources:
        if not re.fullmatch(r'[0-9a-f]{40}', source['commit']):
            errors.append('Source revision is not immutable SHA-1')
        if not source['repository'].startswith('https://github.com/'):
            errors.append('Unexpected source repository')
        if not source['files']:
            errors.append('Empty source file manifest')
        for name, digest in source['files'].items():
            if not re.fullmatch(r'[0-9a-f]{64}', digest) or '..' in Path(name).parts:
                errors.append(f'Invalid source digest/path: {name}')
            hash_count += 1
except (OSError, ValueError, KeyError, TypeError) as exc:
    errors.append(f'Source manifest: {exc}')
    hash_count = 0

try:
    with (ROOT / 'docs/research/api-symbols.csv').open(newline='') as handle:
        reader = csv.DictReader(handle)
        if reader.fieldnames != ['source', 'line', 'symbol']:
            errors.append('API inventory header mismatch')
        rows = list(reader)
    if not rows:
        errors.append('API inventory is empty')
    for row in rows:
        if not row['line'].isdigit() or int(row['line']) < 1:
            errors.append(f'Invalid inventory line: {row}')
        if not row['source'].startswith(('src/', 'libs/')) or not row['symbol']:
            errors.append(f'Invalid inventory row: {row}')
except (OSError, KeyError, TypeError) as exc:
    errors.append(f'API inventory: {exc}')
    rows = []

if errors:
    print('\n'.join(f'FAIL: {error}' for error in errors))
    sys.exit(1)
print(f'PASS: {len(required)} required deliverables, {len(markdown_files)} Markdown files, '
      f'{link_count} local links, {hash_count} source digests, {len(rows)} API references')
print('PASS: no addon Lua, TOC, XML or runtime art assets; no inventory calls executed')
print('NOT RUN: Lua/runtime/client tests (no addon implementation in Phase 0)')
