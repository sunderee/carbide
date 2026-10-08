// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the
// Apache License, Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';

import '../demo_scaffold.dart';
import '../examples/source_literals.dart';
import '../examples/button_example.dart';
import '../knobs.dart';
import '../registry.dart';

part 'tier_a_pages.examples.g.dart';

/// Tier A — the foundational components.
final GalleryCategory tierACategory = GalleryCategory(
  title: 'Foundational',
  icon: CarbonIcons.grid,
  entries: <GalleryEntry>[
    GalleryEntry(
      slug: 'button',
      title: 'Button',
      builder: () => const _ButtonPage(),
    ),
    GalleryEntry(
      slug: 'copy-button',
      title: 'Copy button',
      builder: () => const _CopyButtonPage(),
    ),
    GalleryEntry(
      slug: 'code-snippet',
      title: 'Code snippet',
      builder: () => const _CodeSnippetPage(),
    ),
    GalleryEntry(
      slug: 'icon-button',
      title: 'Icon button',
      builder: () => const _IconButtonPage(),
    ),
    GalleryEntry(
      slug: 'indicators',
      title: 'Indicators',
      builder: () => const _IndicatorsPage(),
    ),
    GalleryEntry(
      slug: 'aspect-ratio',
      title: 'Aspect ratio',
      builder: () => const _AspectRatioPage(),
    ),
    GalleryEntry(slug: 'grid', title: 'Grid', builder: () => const _GridPage()),
    GalleryEntry(
      slug: 'skeletons',
      title: 'Skeletons',
      builder: () => const _SkeletonsPage(),
    ),
    GalleryEntry(slug: 'tag', title: 'Tag', builder: () => const _TagPage()),
    GalleryEntry(slug: 'link', title: 'Link', builder: () => const _LinkPage()),
    GalleryEntry(slug: 'tile', title: 'Tile', builder: () => const _TilePage()),
    GalleryEntry(
      slug: 'loading',
      title: 'Loading',
      builder: () => const _LoadingPage(),
    ),
    GalleryEntry(
      slug: 'progress-bar',
      title: 'Progress bar',
      builder: () => const _ProgressBarPage(),
    ),
    GalleryEntry(slug: 'list', title: 'List', builder: () => const _ListPage()),
    GalleryEntry(
      slug: 'stack',
      title: 'Stack',
      builder: () => const _StackPage(),
    ),
    GalleryEntry(
      slug: 'heading',
      title: 'Heading',
      builder: () => const _HeadingPage(),
    ),
  ],
);

class _ButtonPage extends StatefulWidget {
  const _ButtonPage();
  @override
  State<_ButtonPage> createState() => _ButtonPageState();
}

class _ButtonPageState extends State<_ButtonPage> {
  CarbonButtonKind _kind = CarbonButtonKind.primary;
  CarbonButtonSize _size = CarbonButtonSize.lg;
  bool _withIcon = false;
  bool _enabled = true;
  bool _expressive = false;

  @override
  Widget build(BuildContext context) {
    final ButtonExample example = ButtonExample(
      kind: _kind,
      size: _size,
      withIcon: _withIcon,
      enabled: _enabled,
      expressive: _expressive,
    );
    return DemoScaffold(
      title: 'Button',
      description: 'Eight kinds across six sizes, with an optional icon.',
      preview: example.build(),
      controls: <Widget>[
        choiceKnob<CarbonButtonKind>(
          label: 'Kind',
          value: _kind,
          options: CarbonButtonKind.values,
          labelOf: (CarbonButtonKind k) => k.name,
          onChanged: (CarbonButtonKind k) => setState(() => _kind = k),
        ),
        choiceKnob<CarbonButtonSize>(
          label: 'Size',
          value: _size,
          options: CarbonButtonSize.values,
          labelOf: (CarbonButtonSize s) => s.name,
          onChanged: (CarbonButtonSize s) => setState(() => _size = s),
        ),
        boolKnob(
          label: 'With icon',
          value: _withIcon,
          onChanged: (bool v) => setState(() => _withIcon = v),
        ),
        boolKnob(
          label: 'Expressive',
          value: _expressive,
          onChanged: (bool v) => setState(() => _expressive = v),
        ),
        boolKnob(
          label: 'Enabled',
          value: _enabled,
          onChanged: (bool v) => setState(() => _enabled = v),
        ),
      ],
      code: example.code,
    );
  }
}

class _TagPage extends StatefulWidget {
  const _TagPage();
  @override
  State<_TagPage> createState() => _TagPageState();
}

