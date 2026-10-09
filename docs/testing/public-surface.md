# Public surface and shared specimens

The export inventory in `tool/public_surface.json` records declarations reachable
from `lib/carbide.dart`, including part files and top-level functions. Every
source family has representative scaling/RTL specimens or a reasoned exemption.
Compositions exercise their building blocks; the inventory does not claim that
one specimen tests every variant of every widget.

Run `python3 tool/test_public_surface.py` and
`python3 tool/public_surface.py --check` before committing an export change.
The check is nonmutating: a newly exported declaration fails until its inventory
entry and family classification have been reviewed. Do not regenerate this file
blindly to silence the check. Add the builder to `test/support/specimens.dart`
and record its name under the family's `specimens`; use `open` for a matching
open-state action. Only nonvisual declarations or explicitly justified visual
compositions may be exempted.

The scanner follows local export and part directives, honors `show`/`hide`,
unions repeated exports, masks comments/strings, and resolves local widget base
classes. It is a lexical inventory, not a substitute for `flutter analyze`.
External export URIs require a scanner update and explicit review.

The scaling sweep checks 1.3× and 2× glyph-line height and includes open overlays
in both LTR and RTL. Each open action asserts a popup-only marker before checking
layout, so an unchanged closed trigger cannot count as coverage. The RTL sweep
also builds every closed specimen and retains dedicated keyboard/anchor checks.

The shared host supplies a 1400×1000 logical viewport, an overlay, a media query,
and focus traversal. Chrome's test canvas can remain physically 800×600; these
are layout/behavior checks rather than web pixel baselines. Linux widget goldens
remain the pixel authority, and release-browser checks validate actual fonts,
native focus, and visible bounds.
