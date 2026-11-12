#!/usr/bin/env python3
"""Build a reproducible read-only addon ZIP; does not publish or install it."""
import argparse
from pathlib import Path
import zipfile

ROOT = Path(__file__).resolve().parents[1]


def build(destination):
    toc = ROOT / 'Dejunk-WotLK.toc'
    paths = [toc, ROOT / 'LICENSE']
    for line in toc.read_text().splitlines():
        if line.strip() and not line.lstrip().startswith('#'):
            path = (ROOT / line.strip().replace('\\', '/')).resolve()
            if not path.is_relative_to(ROOT) or not path.is_file() or path.suffix != '.lua':
                raise ValueError(f'Invalid TOC file: {line}')
            paths.append(path)
    entries = {path.relative_to(ROOT).as_posix(): path.read_bytes() for path in paths}
    entries['README.txt'] = (
        'Dejunk-WotLK 0.3.2-dev - READ-ONLY RULE PREVIEW\n'
        'Original WoW 3.3.5a / build 12340 / Interface 30300 only.\n'
        'Original-client testing is pending; this is not the complete addon.\n'
        'Extract so Interface/AddOns/Dejunk-WotLK/Dejunk-WotLK.toc exists.\n'
        '/djw status | /djw profile | /djw lists | /djw rules | /djw preview sell|destroy | /djw report\n'
        'The slot command reads only the chosen bag slot. The report can be copied.\n'
        'Profiles and lists save in account SavedVariables. No selling, deletion, repair or item use.\n'
        'Disable in the AddOns menu or remove only this addon folder to uninstall.\n'
        'Code is independently written; upstream design reference: moody/Dejunk\n'
        'commit 04bafd5e411441ef5b51bb8ed10d208f2d7758f5 (MIT).\n'
        'No upstream code, libraries, artwork or Blizzard FrameXML are bundled.\n'
    ).encode('utf-8')
    destination = destination.resolve()
    if destination.exists():
        raise ValueError(f'Refusing to overwrite existing output: {destination}')
    if destination.suffix.lower() != '.zip' or destination.is_relative_to(ROOT / 'src'):
        raise ValueError('Choose a .zip output outside src')
    destination.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(destination, 'x', compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for name, data in sorted(entries.items()):
            entry = zipfile.ZipInfo('Dejunk-WotLK/' + name, date_time=(2026, 1, 1, 0, 0, 0))
            entry.create_system = 3
            entry.external_attr = 0o100644 << 16
            entry.compress_type = zipfile.ZIP_DEFLATED
            archive.writestr(entry, data, compresslevel=9)
    print(f'Built {destination} ({len(entries)} entries); not installed or published')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('output', type=Path)
    build(parser.parse_args().output)
