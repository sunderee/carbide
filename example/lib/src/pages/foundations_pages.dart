// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the GNU
// Affero General Public License v3.0 or later.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';

import '../demo_scaffold.dart' show kDemoPreviewKey;
import '../knobs.dart';
import '../registry.dart';

/// The Foundations category: tokens that everything else builds on.
final GalleryCategory foundationsCategory = GalleryCategory(
  title: 'Foundations',
  icon: CarbonIcons.categories,
  entries: <GalleryEntry>[
    GalleryEntry(
      slug: 'colors',
      title: 'Color tokens',
      builder: () => const _ColorsPage(),
    ),
    GalleryEntry(
      slug: 'typography',
      title: 'Typography',
      builder: () => const _TypographyPage(),
    ),
    GalleryEntry(
      slug: 'fluid-type',
      title: 'Fluid typography',
      builder: () => const _FluidTypePage(),
    ),
    GalleryEntry(
      slug: 'spacing',
      title: 'Spacing',
      builder: () => const _SpacingPage(),
    ),
    GalleryEntry(
      slug: 'icons',
      title: 'Icons',
      builder: () => const _IconsPage(),
    ),
    GalleryEntry(
      slug: 'pictograms',
      title: 'Pictograms',
      builder: () => const _PictogramsPage(),
    ),
    GalleryEntry(
      slug: 'motion',
      title: 'Motion',
      builder: () => const _MotionPage(),
    ),
  ],
);

