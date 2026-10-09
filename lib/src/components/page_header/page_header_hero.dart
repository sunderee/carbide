// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Reference: Carbon PageHeaderHeroImage.tsx and ContentWithHeroImage story.
// Apache-2.0; see NOTICE. Narrow content stacks rather than being hidden.

part of 'carbon_page_header.dart';

class _HeroContent extends StatelessWidget {
  const _HeroContent(this.header);
  final CarbonPageHeader header;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) {
      final bool sideBySide = constraints.maxWidth >= CarbonBreakpoint.md.width;
      final double ratio =
          header.heroAspectRatio ??
          (constraints.maxWidth >= CarbonBreakpoint.lg.width ? 2 : 1.5);
      Widget hero = header.hero!;
      if (header.heroDecorative) {
        hero = ExcludeFocus(child: ExcludeSemantics(child: hero));
      } else if (header.heroLabel != null) {
        hero = ExcludeFocus(
          child: Semantics(
            image: true,
            label: header.heroLabel,
            excludeSemantics: true,
            child: hero,
          ),
        );
      }
      final Widget slot = Padding(
        padding: EdgeInsets.fromLTRB(
          CarbonPageHeader.gutter,
          sideBySide ? CarbonSpacing.spacing06 : 0,
          CarbonPageHeader.gutter,
          CarbonSpacing.spacing06,
        ),
        child: AspectRatio(
          aspectRatio: ratio,
          child: ClipRect(child: hero),
        ),
      );
      // Keep the ancestry fixed: switching Row/Column and reparenting keys
      // preserves Dart state but removes the focused native editor on web.
      final double width = sideBySide
          ? constraints.maxWidth / 2
          : constraints.maxWidth;
      return Semantics(
        container: true,
        explicitChildNodes: true,
        child: Flex(
          direction: sideBySide ? Axis.horizontal : Axis.vertical,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: width,
              child: Semantics(
                container: true,
                explicitChildNodes: true,
                sortKey: const OrdinalSortKey(0),
                child: _Content(header),
              ),
            ),
            SizedBox(
              width: width,
              child: Semantics(
                container: true,
                explicitChildNodes: true,
                sortKey: const OrdinalSortKey(1),
                child: slot,
              ),
            ),
          ],
        ),
      );
    },
  );
}
