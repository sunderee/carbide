#!/usr/bin/env python3
import copy
from pathlib import Path
import tempfile
import unittest
from carbon_parity import upstream_snapshot, validate

class ParityTests(unittest.TestCase):
    def setUp(self):
        self.data = {'carbonCommit':'abc', 'carbonTag':'v11', 'modules': {'Button': {}},
            'components': {'Button': {'state':'Present','apis':['CarbonButton'],'tier':'curated story','story':'button','note':'Released family contract.'}}}
        self.reference = {'carbonCommit':'abc','carbonTag':'v11'}
    def check(self): validate(self.data, {'CarbonButton': {}}, {'button'}, self.reference)
    def test_valid_review_passes(self): self.check()
    def test_missing_module_decision_fails(self):
        self.data['modules']['New'] = {}
        with self.assertRaisesRegex(ValueError, 'decision'): self.check()
    def test_nonexistent_equivalent_fails(self):
        self.data['components']['Button']['apis'] = ['InventedAPI']
        with self.assertRaisesRegex(ValueError, 'nonexistent'): self.check()
    def test_partial_requires_tracking(self):
        self.data['components']['Button']['state'] = 'Partial'
        with self.assertRaisesRegex(ValueError, 'tracking'): self.check()
    def test_curated_claim_requires_real_story(self):
        self.data['components']['Button']['story'] = 'missing'
        with self.assertRaisesRegex(ValueError, 'curated'): self.check()
    def test_pin_change_requires_review(self):
        self.reference['carbonCommit'] = 'new'
        with self.assertRaisesRegex(ValueError, 'pin'): self.check()
    def test_type_only_and_commented_exports_do_not_add_components(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp); folder=root/'packages/react/src/components/Button';folder.mkdir(parents=True)
            index=root/'packages/react/src/index.ts'
            index.write_text("// export * from './components/Missing';\nexport type { Props } from './components/Props';\nexport * from './components/Button';\n")
            (folder/'index.ts').write_text('export { Button };\n')
            first=upstream_snapshot(root)
            self.assertEqual(set(first['modules']), {'Button'})
            (folder/'index.ts').write_text('export { Button, NewVariant };\n')
            self.assertNotEqual(first, upstream_snapshot(root))
if __name__ == '__main__': unittest.main()
