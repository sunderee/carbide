#!/usr/bin/env python3
"""Regression cases for release tags and the exact packaging-warning allowlist."""

import unittest
from release_verification import assert_dry_run, assert_tag


def warning(paths):
    return (
        "Total compressed archive size: 2 MB.\nValidating package...\n"
        "Package validation found the following potential issue:\n"
        f"* {len(paths)} checked-in files are ignored by a `.gitignore`.\n"
        "  Previous versions of Pub would include those in the published package.\n"
        "  \n"
        "  Consider adjusting your `.gitignore` files to not ignore those files, and if you do not wish to\n"
        "  publish these files use `.pubignore`. See also dart.dev/go/pubignore\n"
        "  \n"
        "  Files that are checked in while gitignored:\n"
        "  \n"
        + "".join(f"  {path}\n" for path in paths)
        + "  \n  \nThe server may enforce additional checks.\n\nPackage has 1 warning.\n"
    )


class ReleaseVerificationTests(unittest.TestCase):
    def test_exact_versions_and_suffixes(self):
        for version in ["0.4.2", "0.5.0-rc.1", "0.5.0+build.7"]:
            assert_tag("v" + version, f"name: carbide\nversion: {version}\n")

    def test_mismatched_or_missing_tags_fail(self):
        for tag in ["v0.5.0", "0.4.2", "v0.4.2-rc.1", "refs/tags/v0.4.2"]:
            with self.subTest(tag=tag), self.assertRaises(ValueError):
                assert_tag(tag, "version: 0.4.2\n")

    def test_invalid_or_ambiguous_package_version_fails(self):
        for spec in ["", "version: 01.2.3", "version: 1.2", "version: latest",
                     "version: 0.4.2-01", "version: 0.4.2-rc..1",
                     "version: 0.4.2\nversion: 0.4.2"]:
            with self.subTest(spec=spec), self.assertRaises(ValueError):
                assert_tag("v0.4.2", spec)

    def test_clean_validation_and_reference_only_warning(self):
        assert_dry_run(0, "Validating package...\nPackage has 0 warnings.\n")
        for paths in [["documentation/carbon"],
                      ["documentation/carbon", "documentation/carbon-design-kit",
                       "documentation/carbon-icons", "documentation/carbon-website",
                       "documentation/plex"]]:
            assert_dry_run(65, warning(paths))

    def test_non_reference_ignored_file_is_rejected(self):
        with self.assertRaises(ValueError):
            assert_dry_run(65, warning(["documentation/carbon", "documentation/secret"]))

    def test_substring_match_cannot_hide_another_warning(self):
        known = warning(["documentation/carbon"])
        for changed in [known + "Error: upload is broken\n",
                        known.replace("Package has 1 warning", "Package has 2 warnings"),
                        known.replace("The server", "* Missing LICENSE.\nThe server"),
                        "Warning: dependency override\n" + known,
                        known + known]:
            with self.subTest(changed=changed), self.assertRaises(ValueError):
                assert_dry_run(65, changed)

    def test_crash_or_inconsistent_count_is_rejected(self):
        known = warning(["documentation/carbon"])
        for code in [1, 69, -9]:
            with self.subTest(code=code), self.assertRaises(ValueError):
                assert_dry_run(code, known)
        for changed in [known.replace("* 1 checked-in", "* 2 checked-in"),
                        warning(["documentation/carbon", "documentation/carbon"])]:
            with self.subTest(changed=changed), self.assertRaises(ValueError):
                assert_dry_run(65, changed)

    def test_success_with_a_diagnostic_is_rejected(self):
        for output in ["Warning: missing metadata\nPackage has 0 warnings.\n",
                       "Package has 0 warnings and 1 hint.\n", ""]:
            with self.subTest(output=output), self.assertRaises(ValueError):
                assert_dry_run(0, output)


if __name__ == "__main__":
    unittest.main()
