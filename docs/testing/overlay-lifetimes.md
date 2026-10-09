# Overlay lifetime coverage

`test/leaks/overlay_lifetime_test.dart` runs the same lifecycle for each scenario:
open the surface, assert a popup-only marker, close it, assert removal, reopen,
then replace the entire host while it is open. Three seconds of pumped time
after removal exercises delayed feedback and hover work; the host must have no
transient callbacks or retained popup widgets.

The suite-wide leak tracker remains the oracle for undisposed objects, focus
nodes and controllers. Flutter's test binding checks pending timers. The harness
disposes its own overlay entry, semantics handle, controlled-state notifier and
mouse gesture. Controlled dialog/popover cases change the supplied open value;
uncontrolled controls use their trigger, Escape, outside dismissal or feedback
timeout as appropriate. Component suites separately verify those interactions.

`tool/overlay_lifetimes.json` maps every source that constructs an `OverlayPortal`
or `OverlayPortalController` to its scenarios. The scanner masks strings and
comments; references to a borrowed controller do not invent another owner.
Delegating components still have scenarios: combo/multi-select use the shared
picker portal, and date pickers, header menus, AI labels and copy feedback use
the popover owner. Header submenus exercise the additional menu portal.

Run `python3 tool/test_overlay_lifetimes.py` and
`python3 tool/check_overlay_lifetimes.py` when adding a portal. A new owner or a
missing table entry fails CI until the lifecycle scenario is added and reviewed.