class _ColorsPage extends StatelessWidget {
  const _ColorsPage();

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData t = CarbonTheme.of(context);
    final List<(String, Color)> tokens = <(String, Color)>[
      ('background', t.background),
      ('layer-01', t.layer01),
      ('field-01', t.field01),
      ('text-primary', t.textPrimary),
      ('text-secondary', t.textSecondary),
      ('text-placeholder', t.textPlaceholder),
      ('link-primary', t.linkPrimary),
      ('interactive', t.interactive),
      ('focus', t.focus),
      ('icon-primary', t.iconPrimary),
      ('border-subtle-01', t.borderSubtle01),
      ('border-strong-01', t.borderStrong01),
      ('support-error', t.supportError),
      ('support-success', t.supportSuccess),
      ('support-warning', t.supportWarning),
      ('support-info', t.supportInfo),
    ];
    return _ScrollPage(
      title: 'Color tokens',
      description:
          'Semantic tokens resolve per theme. Switch themes in the header to '
          'watch every swatch update.',
      child: Wrap(
        spacing: CarbonSpacing.spacing05,
        runSpacing: CarbonSpacing.spacing05,
        children: <Widget>[
          for (final (String, Color) token in tokens)
            _Swatch(name: token.$1, color: token.$2),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData t = CarbonTheme.of(context);
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: t.borderSubtle01),
            ),
            child: const SizedBox(height: 64, width: 160),
          ),
          const SizedBox(height: CarbonSpacing.spacing03),
          Text(
            name,
            style: CarbonTypeStyles.code01.copyWith(color: t.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _TypographyPage extends StatelessWidget {
  const _TypographyPage();

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData t = CarbonTheme.of(context);
    final List<(String, TextStyle)> styles = <(String, TextStyle)>[
      ('productive-heading-06', CarbonTypeStyles.productiveHeading06),
      ('productive-heading-04', CarbonTypeStyles.productiveHeading04),
      ('productive-heading-03', CarbonTypeStyles.productiveHeading03),
      ('heading-compact-02', CarbonTypeStyles.headingCompact02),
      ('body-02', CarbonTypeStyles.body02),
      ('body-01', CarbonTypeStyles.body01),
      ('body-compact-01', CarbonTypeStyles.bodyCompact01),
      ('label-01', CarbonTypeStyles.label01),
      ('helper-text-01', CarbonTypeStyles.helperText01),
      ('code-02', CarbonTypeStyles.code02),
    ];
    return _ScrollPage(
      title: 'Typography',
      description: 'The IBM Plex type scale, bundled with Carbide.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final (String, TextStyle) s in styles)
            Padding(
              padding: const EdgeInsets.only(bottom: CarbonSpacing.spacing06),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'The quick brown fox',
                    style: s.$2.copyWith(color: t.textPrimary),
                  ),
                  const SizedBox(height: CarbonSpacing.spacing02),
                  Text(
                    s.$1,
                    style: CarbonTypeStyles.code01.copyWith(
                      color: t.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SpacingPage extends StatelessWidget {
  const _SpacingPage();

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData t = CarbonTheme.of(context);
    return _ScrollPage(
      title: 'Spacing',
      description: 'The Carbon spacing scale (steps 1–13).',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (int i = 0; i < CarbonSpacing.steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: CarbonSpacing.spacing04),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 96,
                    child: Text(
                      'spacing-${(i + 1).toString().padLeft(2, '0')}',
                      style: CarbonTypeStyles.code01.copyWith(
                        color: t.textSecondary,
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(color: t.interactive),
                    child: SizedBox(height: 16, width: CarbonSpacing.steps[i]),
                  ),
                  const SizedBox(width: CarbonSpacing.spacing03),
                  Text(
                    '${CarbonSpacing.steps[i].toStringAsFixed(0)} px',
                    style: CarbonTypeStyles.code01.copyWith(
                      color: t.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _IconsPage extends StatelessWidget {
  const _IconsPage();

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData t = CarbonTheme.of(context);
    final List<(String, CarbonIconData)> icons = <(String, CarbonIconData)>[
      ('add', CarbonIcons.add),
      ('close', CarbonIcons.close),
      ('search', CarbonIcons.search),
      ('settings', CarbonIcons.settings),
      ('checkmark', CarbonIcons.checkmark),
      ('chevronDown', CarbonIcons.chevronDown),
      ('chevronRight', CarbonIcons.chevronRight),
      ('warning', CarbonIcons.warning),
      ('warningFilled', CarbonIcons.warningFilled),
      ('errorFilled', CarbonIcons.errorFilled),
      ('checkmarkFilled', CarbonIcons.checkmarkFilled),
      ('information', CarbonIcons.information),
      ('edit', CarbonIcons.edit),
      ('trashCan', CarbonIcons.trashCan),
      ('download', CarbonIcons.download),
      ('document', CarbonIcons.document),
      ('folder', CarbonIcons.folder),
      ('user', CarbonIcons.user),
      ('calendar', CarbonIcons.calendar),
      ('filter', CarbonIcons.filter),
      ('menu', CarbonIcons.menu),
      ('overflowMenuVertical', CarbonIcons.overflowMenuVertical),
      ('colorPalette', CarbonIcons.colorPalette),
      ('launch', CarbonIcons.launch),
    ];
    return _ScrollPage(
      title: 'Icons',
      description:
          'A sample from the 2,000+ Carbon icons bundled as tree-shakeable '
          'vector paths.',
      child: Wrap(
        spacing: CarbonSpacing.spacing05,
        runSpacing: CarbonSpacing.spacing05,
        children: <Widget>[
          for (final (String, CarbonIconData) icon in icons)
            SizedBox(
              width: 120,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  CarbonIcon(icon.$2, size: 24, color: t.iconPrimary),
                  const SizedBox(height: CarbonSpacing.spacing03),
                  Text(
                    icon.$1,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CarbonTypeStyles.code01.copyWith(
                      color: t.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MotionPage extends StatefulWidget {
  const _MotionPage();

  @override
  State<_MotionPage> createState() => _MotionPageState();
}

class _MotionPageState extends State<_MotionPage> {
  bool _shifted = false;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData t = CarbonTheme.of(context);
    return _ScrollPage(
      title: 'Motion',
      description: 'Carbon’s productive easing and durations. Tap to animate.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CarbonButton(
            label: _shifted ? 'Reset' : 'Animate',
            onPressed: () => setState(() => _shifted = !_shifted),
          ),
          const SizedBox(height: CarbonSpacing.spacing07),
          Align(
            alignment: _shifted ? Alignment.centerRight : Alignment.centerLeft,
            child: AnimatedContainer(
              duration: CarbonDuration.moderate01,
              curve: CarbonEasing.standardProductive,
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: t.interactive),
            ),
          ),
        ],
      ),
    );
  }
}

/// A simple scrolling page wrapper with a title and description.
class _FluidTypePage extends StatefulWidget {
  const _FluidTypePage();

  @override
  State<_FluidTypePage> createState() => _FluidTypePageState();
}

class _FluidTypePageState extends State<_FluidTypePage> {
  double _width = 1056;

  static const List<(String, CarbonFluidTextStyle)> _styles =
      <(String, CarbonFluidTextStyle)>[
        ('expressiveHeading01', CarbonFluidTypeStyles.expressiveHeading01),
        ('expressiveHeading02', CarbonFluidTypeStyles.expressiveHeading02),
        ('expressiveHeading03', CarbonFluidTypeStyles.expressiveHeading03),
        ('expressiveHeading04', CarbonFluidTypeStyles.expressiveHeading04),
        ('expressiveHeading05', CarbonFluidTypeStyles.expressiveHeading05),
        ('expressiveHeading06', CarbonFluidTypeStyles.expressiveHeading06),
        ('expressiveParagraph01', CarbonFluidTypeStyles.expressiveParagraph01),
        ('quotation01', CarbonFluidTypeStyles.quotation01),
        ('quotation02', CarbonFluidTypeStyles.quotation02),
        ('display01', CarbonFluidTypeStyles.display01),
        ('display02', CarbonFluidTypeStyles.display02),
        ('display03', CarbonFluidTypeStyles.display03),
        ('display04', CarbonFluidTypeStyles.display04),
      ];

  static const List<(String, CarbonFluidTextStyle)> _samples =
      <(String, CarbonFluidTextStyle)>[
        ('expressiveHeading04', CarbonFluidTypeStyles.expressiveHeading04),
        ('expressiveHeading06', CarbonFluidTypeStyles.expressiveHeading06),
        ('quotation02', CarbonFluidTypeStyles.quotation02),
        ('display02', CarbonFluidTypeStyles.display02),
      ];

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData t = CarbonTheme.of(context);
    final CarbonBreakpoint active = CarbonBreakpoint.of(_width);
    return _ScrollPage(
      title: 'Fluid typography',
      description:
          'Fluid styles interpolate across the Carbon breakpoints. Drag the '
          'width to watch each style resolve for that viewport.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          sliderKnob(
            label: 'Viewport width',
            value: _width,
            min: 320,
            max: 1584,
            step: 16,
            onChanged: (double v) => setState(() => _width = v),
          ),
          const SizedBox(height: CarbonSpacing.spacing03),
          Text(
            '${_width.round()}px · breakpoint ${active.name}',
            style: CarbonTypeStyles.code01.copyWith(color: t.textSecondary),
          ),
          const SizedBox(height: CarbonSpacing.spacing06),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              width: _width,
              padding: const EdgeInsets.all(CarbonSpacing.spacing05),
              decoration: BoxDecoration(
                border: Border.all(color: t.borderSubtle01),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (final (String, CarbonFluidTextStyle) sample
                      in _samples) ...<Widget>[
                    Text(
                      '${sample.$1} · '
                      '${sample.$2.resolve(_width).fontSize!.round()}px',
                      style: CarbonTypeStyles.code01.copyWith(
                        color: t.textSecondary,
                      ),
                    ),
                    const SizedBox(height: CarbonSpacing.spacing02),
                    Text(
                      'Carbide is carbon, fluid.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: sample.$2
                          .resolve(_width)
                          .copyWith(color: t.textPrimary),
                    ),
                    const SizedBox(height: CarbonSpacing.spacing06),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: CarbonSpacing.spacing07),
          Text(
            'All fluid styles at ${_width.round()}px',
            style: CarbonTypeStyles.heading02.copyWith(color: t.textPrimary),
          ),
          const SizedBox(height: CarbonSpacing.spacing04),
          for (final (String, CarbonFluidTextStyle) style
              in _styles) ...<Widget>[
            Row(
              children: <Widget>[
                SizedBox(
                  width: 220,
                  child: Text(
                    style.$1,
                    style: CarbonTypeStyles.code01.copyWith(
                      color: t.textSecondary,
                    ),
                  ),
                ),
                Text(
                  '${style.$2.resolve(_width).fontSize!.round()}px',
                  style: CarbonTypeStyles.code01.copyWith(color: t.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: CarbonSpacing.spacing03),
          ],
        ],
      ),
    );
  }
}

class _PictogramsPage extends StatelessWidget {
  const _PictogramsPage();

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData t = CarbonTheme.of(context);
    final List<(String, CarbonIconData)> pictograms =
        <(String, CarbonIconData)>[
          ('accessibility', CarbonPictograms.accessibility),
          ('agriculture', CarbonPictograms.agriculture),
          ('cloud', CarbonPictograms.cloud),
          ('confidentialComputing', CarbonPictograms.confidentialComputing),
          ('connectedDevices', CarbonPictograms.connectedDevices),
          ('globe', CarbonPictograms.globe),
          ('hospital', CarbonPictograms.hospital),
          ('hurricane', CarbonPictograms.hurricane),
          ('hybridCloud', CarbonPictograms.hybridCloud),
          ('processAutomation', CarbonPictograms.processAutomation),
          ('productivity', CarbonPictograms.productivity),
          ('solarPanel', CarbonPictograms.solarPanel),
          ('virtualServer', CarbonPictograms.virtualServer),
          ('virus', CarbonPictograms.virus),
          ('vision', CarbonPictograms.vision),
          ('windPower', CarbonPictograms.windPower),
        ];
    return _ScrollPage(
      title: 'Pictograms',
      description:
          'A sample from the 1,572 Carbon pictograms. Pictograms render at '
          '48px or larger (the CarbonPictogram minimum, per Carbon guidance) '
          'in the ambient icon colour.',
      child: Wrap(
        spacing: CarbonSpacing.spacing06,
        runSpacing: CarbonSpacing.spacing06,
        children: <Widget>[
          for (final (String, CarbonIconData) pictogram in pictograms)
            SizedBox(
              width: 148,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  CarbonPictogram(pictogram.$2, size: 64),
                  const SizedBox(height: CarbonSpacing.spacing03),
                  Text(
                    pictogram.$1,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CarbonTypeStyles.code01.copyWith(
                      color: t.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ScrollPage extends StatelessWidget {
  const _ScrollPage({
    required this.title,
    required this.description,
    required this.child,
  });

  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData t = CarbonTheme.of(context);
    // The boundary carries the demo preview key so the contact-sheet test
    // captures foundations pages too (viewport-sized, like a screenshot).
    return RepaintBoundary(
      key: kDemoPreviewKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: CarbonSpacing.spacing09),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: CarbonTypeStyles.productiveHeading05.copyWith(
                color: t.textPrimary,
              ),
            ),
            const SizedBox(height: CarbonSpacing.spacing03),
            Text(
              description,
              style: CarbonTypeStyles.body01.copyWith(color: t.textSecondary),
            ),
            const SizedBox(height: CarbonSpacing.spacing07),
            child,
          ],
        ),
      ),
    );
  }
}