class _TagPageState extends State<_TagPage> {
  CarbonTagType _type = CarbonTagType.blue;
  bool _selected = false;

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Tag',
      description: 'Read-only, dismissible, selectable and operational tags.',
      preview: Wrap(
        spacing: CarbonSpacing.spacing03,
        runSpacing: CarbonSpacing.spacing03,
        children: <Widget>[
          CarbonTag(label: 'Read-only', type: _type, icon: CarbonIcons.user),
          CarbonDismissibleTag(
            label: 'Dismissible',
            type: _type,
            onClose: () {},
          ),
          CarbonSelectableTag(
            label: 'Selectable',
            selected: _selected,
            onChanged: (bool v) => setState(() => _selected = v),
          ),
          CarbonOperationalTag(
            label: 'Operational',
            type: _type,
            onPressed: () {},
          ),
        ],
      ),
      controls: <Widget>[
        choiceKnob<CarbonTagType>(
          label: 'Type',
          value: _type,
          options: CarbonTagType.values,
          labelOf: (CarbonTagType t) => t.name,
          onChanged: (CarbonTagType t) => setState(() => _type = t),
        ),
      ],
      code: exampleSource,
    );
  }
}

class _LinkPage extends StatefulWidget {
  const _LinkPage();
  @override
  State<_LinkPage> createState() => _LinkPageState();
}

class _LinkPageState extends State<_LinkPage> {
  CarbonLinkSize _size = CarbonLinkSize.md;
  bool _inline = false;
  bool _withIcon = false;
  bool _enabled = true;

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Link',
      description: 'Inline or standalone navigation, three sizes.',
      preview: CarbonLink(
        label: 'Learn more',
        size: _size,
        inline: _inline,
        icon: _withIcon ? CarbonIcons.launch : null,
        onPressed: _enabled ? () {} : null,
      ),
      controls: <Widget>[
        choiceKnob<CarbonLinkSize>(
          label: 'Size',
          value: _size,
          options: CarbonLinkSize.values,
          labelOf: (CarbonLinkSize s) => s.name,
          onChanged: (CarbonLinkSize s) => setState(() => _size = s),
        ),
        boolKnob(
          label: 'Inline',
          value: _inline,
          onChanged: (bool v) => setState(() => _inline = v),
        ),
        boolKnob(
          label: 'With icon',
          value: _withIcon,
          onChanged: (bool v) => setState(() => _withIcon = v),
        ),
        boolKnob(
          label: 'Enabled',
          value: _enabled,
          onChanged: (bool v) => setState(() => _enabled = v),
        ),
      ],
      code: exampleSource,
    );
  }
}

class _TilePage extends StatefulWidget {
  const _TilePage();
  @override
  State<_TilePage> createState() => _TilePageState();
}

class _TilePageState extends State<_TilePage> {
  bool _selected = false;
  bool _expanded = false;
  bool _ai = false;
  int _radio = 0;

  Widget? get _aiLabel =>
      _ai ? const CarbonAILabel(size: CarbonAILabelSize.mini) : null;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData t = CarbonTheme.of(context);
    Widget body(String s) => Text(
      s,
      style: CarbonTypeStyles.bodyCompact01.copyWith(color: t.textPrimary),
    );
    return DemoScaffold(
      title: 'Tile',
      description: 'Base, clickable, selectable, radio and expandable tiles.',
      previewAlignment: Alignment.topLeft,
      preview: Wrap(
        spacing: CarbonSpacing.spacing05,
        runSpacing: CarbonSpacing.spacing05,
        children: <Widget>[
          SizedBox(
            width: 220,
            child: CarbonTile(aiLabel: _aiLabel, child: body('Base tile')),
          ),
          SizedBox(
            width: 220,
            child: CarbonClickableTile(
              icon: CarbonIcons.launch,
              onPressed: () {},
              aiLabel: _aiLabel,
              child: body('Clickable tile'),
            ),
          ),
          SizedBox(
            width: 220,
            child: CarbonSelectableTile(
              selected: _selected,
              onChanged: (bool v) => setState(() => _selected = v),
              aiLabel: _aiLabel,
              child: body('Selectable tile'),
            ),
          ),
          SizedBox(
            width: 220,
            child: Column(
              children: <Widget>[
                for (int i = 0; i < 2; i++)
                  Padding(
                    padding: EdgeInsets.only(
                      top: i == 0 ? 0 : CarbonSpacing.spacing02,
                    ),
                    child: CarbonRadioTile(
                      selected: _radio == i,
                      onSelected: () => setState(() => _radio = i),
                      aiLabel: _aiLabel,
                      child: body('Radio tile ${i + 1}'),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 220,
            child: CarbonExpandableTile(
              expanded: _expanded,
              onExpandedChanged: (bool v) => setState(() => _expanded = v),
              aiLabel: _aiLabel,
              aboveTheFold: body('Expandable tile'),
              belowTheFold: body('Hidden detail revealed on expand.'),
            ),
          ),
        ],
      ),
      controls: <Widget>[
        boolKnob(
          label: 'AI label',
          value: _ai,
          onChanged: (bool v) => setState(() => _ai = v),
        ),
      ],
      code: exampleSource,
    );
  }
}

class _LoadingPage extends StatelessWidget {
  const _LoadingPage();
  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Loading',
      description: 'The spinner and inline loading states.',
      preview: const Wrap(
        spacing: CarbonSpacing.spacing09,
        runSpacing: CarbonSpacing.spacing07,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          CarbonLoading(),
          CarbonLoading(small: true),
          CarbonInlineLoading(description: 'Loading…'),
          CarbonInlineLoading(
            status: CarbonInlineLoadingStatus.finished,
            description: 'Done',
          ),
        ],
      ),
      code: exampleSource,
    );
  }
}

