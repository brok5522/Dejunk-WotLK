#!/usr/bin/env python3
"""Validate and bundle this portable skill; no installation/publication side effects."""
import argparse
import hashlib
from pathlib import Path
import re
import zipfile


def build(destination):
    root = Path(__file__).resolve().parents[1]
    skill = (root / 'SKILL.md').read_text()
    assert skill.startswith('---\n') and '\n---\n' in skill
    front = skill.split('---\n', 2)[1]
    assert re.search(r'^name: addons-wow-3-3-5a$', front, re.M)
    assert re.search(r'^description: .+', front, re.M)
    required = ['SKILL.md', 'README.fa.md', 'LICENSE', 'VERSION', 'agents/openai.yaml',
                'scripts/audit_addon.py', 'scripts/package_addon.py',
                'references/research-snapshot/source-manifest.json']
    for name in required:
        assert (root / name).is_file(), 'Missing skill resource: ' + name
    entries = {}
    for path in sorted(root.rglob('*')):
        if not path.is_file():
            continue
        if path.is_symlink():
            raise ValueError('skill resources must not be symlinks')
        rel = path.relative_to(root)
        if any(part in {'__pycache__', '.git'} for part in rel.parts):
            continue
        if path.suffix.lower() in {'.pyc', '.pyo', '.zip', '.skill', '.log'}:
            continue
        entries[rel.as_posix()] = path.read_bytes()
    # Curated docs have portable local links. Historical snapshots are .txt files.
    for name, data in entries.items():
        if name.endswith('.md'):
            for target in re.findall(r'\[[^\]]+\]\(([^)]+)\)', data.decode()):
                if re.match(r'^[a-zA-Z][a-zA-Z0-9+.-]*:', target) or target.startswith('#'):
                    continue
                resolved = ((root / name).parent / target.split('#', 1)[0]).resolve()
                if not resolved.is_relative_to(root) or not resolved.exists():
                    raise ValueError('broken skill reference: ' + name + ' -> ' + target)
    sums = ''.join(hashlib.sha256(data).hexdigest() + '  ' + name + '\n'
                   for name, data in sorted(entries.items()))
    entries['SHA256SUMS.txt'] = sums.encode()
    destination = Path(destination).resolve()
    if destination.suffix.lower() not in {'.zip', '.skill'}:
        raise ValueError('output must be .zip or .skill')
    if destination.exists() or destination.is_relative_to(root):
        raise ValueError('choose a new output file outside the skill directory')
    destination.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(destination, 'x', compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for name, data in sorted(entries.items()):
            info = zipfile.ZipInfo(root.name + '/' + name, date_time=(2026, 1, 1, 0, 0, 0))
            info.create_system = 3
            info.external_attr = 0o100644 << 16
            info.compress_type = zipfile.ZIP_DEFLATED
            archive.writestr(info, data, compresslevel=9)
    with zipfile.ZipFile(destination) as archive:
        assert archive.testzip() is None
        for name, data in entries.items():
            assert archive.read(root.name + '/' + name) == data
    print(f'Built {destination.name}: {len(entries)} entries')
    print('SHA256:', hashlib.sha256(destination.read_bytes()).hexdigest())


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    build(args.output)
