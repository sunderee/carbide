// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

part of 'carbon_page_header.dart';

/// Measures the original tag children once per layout; hidden children stay
/// mounted offstage and move into the reference's popover when disclosed.
class _ResponsiveTags extends StatefulWidget {
  const _ResponsiveTags({
    required this.tags,
    required this.overflowLabel,
    required this.disclosureLabel,
  });

  final List<Widget> tags;
  final String Function(int)? overflowLabel;
  final String disclosureLabel;

  @override
  State<_ResponsiveTags> createState() => _ResponsiveTagsState();
}

class _ResponsiveTagsState extends State<_ResponsiveTags> {
  final FocusNode _trigger = FocusNode();
  final OverlayPortalController _portal = OverlayPortalController();
  final Object _group = Object();
  final Map<Object, GlobalKey> _keys = <Object, GlobalKey>{};
  final Map<Object, double> _widths = <Object, double>{};
  bool _open = false;
  double? _lastWidth;
  TextScaler? _lastScaler;

  Object _identity(int i) => widget.tags[i].key ?? i;

  @override
  void didUpdateWidget(_ResponsiveTags oldWidget) {
    super.didUpdateWidget(oldWidget);
    final Set<Object> identities = <Object>{
      for (int i = 0; i < widget.tags.length; i++) _identity(i),
    };
    _keys.removeWhere((Object key, _) => !identities.contains(key));
    _widths.removeWhere((Object key, _) => !identities.contains(key));
  }

  @override
  void dispose() {
    _trigger.dispose();
    super.dispose();
  }

  void _close() {
    if (!mounted) return;
    if (_portal.isShowing) _portal.hide();
    setState(() => _open = false);
    if (_trigger.context != null) _trigger.requestFocus();
  }

  void _toggle() {
    _trigger.requestFocus();
    _open ? _portal.hide() : _portal.show();
    setState(() => _open = !_open);
  }

  double _counterWidth(int hidden) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: '+$hidden', style: CarbonTag.labelStyle),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      locale: Localizations.maybeLocaleOf(context),
      maxLines: 1,
    )..layout();
    // OperationalTag's 8px side padding plus its 1px border.
    final double width = (painter.width + 18).clamp(
      CarbonTag.minWidth,
      CarbonTag.maxWidth,
    );
    painter.dispose();
    return width;
  }

  Widget _tag(int i) {
    final Object identity = _identity(i);
    return _MeasuredTag(
      key: _keys.putIfAbsent(identity, GlobalKey.new),
      onWidth: (double width) {
        if (mounted && (_widths[identity] ?? -1) != width) {
          setState(() => _widths[identity] = width);
        }
      },
      child: widget.tags[i],
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(
      <Object>{for (int i = 0; i < widget.tags.length; i++) _identity(i)}
              .length ==
          widget.tags.length,
      'Collapsed tag keys must be unique.',
    );
    if (widget.tags.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final TextScaler scaler = MediaQuery.textScalerOf(context);
        final bool changed =
            _lastWidth != null &&
            (_lastWidth != constraints.maxWidth || _lastScaler != scaler);
        _lastWidth = constraints.maxWidth;
        _lastScaler = scaler;
        if (changed && _open) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _close());
        }
        const double gap = CarbonSpacing.spacing03;
        final List<double> widths = <double>[
          for (int i = 0; i < widget.tags.length; i++)
            _widths[_identity(i)] ?? CarbonTag.maxWidth,
        ];
        final double total =
            widths.fold<double>(0, (double sum, double width) => sum + width) +
            gap * (widths.length - 1);
        int visible = widths.length;
        if (total > constraints.maxWidth) {
          visible = 0;
          double used = 0;
          for (int i = 0; i < widths.length; i++) {
            final double candidate =
                used +
                widths[i] +
                gap * (i + 1) +
                _counterWidth(widths.length - i - 1);
            if (candidate > constraints.maxWidth) break;
            visible = i + 1;
            used += widths[i];
          }
        }
        final int hidden = widths.length - visible;
        final bool show = _open && hidden > 0;
        if (_open && hidden == 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _open = false);
          });
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (int i = 0; i < visible; i++) ...<Widget>[
                  if (i > 0) const SizedBox(width: gap),
                  SizedBox(width: widths[i], child: _tag(i)),
                ],
                if (hidden > 0) ...<Widget>[
                  if (visible > 0) const SizedBox(width: gap),
                  CarbonPopover(
                    open: show,
                    portalController: _portal,
                    autoAlign: true,
                    align: CarbonPopoverAlignment.bottomEnd,
                    tapRegionGroupId: _group,
                    onRequestClose: _close,
                    content: Semantics(
                      container: true,
                      explicitChildNodes: true,
                      label: widget.disclosureLabel,
                      child: Padding(
                        padding: const EdgeInsets.all(CarbonSpacing.spacing05),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              for (
                                int i = visible;
                                i < widths.length;
                                i++
                              ) ...<Widget>[
                                if (i > visible) const SizedBox(height: gap),
                                _tag(i),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    child: TapRegion(
                      groupId: _group,
                      child: CarbonControlSemantics(
                        state: CarbonControlState.interactive,
                        label:
                            widget.overflowLabel?.call(hidden) ??
                            '$hidden more tags',
                        readOnlyHint: CarbonControlState.defaultReadOnlyHint,
                        button: true,
                        expanded: show,
                        focusNode: _trigger,
                        onActivate: _toggle,
                        builder: (FocusNode node) => ExcludeSemantics(
                          child: CarbonOperationalTag(
                            label: '+$hidden',
                            focusNode: node,
                            onPressed: _toggle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (!show && hidden > 0)
              ExcludeFocus(
                child: Offstage(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      for (int i = visible; i < widths.length; i++) _tag(i),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MeasuredTag extends SingleChildRenderObjectWidget {
  const _MeasuredTag({required this.onWidth, required super.child, super.key});

  final ValueChanged<double> onWidth;

  @override
  _RenderMeasuredTag createRenderObject(BuildContext context) =>
      _RenderMeasuredTag(onWidth);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderMeasuredTag renderObject,
  ) {
    renderObject.onWidth = onWidth;
  }
}

class _RenderMeasuredTag extends RenderProxyBox {
  _RenderMeasuredTag(this.onWidth);

  ValueChanged<double> onWidth;
  double? _reported;

  @override
  void performLayout() {
    super.performLayout();
    final double width = child!
        .getDryLayout(const BoxConstraints(maxWidth: CarbonTag.maxWidth))
        .width;
    if (_reported == width) return;
    _reported = width;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (attached) onWidth(width);
    });
  }
}
