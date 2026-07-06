# Text toolbars

How to assemble a horizontal strip of editing controls — actions,
formatting, attachment, and search — above an editable text area.

> Adapted from the Carbon Design System "Text toolbars" pattern
> (Apache-2.0, carbon-design-system/carbon-website; see NOTICE). Guidance
> is rewritten for Carbide's API.

Carbide has no rich-text editor or dedicated toolbar container; this
pattern is a composition recipe. Upstream also flags its keyword-search
concept as not production-ready.

## The pieces

| Role | Carbide API |
|---|---|
| Action buttons (undo, bold, ...) | `CarbonIconButton` (`kind: CarbonButtonKind.ghost`, built-in tooltip) |
| Typeface / type size menus | `CarbonDropdown` (`inline: true`, `hideLabel: true`) |
| Color / alignment menus | `CarbonMenuButton` or `CarbonOverflowMenu` with `CarbonMenuItem` rows |
| Collapsed controls | `CarbonOverflowMenu` |
| Attach files | `CarbonFileUploaderButton`, listed via `CarbonFileUploaderItem` |
| Keyword search | `CarbonExpandableSearch`; match count in a `CarbonDismissibleTag` |
| Text area | `CarbonTextArea` (plain text only) |
| Save / send | `CarbonButton` |

## Anatomy

Group the controls left to right by purpose, separated by spacing:

1. *Actions* — undo, redo, cut, copy, paste.
2. *Formatting* — typeface and size dropdowns; bold, italic, underline
   toggles (use `CarbonIconButton.isSelected` for the pressed state);
   text color menu.
3. *Paragraph* — alignment, lists, indent controls.
4. *Attachment* — file and link buttons.
5. *Search* — an `CarbonExpandableSearch` at the trailing edge.

Include only the controls your users need; a toolbar is customized by
adding or removing icon buttons, not by disabling rows of unused ones.

## When to use

- Creating and saving simple text quickly.
- Editing with common actions (cut, copy, paste) and text styles.
- Basic find-within-text functionality.
- Attaching files or embedding links in text.

## Behaviors

- *States.* Ghost `CarbonIconButton`s provide enabled, hover, focus,
  pressed, and disabled states; pass `onPressed: null` to disable an
  action that does not currently apply.
- *Attachments.* `CarbonFileUploaderButton` opens the picker; render
  chosen files as `CarbonFileUploaderItem`s beneath the text area, each
  removable via its close control.
- *Links.* Embedding a link needs a small text field revealed by the
  link button — compose a `CarbonPopover` with a `CarbonTextInput`;
  Carbide has no prebuilt link-embed control, and inline links require
  your own rich-text rendering.
- *Search.* Show the match count in a `CarbonDismissibleTag` inside or
  next to the search field; dismissing the tag clears the query.
  Highlighting matches inside `CarbonTextArea` is not supported — the
  area is plain text.
- *Responsiveness.* At wide widths show every control in one row. As
  space shrinks: collapse the search to its icon
  (`CarbonExpandableSearch` does this by default), then move the least
  used controls into a `CarbonOverflowMenu`, then wrap to two rows.
  Drive this with `LayoutBuilder`.
- *Saving.* Offer an explicit "Save draft" `CarbonButton` or autosave;
  either way the primary send/save action sits after the toolbar or
  below the text area, not among the formatting icons.

## Example

```dart
Row(
  children: <Widget>[
    CarbonIconButton(
      icon: CarbonIcons.undo,
      label: 'Undo',
      kind: CarbonButtonKind.ghost,
      size: CarbonButtonSize.sm,
      onPressed: _canUndo ? _undo : null,
    ),
    CarbonIconButton(
      icon: CarbonIcons.textBold,
      label: 'Bold',
      kind: CarbonButtonKind.ghost,
      size: CarbonButtonSize.sm,
      isSelected: _bold,
      onPressed: _toggleBold,
    ),
    const Spacer(),
    CarbonExpandableSearch(placeholder: 'Find', onChanged: _find),
    CarbonOverflowMenu(
      iconDescription: 'More formatting',
      items: <Widget>[
        CarbonMenuItem(label: 'Indent more', onPressed: _indent),
        CarbonMenuItem(label: 'Indent less', onPressed: _outdent),
      ],
    ),
  ],
)
```

## Accessibility

- Every icon-only control needs a tooltip that doubles as its
  accessible name; `CarbonIconButton.label` provides both.
- Wrap the strip in a `Semantics(container: true, label: 'Formatting
  toolbar')` so assistive tech announces the grouping.
- Upstream's toolbar keyboard model (one tab stop, arrow keys between
  controls) has no Carbide container yet; by default each control is
  its own tab stop. Implement roving focus with `FocusTraversalGroup`
  and arrow-key `Shortcuts` if your toolbar grows large.

## Related

- [Overflow content pattern](overflow-content.md) — collapsing controls
- [Search pattern](search.md) — find-in-text behavior
- Gallery: Button, Dropdown, File uploader, Overflow menu pages