class _ProgressBarPage extends StatefulWidget {
  const _ProgressBarPage();
  @override
  State<_ProgressBarPage> createState() => _ProgressBarPageState();
}

class _ProgressBarPageState extends State<_ProgressBarPage> {
  double _value = 40;
  bool _indeterminate = false;

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Progress bar',
      description: 'Determinate and indeterminate progress.',
      preview: SizedBox(
        width: 320,
        child: CarbonProgressBar(
          label: 'Uploading',
          helperText: _indeterminate ? null : '${_value.round()}%',
          value: _indeterminate ? null : _value,
        ),
      ),
      controls: <Widget>[
        boolKnob(
          label: 'Indeterminate',
          value: _indeterminate,
          onChanged: (bool v) => setState(() => _indeterminate = v),
        ),
        if (!_indeterminate)
          sliderKnob(
            label: 'Value',
            value: _value,
            min: 0,
            max: 100,
            onChanged: (double v) => setState(() => _value = v),
          ),
      ],
      code: exampleSource,
    );
  }
}

class _ListPage extends StatelessWidget {
  const _ListPage();
  @override
  Widget build(BuildContext context) {
    final CarbonThemeData t = CarbonTheme.of(context);
    CarbonListItem item(String s) => CarbonListItem(
      child: Text(
        s,
        style: CarbonTypeStyles.body01.copyWith(color: t.textPrimary),
      ),
    );
    return DemoScaffold(
      title: 'List',
      description: 'Ordered and unordered lists, with nesting.',
      previewAlignment: Alignment.topLeft,
      preview: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: CarbonUnorderedList(
              children: <CarbonListItem>[
                item('Apples'),
                item('Oranges'),
                item('Pears'),
              ],
            ),
          ),
          Expanded(
            child: CarbonOrderedList(
              children: <CarbonListItem>[
                item('First'),
                item('Second'),
                item('Third'),
              ],
            ),
          ),
        ],
      ),
      code: exampleSource,
    );
  }
}

class _StackPage extends StatefulWidget {
  const _StackPage();
  @override
  State<_StackPage> createState() => _StackPageState();
}

class _StackPageState extends State<_StackPage> {
  double _gap = 4;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData t = CarbonTheme.of(context);
    Widget box(String s) => DecoratedBox(
      decoration: BoxDecoration(color: t.layerAccent01),
      child: Padding(
        padding: const EdgeInsets.all(CarbonSpacing.spacing03),
        child: Text(
          s,
          style: CarbonTypeStyles.bodyCompact01.copyWith(color: t.textPrimary),
        ),
      ),
    );
    return DemoScaffold(
      title: 'Stack',
      description: 'Lays children out with a token-based gap.',
      previewAlignment: Alignment.topLeft,
      preview: CarbonStack(
        gapStep: _gap.round(),
        children: <Widget>[box('One'), box('Two'), box('Three')],
      ),
      controls: <Widget>[
        sliderKnob(
          label: 'Gap step',
          value: _gap,
          min: 1,
          max: 9,
          onChanged: (double v) => setState(() => _gap = v),
        ),
      ],
      code: exampleSource,
    );
  }
}

