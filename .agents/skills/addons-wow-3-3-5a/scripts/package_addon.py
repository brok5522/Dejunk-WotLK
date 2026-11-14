#!/usr/bin/env python3
"""Build an installable deterministic addon ZIP from a TOC/XML graph and explicit extras."""
import argparse
from pathlib import Path
import re
import zipfile
from audit_addon import BLOCKED, load_graph, safe_path


def build(addon_root, destination, toc=None, includes=(), folder=None):
    root, toc_path, metadata, files = load_graph(addon_root, toc)
    if '30300' not in re.findall(r'\d+', metadata.get('Interface', '')):
        raise ValueError('selected TOC does not target Interface 30300')
    folder = folder or root.name
    if not re.fullmatch(r'[A-Za-z0-9_-]+', folder):
        raise ValueError('choose a simple addon folder name with --folder')
    destination = Path(destination).resolve()
    if destination.suffix.lower() != '.zip':
        raise ValueError('output must be a .zip file')
    if destination.exists():
        raise ValueError('refusing to overwrite existing output: ' + str(destination))
    chosen = set(files)
    for raw in includes:
        path = safe_path(root, raw)
        if not path.exists():
            raise ValueError('extra path does not exist: ' + str(raw))
        candidates = path.rglob('*') if path.is_dir() else [path]
        for candidate in candidates:
            if not candidate.is_file():
                continue
            # Re-resolve symlinks and reject personal data rather than silently packaging it.
            resolved = safe_path(root, str(candidate.relative_to(root)))
            if any(part.casefold() in BLOCKED for part in candidate.relative_to(root).parts):
                raise ValueError('private/generated directory in explicit extras: ' + str(candidate))
            if resolved.suffix.lower() in {'.zip', '.log', '.pyc', '.pyo'}:
                continue
            chosen.add(resolved)
    entries = {folder + '/' + str(path.relative_to(root)).replace('\\', '/'): path.read_bytes()
               for path in sorted(chosen)}
    destination.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(destination, 'x', compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for name, data in sorted(entries.items()):
            info = zipfile.ZipInfo(name, date_time=(2026, 1, 1, 0, 0, 0))
            info.create_system = 3
            info.external_attr = 0o100644 << 16
            info.compress_type = zipfile.ZIP_DEFLATED
            archive.writestr(info, data, compresslevel=9)
    with zipfile.ZipFile(destination) as archive:
        if archive.testzip() is not None or set(archive.namelist()) != set(entries):
            raise ValueError('archive verification failed')
        for name, data in entries.items():
            if archive.read(name) != data:
                raise ValueError('archive content mismatch: ' + name)
    return len(entries)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('addon_root', type=Path)
    parser.add_argument('output', type=Path)
    parser.add_argument('--toc')
    parser.add_argument('--include', action='append', default=[], help='relative file/directory; repeat for assets and notices')
    parser.add_argument('--folder')
    args = parser.parse_args()
    try:
        count = build(args.addon_root, args.output, args.toc, args.include, args.folder)
    except (ValueError, OSError) as exc:
        parser.exit(1, str(exc) + '\n')
    print(f'Built and verified {args.output} ({count} files); not installed or published')
    print('Review all asset/license requirements before distributing')


if __name__ == '__main__':
    main()
