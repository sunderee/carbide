#!/usr/bin/env python3
"""Unstamped or modified reference bytes must fail provenance checks."""

import hashlib
from pathlib import Path
import tempfile
import unittest
from check_reference_images import verify_images


class ReferenceImagesTest(unittest.TestCase):
    def test_changed_and_unstamped_bytes_fail(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            (directory / 'button').mkdir()
            image = directory / 'button/white.png'
            image.write_bytes(b'reference')
            manifest = {'stories': [{'component': 'button'}], 'themes': ['white'], 'imageSha256': {'button/white.png': hashlib.sha256(b'reference').hexdigest()}}
            self.assertEqual(verify_images(manifest, directory), 1)
            image.write_bytes(b'changed')
            with self.assertRaisesRegex(ValueError, 'Reference bytes differ'):
                verify_images(manifest, directory)
            manifest['imageSha256'] = {}
            with self.assertRaisesRegex(ValueError, 'Every reference image'):
                verify_images(manifest, directory)


if __name__ == '__main__':
    unittest.main()