class _HeadingPage extends StatelessWidget {
  const _HeadingPage();
  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Heading',
      description:
          'Semantic headings whose level comes from the ambient CarbonSection.',
      previewAlignment: Alignment.topLeft,
      preview: const CarbonSection(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CarbonHeading('Level 1 heading'),
            SizedBox(height: CarbonSpacing.spacing05),
            CarbonSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[CarbonHeading('Nested level 2 heading')],
              ),
            ),
          ],
        ),
      ),
      code: exampleSource,
    );
  }
}

class _CopyButtonPage extends StatefulWidget {
  const _CopyButtonPage();
  @override
  State<_CopyButtonPage> createState() => _CopyButtonPageState();
}

class _CopyButtonPageState extends State<_CopyButtonPage> {
  CarbonCopySize _size = CarbonCopySize.md;
  bool _enabled = true;

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Copy button',
      description:
          'An icon button that copies to the clipboard and shows a brief '
          '"Copied!" confirmation.',
      preview: CarbonCopyButton(
        value: 'npm i @carbon/react',
        size: _size,
        enabled: _enabled,
      ),
      controls: <Widget>[
        choiceKnob<CarbonCopySize>(
          label: 'Size',
          value: _size,
          options: CarbonCopySize.values,
          labelOf: (CarbonCopySize size) => size.name,
          onChanged: (CarbonCopySize size) => setState(() => _size = size),
        ),
        boolKnob(
          label: 'Enabled',
          value: _enabled,
          onChanged: (bool value) => setState(() => _enabled = value),
        ),
      ],
      code: exampleSource,
    );
  }
}

class _CodeSnippetPage extends StatefulWidget {
  const _CodeSnippetPage();
  @override
  State<_CodeSnippetPage> createState() => _CodeSnippetPageState();
}

class _CodeSnippetPageState extends State<_CodeSnippetPage> {
  CarbonCodeSnippetType _type = CarbonCodeSnippetType.single;

  String get _code => switch (_type) {
    CarbonCodeSnippetType.inline => 'carbide',
    CarbonCodeSnippetType.single => 'flutter pub add carbide',
    CarbonCodeSnippetType.multi =>
      "import 'package:carbide/carbide.dart';\n\n"
          'void main() {\n  runApp(const MyApp());\n}',
  };

  @override
  Widget build(BuildContext context) {
    final CarbonCodeSnippet snippet = CarbonCodeSnippet(
      code: _code,
      type: _type,
    );
    return DemoScaffold(
      title: 'Code snippet',
      description: 'Monospaced code with a copy affordance.',
      previewAlignment: Alignment.topLeft,
      preview: _type == CarbonCodeSnippetType.inline
          ? snippet
          : SizedBox(width: 320, child: snippet),
      controls: <Widget>[
        choiceKnob<CarbonCodeSnippetType>(
          label: 'Type',
          value: _type,
          options: CarbonCodeSnippetType.values,
          labelOf: (CarbonCodeSnippetType type) => type.name,
          onChanged: (CarbonCodeSnippetType type) =>
              setState(() => _type = type),
        ),
      ],
      code: exampleSource,
    );
  }
}

class _IconButtonPage extends StatefulWidget {
  const _IconButtonPage();
  @override
  State<_IconButtonPage> createState() => _IconButtonPageState();
}

class _IconButtonPageState extends State<_IconButtonPage> {
  CarbonButtonKind _kind = CarbonButtonKind.primary;

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Icon button',
      description: 'An icon-only button that shows its label in a tooltip.',
      preview: CarbonIconButton(
        icon: CarbonIcons.add,
        label: 'Add item',
        kind: _kind,
        onPressed: () {},
      ),
      controls: <Widget>[
        choiceKnob<CarbonButtonKind>(
          label: 'Kind',
          value: _kind,
          options: const <CarbonButtonKind>[
            CarbonButtonKind.primary,
            CarbonButtonKind.secondary,
            CarbonButtonKind.tertiary,
            CarbonButtonKind.ghost,
          ],
          labelOf: (CarbonButtonKind k) => k.name,
          onChanged: (CarbonButtonKind k) => setState(() => _kind = k),
        ),
      ],
      code: exampleSource,
    );
  }
}

