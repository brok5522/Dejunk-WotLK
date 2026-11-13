#!/usr/bin/env python3
"""Validate the Phase 1 read-only addon with an actual Lua 5.1 toolchain."""
import argparse
import hashlib
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import zipfile

from package import build

ROOT = Path(__file__).resolve().parents[1]


def run(command):
    subprocess.run(command, cwd=ROOT, check=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--lua', default=shutil.which('lua5.1'))
    parser.add_argument('--luac', default=shutil.which('luac5.1'))
    args = parser.parse_args()
    if not args.lua or not args.luac:
        parser.error('Install lua5.1 or pass --lua /path/to/lua5.1 --luac /path/to/luac5.1')
    for executable in (args.lua, args.luac):
        version = subprocess.run([executable, '-v'], text=True, capture_output=True, check=True)
        if not re.search(r'\bLua 5\.1\.', version.stdout + version.stderr):
            parser.error(f'{executable} is not a Lua 5.1 tool')

    for deliverable in (
        'docs/PHASE1.md', 'docs/PHASE1.fa.md', 'docs/PHASE2.md', 'docs/CLIENT-ACCEPTANCE.md',
        'docs/PULL_REQUEST_PHASE1.md', 'LICENSE', 'tools/package.py',
    ):
        if not (ROOT / deliverable).is_file():
            raise ValueError(f'Missing Phase 1 deliverable: {deliverable}')
    toc = ROOT / 'Dejunk-WotLK.toc'
    text = toc.read_text()
    if not re.search(r'^## Interface: 30300$', text, re.M):
        raise ValueError('TOC must target Interface 30300')
    if text.count('## SavedVariables: DejunkWotLKDB') != 1 or 'Dependencies:' in text or 'LoadOnDemand:' in text:
        raise ValueError('Phase 2 requires one namespaced SavedVariables declaration and no external dependencies')
    load_order = []
    for line in text.splitlines():
        if line.strip() and not line.lstrip().startswith('#'):
            entry = line.strip().replace('\\', '/')
            path = (ROOT / entry).resolve()
            if not path.is_relative_to(ROOT) or not path.is_file() or path.suffix != '.lua':
                raise ValueError(f'Invalid TOC path: {entry}')
            load_order.append(entry)
    if len(load_order) != len(set(load_order)):
        raise ValueError('Duplicate TOC entry')
    expected = [
        'src/namespace.lua', 'libs/Waffle.lua', 'src/compat/client.lua', 'src/compat/legacy.lua',
        'src/compat/runtime.lua', 'src/core/events.lua', 'src/core/scheduler.lua',
        'src/core/bag-cache.lua', 'src/core/diagnostics.lua', 'src/store/store.lua',
        'src/rules/evaluator.lua', 'src/services/preview.lua', 'src/services/seller.lua',
        'src/services/repair.lua', 'src/services/destroyer.lua', 'src/ui/config.lua', 'src/core/bootstrap.lua',
    ]
    if load_order != expected:
        raise ValueError('Unexpected TOC load order; review the runtime and vendored UI boundary')
    if hashlib.sha256((ROOT / 'libs/Waffle.lua').read_bytes()).hexdigest() != 'bd668fb59160f4f9bc4b2b13298c7ca93cbad9be017892b21eac089a3015d396':
        raise ValueError('Pinned upstream Waffle source digest changed')
    if not (ROOT / 'libs/Waffle-LICENSE.txt').is_file():
        raise ValueError('Vendored Waffle license notice is missing')
    source_files = {p.relative_to(ROOT).as_posix() for p in (ROOT / 'src').rglob('*.lua')}
    if set(load_order) - {'libs/Waffle.lua'} != source_files:
        raise ValueError('Runtime files missing from TOC or unauthorized module added')
    if re.search(r'^## Version: (.+)$', text, re.M).group(1) not in (ROOT / 'src/namespace.lua').read_text():
        raise ValueError('TOC/code version mismatch')

    forbidden = re.compile(r'\b(?:UseContainerItem|PickupContainerItem|DeleteCursorItem|'
                           r'RepairAllItems|SplitContainerItem|EquipItemByName|PickupInventoryItem|'
                           r'PickupItem|UseItemByName|SellCursorItem|PutItemInBag|PutItemInBackpack|'
                           r'loadstring|dofile|loadfile|C_[A-Za-z0-9_]+|Enum)\b')
    for entry in load_order:
        source = (ROOT / entry).read_text()
        if entry == 'src/compat/runtime.lua':
            # Upstream ListItem clears a deliberately held cursor item after
            # its ID is committed to a list. Keep this sole UI-only exception
            # narrow; selling/deleting/picking up inventory remains forbidden.
            if source.count('api.ClearCursor') != 2:
                raise ValueError('Unexpected cursor-clear path in the compatibility UI')
            source = source.replace('api.ClearCursor', '')
        if 'ClearCursor' in source:
            raise ValueError(f'Cursor clearing is outside the approved list-drop path: {entry}')
        if forbidden.search(source):
            raise ValueError(f'Forbidden runtime symbol in {entry}: {forbidden.search(source).group()}')
        if not entry.startswith('src/compat/'):
            if re.search(r'\b(?:_G|CreateFrame|SlashCmdList|GetBuildInfo|GetContainer\w+|GetItemInfo|'
                         r'GetNumEquipmentSets|GetEquipmentSet\w+|DEFAULT_CHAT_FRAME|GameTooltip)\b', source):
                raise ValueError(f'Game access outside compat: {entry}')
    print(f'PASS: Interface 30300, {len(load_order)} ordered runtime files and read-only API boundary', flush=True)
    lua_files = sorted((ROOT / 'src').rglob('*.lua')) + sorted((ROOT / 'tests').rglob('*.lua')) + [ROOT / 'libs/Waffle.lua']
    for path in lua_files:
        run([args.luac, '-p', str(path)])
    print(f'PASS: actual Lua 5.1 syntax for {len(lua_files)} files', flush=True)
    run([sys.executable, 'tools/check_phase0.py'])
    run([args.lua, 'tests/run.lua'])
    run([args.lua, 'tests/store-tests.lua'])
    run([args.lua, 'tests/service-tests.lua'])
    run([args.lua, 'tests/destroyer-tests.lua'])
    run([args.lua, 'tests/ui-tests.lua'])
    run([args.lua, 'tests/ui-interaction-tests.lua'])
    with tempfile.TemporaryDirectory(prefix='dejunk-wotlk-check-') as directory:
        first, second = Path(directory) / 'first.zip', Path(directory) / 'second.zip'
        build(first)
        build(second)
        if first.read_bytes() != second.read_bytes():
            raise ValueError('ZIP build is not reproducible')
        with zipfile.ZipFile(first) as archive:
            expected_entries = {'Dejunk-WotLK/' + entry for entry in load_order}
            expected_entries.update({'Dejunk-WotLK/Dejunk-WotLK.toc',
                                     'Dejunk-WotLK/LICENSE', 'Dejunk-WotLK/README.txt',
                                     'Dejunk-WotLK/libs/Waffle-LICENSE.txt'})
            if set(archive.namelist()) != expected_entries or archive.testzip() is not None:
                raise ValueError('ZIP content/layout/CRC check failed')
            for entry in load_order + ['Dejunk-WotLK.toc', 'LICENSE', 'libs/Waffle-LICENSE.txt']:
                if archive.read('Dejunk-WotLK/' + entry) != (ROOT / entry).read_bytes():
                    raise ValueError(f'Packaged file mismatch: {entry}')
        try:
            build(first)
        except ValueError:
            pass
        else:
            raise ValueError('Package command overwrote existing output')
        print('PASS: reproducible ZIP, source content, CRC, layout and overwrite protection')
    print('NOT RUN: original-client UI evidence (WoW client required)')


if __name__ == '__main__':
    try:
        main()
    except (ValueError, OSError, subprocess.CalledProcessError) as exc:
        print(f'FAIL: {exc}', file=sys.stderr)
        sys.exit(1)
