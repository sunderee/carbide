# Disclosures

Small surfaces that open over the page — profile menus, settings and
filter panels, combo buttons — built from a trigger plus a popover.

> Adapted from the Carbon Design System "Disclosures" pattern
> (Apache-2.0, carbon-design-system/carbon-website; see NOTICE). Guidance
> is rewritten for Carbide's API.

## The pieces

| Role | Carbide API |
|---|---|
| Popover container | `CarbonPopover` (`open`, `align`, `caret`, `dropShadow`) |
| Icon-only trigger | `CarbonIconButton`; in the shell, `CarbonHeaderGlobalAction` |
| Text + interactive popover | `CarbonToggletip` (`actions`) |
| Action menus | `CarbonOverflowMenu`, `CarbonMenuButton`, `CarbonMenu` + `CarbonMenuItem` |
| Primary action + menu | `CarbonComboButton` |
| Right-side shell panel | `CarbonHeaderPanel`, `CarbonSwitcher` |
| Popover contents | `CarbonCheckbox`, `CarbonRadioButtonGroup`, `CarbonSearch`, `CarbonButton`, ... |

## Overview

A disclosure has two parts: a trigger the user clicks (or activates with
Enter/Space) and a container that opens with related content. Unlike a
`CarbonTooltip`, the disclosed content may be interactive — checkboxes,
radio groups, links, buttons.

Use a disclosure to reveal secondary detail about part of the UI, to
host settings/filter/sort controls near what they affect, or for
dropdown-like surfaces (profile menus, combo buttons, menu buttons). Do
not use one for critical information or required input — that is a
modal's job ([Dialogs](dialog.md)) — and never open one the user didn't
trigger.

## Best practices

- **Keep it small.** A disclosure is a moment, not a screen takeover.
  Trim the content to what the task needs.
- **One at a time.** Opening a disclosure should close any other; two
  open popovers compete for attention.
- **Don't nest.** A popover inside a popover stacks confusingly. Submenu
  fly-outs inside a `CarbonContextMenu` are the acceptable exception.
- **Nothing critical inside.** If the user needs it to finish the task,
  keep it at page level where it is visible.
- **Dismissal.** Close on a second trigger press, an outside tap, or
  Escape — `CarbonPopover`-based components wire Escape and outside-tap
  handling; keep your `open` state in sync via the close callbacks. If
  you add a close `x`, put it in the top-right corner, clear of other
  interactive elements.

## Common use cases

### Profile menu

An icon trigger in the shell header (`CarbonHeaderGlobalAction` with
`CarbonIcons.userAvatar`) disclosing account and session content:
identity block at top, optional divided sections of contextual
information, then navigational menu items and log out. For full-height
account/switcher content, `CarbonHeaderPanel` with `CarbonSwitcher` is
the shell-native surface.

### Settings and filter menus

A `CarbonIconButton` (`CarbonIcons.settings`, `CarbonIcons.filter`) —
commonly in a `CarbonTableToolbar` — opens a `CarbonPopover` holding the
controls that adjust nearby content. When live filtering isn't feasible,
end the popover with a Cancel/Apply `CarbonButton` pair and apply changes
on Apply. Keep at least 16px (`CarbonSpacing.spacing05`) between
interactive elements.

```dart
CarbonPopover(
  open: _filtersOpen,
  align: CarbonPopoverAlignment.bottomEnd,
  onRequestClose: () => setState(() => _filtersOpen = false),
  child: CarbonIconButton(
    icon: CarbonIcons.filter,
    label: 'Filter',
    kind: CarbonButtonKind.ghost,
    onPressed: () => setState(() => _filtersOpen = !_filtersOpen),
  ),
  content: CarbonCheckboxGroup(
    legend: 'Status',
    children: <Widget>[
      CarbonCheckbox(label: 'Running', value: _running,
          onChanged: _setRunning),
      CarbonCheckbox(label: 'Stopped', value: _stopped,
          onChanged: _setStopped),
    ],
  ),
)
```

### Combo button

`CarbonComboButton` pairs a primary default action with an attached icon
trigger that discloses related actions in a menu. Put the most-used
action in the primary button — never bury it in the menu — and keep the
labels text-only; extra icons add noise. Use `CarbonMenuItemDivider` to
separate groups of related actions, and `CarbonMenuItemKind.danger` for
destructive ones.

## Keyboard and screen readers

- `Tab` reaches the trigger; `Enter`/`Space` opens the disclosure.
- On open, focus moves to the first interactive element; menus arrow
  through items with `Up`/`Down`, panels move with `Tab`.
- `Esc` closes and returns focus to the trigger.

Carbide's popover-based components implement this; when composing your
own content inside `CarbonPopover`, keep the tab order top-to-bottom.

## Related

- [Dialogs pattern](dialog.md) — when the content is required, not
  optional
- [Common actions pattern](common-actions.md) — actions inside menus
- Gallery: Popover, Toggletip, Overflow menu, Menu buttons pages
