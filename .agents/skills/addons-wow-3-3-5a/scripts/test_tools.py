"""Offline regression tests for portable auditing/packaging; no WoW API calls."""
from pathlib import Path
import tempfile
import unittest
import zipfile
from audit_addon import audit, load_graph
from package_addon import build


class PortableToolsTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.base = Path(self.temp.name)
        self.root = self.base / 'Example'
        self.root.mkdir()
        (self.root / 'Example.toc').write_text('## Interface: 30300\nCore.lua\n')
        (self.root / 'Core.lua').write_text('local addonName, Addon = ...\n')

    def tearDown(self):
        self.temp.cleanup()

    def test_valid_graph_and_modern_calls_are_review_warnings(self):
        result = audit(self.root)
        self.assertEqual(result['errors'], [])
        self.assertEqual(result['lua_syntax'], 'not run')
        (self.root / 'Core.lua').write_text('local x = C_Container.GetContainerItemInfo(0, 1)\n')
        result = audit(self.root)
        self.assertFalse(result['errors'])
        self.assertTrue(any('C_Container' in value for value in result['warnings']))

    def test_wrong_interface_and_missing_file_fail(self):
        (self.root / 'Example.toc').write_text('## Interface: 30403\nCore.lua\n')
        self.assertTrue(audit(self.root)['errors'])
        (self.root / 'Core.lua').unlink()
        self.assertTrue(audit(self.root)['errors'])

    def test_escape_and_symlink_are_rejected(self):
        outside = self.base / 'Outside.lua'
        outside.write_text('return true\n')
        (self.root / 'Example.toc').write_text('## Interface: 30300\n../Outside.lua\n')
        self.assertTrue(audit(self.root)['errors'])
        (self.root / 'Example.toc').write_text('## Interface: 30300\nLink.lua\n')
        (self.root / 'Link.lua').symlink_to(outside)
        self.assertTrue(audit(self.root)['errors'])

    def test_xml_dependencies_and_cycles(self):
        (self.root / 'Example.toc').write_text('## Interface: 30300\nUI.xml\n')
        (self.root / 'UI.xml').write_text('<Ui><Script file="Core.lua"/></Ui>')
        result = audit(self.root)
        self.assertFalse(result['errors'])
        self.assertIn('Core.lua', result['files'])
        (self.root / 'UI.xml').write_text('<Ui><Include file="UI.xml"/></Ui>')
        self.assertTrue(audit(self.root)['errors'])

    def test_multiple_tocs_require_a_choice(self):
        (self.root / 'Example.toc').rename(self.root / 'Original.toc')
        (self.root / 'Other.toc').write_text('## Interface: 30300\nCore.lua\n')
        self.assertTrue(audit(self.root)['errors'])
        self.assertFalse(audit(self.root, 'Original.toc')['errors'])

    def test_zip_determinism_and_overwrite_guard(self):
        first, second = self.base / 'first.zip', self.base / 'second.zip'
        (self.root / 'LICENSE').write_text('Fixture license\n')
        self.assertEqual(build(self.root, first, includes=['LICENSE']), 3)
        build(self.root, second, includes=['LICENSE'])
        self.assertEqual(first.read_bytes(), second.read_bytes())
        with zipfile.ZipFile(first) as archive:
            self.assertEqual(archive.testzip(), None)
            self.assertIn('Example/Core.lua', archive.namelist())
            self.assertIn('Example/LICENSE', archive.namelist())
        with self.assertRaises(ValueError):
            build(self.root, first)

    def test_personal_data_is_not_packaged(self):
        (self.root / 'WTF').mkdir()
        (self.root / 'WTF' / 'account.lua').write_text('private = true\n')
        with self.assertRaises(ValueError):
            build(self.root, self.base / 'bad.zip', includes=['WTF'])
        (self.root / 'assets').mkdir()
        (self.root / 'assets' / 'icon.tga').write_bytes(b'fixture')
        (self.root / 'assets' / 'old.zip').write_bytes(b'not a release')
        out = self.base / 'safe.zip'
        build(self.root, out, includes=['assets'])
        with zipfile.ZipFile(out) as archive:
            self.assertIn('Example/assets/icon.tga', archive.namelist())
            self.assertNotIn('Example/assets/old.zip', archive.namelist())


if __name__ == '__main__':
    unittest.main(verbosity=2)
