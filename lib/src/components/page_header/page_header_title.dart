// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

part of 'carbon_page_header.dart';

class _PageTitle extends StatefulWidget {
  const _PageTitle(this.header, {required this.maxLines});
  final CarbonPageHeader header;
  final int maxLines;

  @override
  State<_PageTitle> createState() => _PageTitleState();
}

class _PageTitleState extends State<_PageTitle> {
  static int _nextIdentifier = 0;
  final String _identifier = 'carbide-page-title-${_nextIdentifier++}';
  final GlobalKey _focusKey = GlobalKey();
  final OverlayFocusRepair _repair = OverlayFocusRepair();
  late FocusNode _focus;
  bool _truncated = false;
  bool _showFocus = false;

  @override
  void initState() {
    super.initState();
    _focus = widget.header.titleFocusNode ?? FocusNode();
    _focus.addListener(_focusChanged);
    PaintingBinding.instance.systemFonts.addListener(_fontsChanged);
  }

  void _fontsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(_PageTitle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.header.titleFocusNode != oldWidget.header.titleFocusNode) {
      _repair.cancel();
      _focus.removeListener(_focusChanged);
      if (oldWidget.header.titleFocusNode == null) _focus.dispose();
      _focus = widget.header.titleFocusNode ?? FocusNode();
      _focus.addListener(_focusChanged);
    }
    _repairFocus();
  }

  void _focusChanged() {
    if (!mounted) return;
    setState(() {});
    if (_focus.hasPrimaryFocus) {
      _repairFocus();
    } else if (FocusManager.instance.primaryFocus !=
            FocusManager.instance.rootScope &&
        FocusManager.instance.primaryFocus != _focus.enclosingScope) {
      _repair.cancel();
    }
  }

  void _repairFocus() {
    if (!kIsWeb || !_truncated || !_focus.hasPrimaryFocus) return;
    _repair.schedule(
      _focus,
      captureReadOnlyControlFocus(_identifier),
      isCurrent: () => mounted && _truncated,
      parkingScope: _focus.enclosingScope,
    );
  }

  @override
  void dispose() {
    PaintingBinding.instance.systemFonts.removeListener(_fontsChanged);
    _repair.dispose();
    _focus.removeListener(_focusChanged);
    if (widget.header.titleFocusNode == null) _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final TextStyle style = CarbonTypeStyles.productiveHeading04.copyWith(
      color: theme.textPrimary,
    );
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final TextPainter painter = TextPainter(
          text: TextSpan(
            text: widget.header.title,
            style: DefaultTextStyle.of(context).style.merge(style),
          ),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          locale: Localizations.maybeLocaleOf(context),
          maxLines: widget.maxLines,
          ellipsis: '…',
        )..layout(maxWidth: constraints.maxWidth);
        _truncated = painter.didExceedMaxLines;
        painter.dispose();
        if (!_truncated) _repair.cancel();
        final Widget title = FocusableActionDetector(
          key: _focusKey,
          focusNode: _focus,
          enabled: _truncated,
          includeFocusSemantics: false,
          onShowFocusHighlight: (bool visible) {
            if (_showFocus != visible) setState(() => _showFocus = visible);
          },
          child: CustomPaint(
            foregroundPainter: _showFocus && _truncated
                ? _TitleFocusPainter(theme.focus)
                : null,
            child: Semantics(
              // Flutter 3.47's stopManaging removes native focus listeners
              // but leaves tabindex=0 behind. Replace this heading when its
              // focusability changes, as well as when its h1–h6 tag changes.
              key: ValueKey<(int, bool)>((
                widget.header.headingLevel,
                _truncated,
              )),
              identifier: _identifier,
              header: true,
              headingLevel: widget.header.headingLevel,
              label: widget.header.title,
              excludeSemantics: true,
              focusable: _truncated,
              focused: _truncated ? _focus.hasFocus : null,
              onFocus: _truncated ? _focus.requestFocus : null,
              child: Text(
                widget.header.title,
                maxLines: widget.maxLines,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
            ),
          ),
        );
        return _truncated
            ? CarbonTooltip(
                label: widget.header.title,
                align: CarbonPopoverAlignment.bottom,
                autoAlign: true,
                excludeFromSemantics: true,
                scrollable: true,
                onOpenChanged: (_) => _repairFocus(),
                child: title,
              )
            : title;
      },
    );
  }
}

/// TruncatedText's 2px focus-visible outline with a 2px outward offset.
class _TitleFocusPainter extends CustomPainter {
  const _TitleFocusPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      (Offset.zero & size).inflate(3),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_TitleFocusPainter oldDelegate) =>
      color != oldDelegate.color;
}