class _IndicatorsPage extends StatelessWidget {
  const _IndicatorsPage();
  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Indicators',
      description: 'Badge, icon, and colour-blind-safe shape status markers.',
      previewAlignment: Alignment.topLeft,
      preview: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              CarbonBadgeIndicator(),
              SizedBox(width: 16),
              CarbonBadgeIndicator(count: 8),
              SizedBox(width: 16),
              CarbonBadgeIndicator(count: 4000),
            ],
          ),
          SizedBox(height: 16),
          CarbonIconIndicator(
            kind: CarbonIconIndicatorKind.failed,
            label: 'Failed',
          ),
          SizedBox(height: 8),
          CarbonIconIndicator(
            kind: CarbonIconIndicatorKind.succeeded,
            label: 'Succeeded',
          ),
          SizedBox(height: 16),
          CarbonShapeIndicator(
            kind: CarbonShapeIndicatorKind.critical,
            label: 'Critical',
          ),
          SizedBox(height: 8),
          CarbonShapeIndicator(
            kind: CarbonShapeIndicatorKind.stable,
            label: 'Stable',
          ),
        ],
      ),
      code: exampleSource,
    );
  }
}

class _AspectRatioPage extends StatefulWidget {
  const _AspectRatioPage();
  @override
  State<_AspectRatioPage> createState() => _AspectRatioPageState();
}

class _AspectRatioPageState extends State<_AspectRatioPage> {
  CarbonAspectRatioValue _ratio = CarbonAspectRatioValue.r16x9;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData t = CarbonTheme.of(context);
    return DemoScaffold(
      title: 'Aspect ratio',
      description: 'Constrains content to a fixed ratio.',
      preview: SizedBox(
        width: 240,
        child: CarbonAspectRatio(
          ratio: _ratio,
          child: ColoredBox(color: t.layerAccent01),
        ),
      ),
      controls: <Widget>[
        choiceKnob<CarbonAspectRatioValue>(
          label: 'Ratio',
          value: _ratio,
          options: CarbonAspectRatioValue.values,
          labelOf: (CarbonAspectRatioValue r) => r.label,
          onChanged: (CarbonAspectRatioValue r) => setState(() => _ratio = r),
        ),
      ],
      code: exampleSource,
    );
  }
}

class _GridPage extends StatefulWidget {
  const _GridPage();

  @override
  State<_GridPage> createState() => _GridPageState();
}

class _GridPageState extends State<_GridPage> {
  CarbonGridMode _mode = CarbonGridMode.wide;
  bool _fullWidth = false;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData t = CarbonTheme.of(context);
    return DemoScaffold(
      title: 'Grid',
      description:
          'Responsive columns with wide, narrow or condensed content gutters.',
      previewAlignment: Alignment.topLeft,
      preview: CarbonGrid(
        mode: _mode,
        fullWidth: _fullWidth,
        rowSpacing: 8,
        children: <Widget>[
          for (int i = 0; i < 4; i++)
            CarbonColumn(
              sm: 2,
              md: 4,
              lg: 4,
              child: SizedBox(
                height: 48,
                child: ColoredBox(color: t.layerAccent01),
              ),
            ),
        ],
      ),
      controls: <Widget>[
        choiceKnob<CarbonGridMode>(
          label: 'Gutter mode',
          value: _mode,
          options: CarbonGridMode.values,
          labelOf: (CarbonGridMode mode) => mode.name,
          onChanged: (CarbonGridMode mode) => setState(() => _mode = mode),
        ),
        boolKnob(
          label: 'Full width',
          value: _fullWidth,
          onChanged: (bool full) => setState(() => _fullWidth = full),
        ),
      ],
      code: exampleSource,
    );
  }
}

class _SkeletonsPage extends StatelessWidget {
  const _SkeletonsPage();
  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Skeletons',
      description: 'Loading placeholders that mimic a component footprint.',
      previewAlignment: Alignment.topLeft,
      preview: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(width: 240, child: CarbonTextInputSkeleton()),
          SizedBox(height: 24),
          CarbonCheckboxSkeleton(),
          SizedBox(height: 24),
          SizedBox(
            width: 280,
            child: CarbonDataTableSkeleton(rowCount: 3, columnCount: 3),
          ),
          SizedBox(height: 24),
          SizedBox(width: 240, child: CarbonAISkeletonText(paragraph: true)),
          SizedBox(height: 24),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CarbonAISkeletonIcon(),
              SizedBox(width: 24),
              CarbonAISkeletonPlaceholder(width: 64, height: 64),
            ],
          ),
        ],
      ),
      code: exampleSource,
    );
  }
}
