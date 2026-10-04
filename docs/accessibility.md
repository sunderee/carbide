# Accessibility semantics

Carbide uses Flutter's public semantics APIs. Applications supply the meaning
of their content and localized labels. This policy covers static tags, lists,
and code snippets; platform preferences are described in
[theming and layers](theming-and-layers.md#increased-contrast-accessibility)
and [loading motion](patterns/loading.md#accessibility).

## Static tags

`CarbonTag.label` is ordinary accessible text, including the complete label
when the visible pill truncates it. Disabled styling does not hide that text
or turn a static tag into a control. Leading icons are decorative; communicate
status in words rather than relying on a color or icon alone.

The #318 investigation found that a status such as “Active” was already
present once in the semantics tree. An extra component `semanticLabel` or
`status` parameter is therefore unnecessary. To provide context, replace the
label using Flutter's existing API:

```dart
Semantics(
  label: 'Service status: Active',
  excludeSemantics: true,
  child: const CarbonTag(label: 'Active'),
);
```

Use `ExcludeSemantics` around a tag only when it repeats information already
available nearby or is purely decorative. Do not exclude the only status
label. Static tags do not announce updates automatically; applications decide
whether a changing status needs a localized live region.

## Lists

`CarbonOrderedList` and `CarbonUnorderedList` provide
`SemanticsRole.list` containers and `SemanticsRole.listItem` nodes for their
direct children. Nested lists keep their own containers. Item traversal follows
the supplied order in LTR and RTL. Text, visible markers and interactive child
controls remain available; controls keep their own actions rather than being
merged into one list label. Empty lists have no item nodes, and Flutter may
omit their zero-area container.

Before #318, list content and markers were readable, but there were no list
roles. The supported roles now supply that missing structure without adding
synthetic “item N of M” strings. With Flutter 3.47.6, the web backend exposes
`role="list"` and `role="listitem"`, including the nested DOM hierarchy.
It does not emit `aria-setsize`, `aria-posinset` or an explicit nesting-depth
attribute for these widgets. The hierarchy and direct child counts are present;
the exact spoken count, position or depth depends on the browser and assistive
technology. Carbide does not promise a particular announcement.

## Code snippets

Single- and multi-line snippets expose their code text. Copy and expand
controls remain separate actions. The full multi-line text remains available
when the visual block is collapsed. A copyable inline snippet exposes one
button label combining `copyLabel` and the code; a non-copyable inline snippet
exposes plain text. Use localized `copyLabel`, `showMoreText` and
`showLessText` values where needed.

Snippets do not create landmarks automatically: an inline token inside prose
does not need its own landmark. For an important standalone block, the caller
supplies a useful contextual region name while preserving the code and controls:

```dart
Semantics(
  role: SemanticsRole.region,
  container: true,
  explicitChildNodes: true,
  label: 'Install command',
  child: const CarbonCodeSnippet(code: 'flutter pub add carbide'),
);
```

Do not repeat the code in the region label or exclude the snippet's children;
either can produce duplicated content or hide its actions. A heading may be
more appropriate when the block belongs to an already named section.

## Investigation and platform scope

The #318 policy is backed by
[`static_semantics_test.dart`](../test/components/static_semantics_test.dart)
and the gallery's
[native web test](../example/integration_test/static_semantics_test.dart).
The VM dumps and browser DOM/accessibility tree cover ordinary, disabled,
truncated and excluded tags; flat/nested ordered and unordered lists;
interactive list children; all snippet variants; and code-region composition.

Representative structure, omitting layout nodes:

```text
tag: text "Active"                          (no action)
list                                      (role=list)
  item                                    (role=listItem)
    text "1."
    text "Parent"
    list                                  (role=list)
      item -> text "a.", text "Nested Alpha"
      item -> text "b.", text "Nested Beta"
  item -> text "2.", text "Sibling"
region "Install command"                  (role=region, caller supplied)
  text "flutter pub add carbide"
  button "Copy to clipboard"
```

Browser validation establishes roles, content, nesting and working actions.
TalkBack and VoiceOver spoken output has not been evaluated in this
investigation; device testing was waived for #318. No Safari MCP server was
available. These observations do not claim spoken screen-reader results.

Flutter documents the platform mapping in
[`SemanticsRole`](https://api.flutter.dev/flutter/dart-ui/SemanticsRole.html)
and the composition APIs in
[`Semantics`](https://api.flutter.dev/flutter/widgets/Semantics-class.html).
