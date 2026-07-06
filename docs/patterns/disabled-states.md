# Disabled states

When a control must be present but not usable — and how to choose
between disabling it, showing it read-only, or hiding it entirely.

> Adapted from the Carbon Design System "Disabled states" pattern
> (Apache-2.0, carbon-design-system/carbon-website; see NOTICE). Guidance
> is rewritten for Carbide's API.

## The pieces

| Role | Carbide API |
|---|---|
| Disable a button | `CarbonButton(onPressed: null)` (also `CarbonIconButton`, `CarbonLink`) |
| Disable selection controls | `CarbonCheckbox(onChanged: null)`, `CarbonToggle(onToggled: null)` |
| Disable field components | `disabled: true` on `CarbonTextInput`, `CarbonTextArea`, `CarbonNumberInput`, `CarbonDropdown`, `CarbonSlider`, `CarbonSelect`, ... |
| Disable a whole group | `CarbonFormGroup` / `CarbonField` `disabled` |
| Read-only alternative | `readOnly: true` — see [Read-only states](read-only-states.md) |
| Explain why | `CarbonInlineNotification` (warning kind) |

## The three variations

| Variation | Behavior |
|---|---|
| Default disabled | Cannot be operated. Carbide keeps the widget in the semantics tree but flags it not-enabled, so assistive tech announces it as dimmed. Styled with disabled tokens; no hover or focus response. |
| Read-only | Content stays legible, passes contrast, and remains reachable by keyboard and screen reader — only the ability to change it is removed. |
| Hidden | The widget is not built at all. The user never learns the option exists. |

## Default disabled

Use when a control is *temporarily* unusable because of a dependency or
an unmet prerequisite — something the user (or the system) can still
resolve. The control stays visible so the user knows it exists and can
infer what unlocks it; it returns to normal once the blocker clears.

Carbide has two disabling conventions, mirroring Flutter idiom:

- **Callback-null**: interactive widgets whose whole purpose is a
  callback disable when it is absent — `CarbonButton(onPressed: null)`,
  `CarbonCheckbox(onChanged: null)`, `CarbonToggle(onToggled: null)`.
- **`disabled: true`**: field components (`CarbonTextInput`,
  `CarbonDropdown`, `CarbonNumberInput`, and friends) keep their
  callbacks in place and take an explicit flag.

Styling is automatic. Disabled Carbon components swap to the theme's
disabled tokens (`textDisabled`, `iconDisabled`, transparent borders) —
never fake a disabled look by wrapping widgets in `Opacity`.

```dart
CarbonCheckbox(
  label: 'Enable replication',
  value: _replication,
  onChanged: _planSupportsReplication
      ? (bool v) => setState(() => _replication = v)
      : null,
)
```

### Explain the blocker when it matters

If a disabled control gates the flow's primary action or affects several
items, add a warning `CarbonInlineNotification` telling the user what to
do to re-enable it. A lone disabled button with no explanation is a dead
end.

## Read-only instead of disabled

If the user still needs the *content* of the control — to review values
they cannot change — disabled is the wrong tool: disabled styling fails
contrast and reads as irrelevant. Use the component's `readOnly`
parameter instead, which keeps text at full contrast and keeps the value
accessible. The full decision guide lives in
[Read-only states](read-only-states.md).

## Hidden

Use when permissions mean the user may never see the option at all — an
"Add member" button only organization owners get. In Flutter this is
simply conditional building:

```dart
if (user.isOwner)
  CarbonButton(label: 'Add member', onPressed: _addMember),
```

Hide for *permission* differences; disable for *temporary* blockers. A
control the user could unlock through their own action should stay
visible and disabled, never vanish.

## Related

- [Read-only states pattern](read-only-states.md) — the accessible
  sibling of disabled
- [Forms pattern](forms.md) — why submit buttons should rarely be
  disabled
- [Notifications pattern](notification.md) — warning surfaces
