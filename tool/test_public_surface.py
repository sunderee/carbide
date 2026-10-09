#!/usr/bin/env python3
"""Export drift guard regressions, including barrel visibility and new APIs."""

import tempfile
import unittest
from pathlib import Path

from public_surface import inventory, validate


class PublicSurfaceTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / 'lib').mkdir()

    def write(self, name, content):
        (self.root / 'lib' / name).write_text(content)

    def test_combinators_union_and_parts(self):
        self.write('carbide.dart', "export 'a.dart' show First;\nexport 'a.dart' show second;\n")
        self.write('a.dart', "part 'part.dart';\nclass First extends StatefulWidget {}\nclass Hidden {}\n")
        self.write('part.dart', 'String second() => "ok";\n')
        result = inventory(self.root)
        self.assertEqual(set(result), {'First', 'second'})
        self.assertTrue(result['First']['visual'])
        self.assertEqual(result['second']['kind'], 'function')
        self.write('carbide.dart', "export 'a.dart' hide Hidden;\n")
        self.assertEqual(set(inventory(self.root)), {'First', 'second'})

    def test_comments_strings_members_and_indirect_widgets(self):
        self.write('carbide.dart', "export 'a.dart';")
        self.write('a.dart', '''
/* nested /* class Fake {} */ comment */
class Base extends StatelessWidget {
  String member() => 'class AlsoFake {}';
}
class Real extends Base {}
class _Private extends Base {}
typedef Callback = void Function();
String get title => 'Title';
int publicCounter = 0;
final String publicName = 'Name';
''')
        result = inventory(self.root)
        self.assertEqual(set(result), {'Base', 'Real', 'Callback', 'title', 'publicCounter', 'publicName'})
        self.assertTrue(result['Real']['visual'])

    def test_new_function_requires_classification_without_writing(self):
        self.write('carbide.dart', 'class Original {}\n')
        manifest = {'exports': inventory(self.root), 'families': {}}
        self.write('carbide.dart', 'class Original {}\nvoid newlyPublic() {}\n')
        before = (self.root / 'lib/carbide.dart').read_bytes()
        with self.assertRaisesRegex(ValueError, 'newlyPublic'):
            validate(inventory(self.root), manifest, set())
        self.assertEqual((self.root / 'lib/carbide.dart').read_bytes(), before)

    def test_missing_specimen_or_exemption_fails(self):
        with self.assertRaisesRegex(ValueError, 'missing specimen'):
            validate({}, {'exports': {}, 'families': {'button': {'specimens': ['button']}}}, set())
        with self.assertRaisesRegex(ValueError, 'reasoned exemption'):
            validate({}, {'exports': {}, 'families': {'button': {}}}, set())
        with self.assertRaisesRegex(ValueError, 'missing open-state action'):
            validate({}, {'exports': {}, 'families': {'button': {'specimens': ['button'], 'open': ['button']}}}, {'button'}, set())


if __name__ == '__main__':
    unittest.main()
