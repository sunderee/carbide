# Release metadata decisions

The gallery's web manifest and HTML identify Carbide, use its neutral/blue
palette and permit any orientation. A repository-owned vector C mark replaces
the Flutter starter icon in the browser/manifest. Chromium metadata and image
decoding are checked manually; no platform installation behavior is implied.

The pubspec declares three listing screenshots copied byte-for-byte from the
Linux-authoritative review images. They live under `screenshots/` so `.pubignore`
can continue excluding contributor docs while including the listing assets.
The Linux regeneration workflow refreshes both locations; the metadata guard
checks their equality and PNG dimensions. Strict pub validation checks the
actual archive and screenshot declarations. The listing changes after a
separately authorized publication, not when a PR is created.

The root security policy links private GitHub vulnerability reporting. The
repository setting is enabled as part of this preparation; ordinary bugs stay
in public issues. CODEOWNERS names the repository owner. Weekly grouped
Dependabot updates are limited to GitHub Actions, with at most three open PRs.
Pub/Flutter upgrades remain deliberate because SDK floors, reference captures
and goldens need joint review; no automatic dependency merge is configured.

Root pubspec/lock changes trigger gallery deployment. Deployment consumes the
shared verified build artifact and depends on the complete verification graph.
Font attribution states the seven files actually bundled, not the broader Plex
catalog. See [source-derived reference facts](reference-facts.md).

This prepares metadata and review automation for 0.5.0. It does not create a
release tag, publish a package, or change the package version.
