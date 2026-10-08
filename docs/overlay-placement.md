# Anchored overlay placement

Pickers and anchored action menus prefer the bottom side, flip to the roomier
side when that placement does not fit, and clamp the surface to the nearest
hosting Overlay. The surface receives that overlay's bounded width and height;
option lists and action menus remain scrollable when the available viewport
is smaller than their ordinary fold. When neither side can fit the surface,
placement stays inside the viewport and may overlap the trigger.

Start/end alignment is logical horizontally. Submenus prefer the logical end
side and flip away from an edge. Popover primary left/right alignments retain
their existing physical meaning; their start/end suffixes remain logical.
`CarbonPopover.autoAlign` opts into the shared policy, including clamping and
keeping the caret directed toward the trigger. Its default `false` retains
fixed placement.

Omitting `CarbonDropdown.direction` now enables automatic placement, preferring
bottom. Explicit `CarbonDropdownDirection.top` or `.bottom` pins that side,
including when the caller intentionally permits main-axis overflow. The public
`direction` getter remains non-null and defaults to bottom. Select, combo box,
multi-select, overflow menu, menu button and combo button offer `menuSide`:

```dart
CarbonSelect<String>(
  labelText: 'City',
  menuSide: CarbonOverlaySide.top,
  items: const [CarbonSelectItem(value: 'tallinn', label: 'Tallinn')],
  onChanged: (value) {},
)
```

A null `menuSide` enables automatic placement. Explicit sides pin the main
axis; cross-axis clamping still applies. `start`/`end` resolve from Directionality.

The shared follower resolves geometry once per composed frame using the
leader's current layer transform. Retained ancestor scroll transforms therefore
update placement without rebuilding option rows, polling, scheduling idle frames,
or installing a listener on every ancestor scrollable. Resize updates both the
surface constraints and placement. Pointer and semantics transforms use the
same follower layer. Picker portal ownership remains unchanged, including the
persistent transparent web anchor that preserves native editor focus.

The regression suite covers corners, RTL, scroll, resize, side pinning,
submenu collision, bounded-menu keyboard reveal and device-pixel ratio 2.
Its retained-scroll measurement counts 60 placements over 60 frames with zero
popup rebuilds and no scheduled idle frame; observational whole-test-frame
timing is printed separately and is not a CI performance limit.
