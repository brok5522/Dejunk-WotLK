#!/usr/bin/env python3
"""Report conservative, explicitly evidenced source-review coverage.

Whole files count only when listed with their exact source hash. Partial review
is useful but contributes zero until precise line ranges are recorded. This is
not a test, parity, security, or in-game compatibility metric.
"""
import hashlib
import json
import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
UPSTREAM = pathlib.Path('/workspace/work/Dejunk-upstream')
MANIFEST = ROOT / 'docs/review-coverage.json'
REVISION = '04bafd5e411441ef5b51bb8ed10d208f2d7758f5'

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def lines(path):
    with path.open('rb') as source:
        return sum(1 for _ in source)

def main():
    if subprocess.check_output(['git', '-C', str(UPSTREAM), 'rev-parse', 'HEAD'], text=True).strip() != REVISION:
        sys.exit('Unexpected upstream revision; coverage cannot be computed.')
    manifest = json.loads(MANIFEST.read_text())
    if manifest['upstream_revision'] != REVISION:
        sys.exit('Manifest revision mismatch.')
    for group, root in [('upstream', UPSTREAM), ('port', ROOT)]:
        paths = sorted((root / 'src').rglob('*.lua'))
        if group == 'upstream':
            paths = [p for p in paths if p.parent.name != 'locales' or p.name == '_enUS.lua']
        evidence = manifest[group]
        known = {p.relative_to(root).as_posix() for p in paths}
        if set(evidence) - known:
            sys.exit('Evidence references a missing file: ' + str(set(evidence) - known))
        done_files = done_lines = total_lines = 0
        print('\n' + group.upper())
        for path in paths:
            name = path.relative_to(root).as_posix()
            size = lines(path)
            total_lines += size
            entry = evidence.get(name)
            done = bool(entry and entry['sha256'] == sha(path))
            if entry and not done:
                print('STALE: ' + name)
            if done:
                if not entry.get('evidence') or not (ROOT / entry['evidence']).is_file():
                    sys.exit('Missing review evidence for ' + name)
                done_files += 1
                done_lines += size
            print(('%s %5d %s' % ('REVIEWED' if done else 'PENDING ', size, name)))
        print('TOTAL: %d/%d files (%.2f%%); %d/%d physical lines (%.2f%%)' % (
            done_files, len(paths), 100 * done_files / len(paths), done_lines,
            total_lines, 100 * done_lines / total_lines))
    print('\nCounts cover complete, hash-matching files only; partially reviewed files count as pending.')
    print('Non-English locales, vendored libraries, assets and tests are excluded from this source metric.')
    print('Coverage does not imply parity, resolved findings or original-client acceptance.')

if __name__ == '__main__':
    main()
