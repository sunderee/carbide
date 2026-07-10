// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/search/_search.scss
//   styles/scss/components/fluid-search/_fluid-search.scss
//   react/src/components/{Search,ExpandableSearch}

import 'package:flutter/services.dart' show KeyDownEvent, LogicalKeyboardKey;
import 'package:flutter/widgets.dart';

import '../../foundations/motion.dart';
import '../../foundations/typography.dart';
import '../../icons/carbon_icon.dart';
import '../../icons/carbon_icons.dart';
import '../../theme/carbon_layer.dart';
import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';
import '../../utils/focus_ring.dart';
import '../../utils/interaction.dart';
import '../form/carbon_form.dart';

/// A Carbon search field.
///
/// A leading magnifier, an `EditableText`, and a trailing clear button shown
/// only when there is content. The leading/trailing controls are
/// height-square; the field reads `field` with a `border-strong` bottom
/// border, per `_search.scss`. See [CarbonExpandableSearch] for the
/// collapse-to-an-icon variant.
class CarbonSearch extends StatefulWidget {
  /// Creates a search field.
  const CarbonSearch({
    super.key,
    this.labelText = 'Search',
    this.controller,
    this.initialValue,
    this.onChanged,
    this.onClear,
    this.placeholder = 'Search',
    this.size = CarbonFieldSize.md,
    this.disabled = false,
    this.closeButtonLabel = 'Clear search input',
    this.fluid = false,
    this.focusNode,
    this.autofocus = false,
  }) : assert(
         controller == null || initialValue == null,
         'provide controller or initialValue, not both',
       );

  /// The accessible label (visually hidden).
  final String labelText;

  /// An external controller.
  final TextEditingController? controller;

  /// The initial query.
  final String? initialValue;

  /// Called when the query changes.
  final ValueChanged<String>? onChanged;

  /// Called when the clear button is pressed.
  final VoidCallback? onClear;

  /// Placeholder shown when empty.
  final String placeholder;

  /// The field size.
  final CarbonFieldSize size;

  /// Whether disabled.
  final bool disabled;

  /// The clear button's accessible label.
  final String closeButtonLabel;

  /// Uses the fluid treatment.
  final bool fluid;

  /// An optional focus node.
  final FocusNode? focusNode;

  /// Whether to request focus when first built.
  final bool autofocus;

  @override
  State<CarbonSearch> createState() => _CarbonSearchState();
}

class _CarbonSearchState extends State<CarbonSearch> {
  /// The effective fluid flag: the widget's own, or an enclosing
  /// [CarbonFluidForm] scope.
  bool get _fluid => widget.fluid || CarbonFluidForm.of(context);

  TextEditingController? _internalController;
  FocusNode? _internalFocus;

  TextEditingController get _controller =>
      widget.controller ?? (_internalController ??= TextEditingController());
  FocusNode get _focus => widget.focusNode ?? (_internalFocus ??= FocusNode());

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _internalController = TextEditingController(text: widget.initialValue);
    }
    _controller.addListener(_rebuild);
    _focus.addListener(_rebuild);
  }

  @override
  void dispose() {
    _controller.removeListener(_rebuild);
    _focus.removeListener(_rebuild);
    _internalController?.dispose();
    _internalFocus?.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) {
      setState(() {});
    }
  }

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
    widget.onClear?.call();
    _focus.requestFocus();
  }

  /// Escape clears a non-empty query (`search/accessibility.mdx`: users
  /// "press Esc to clear it"). An empty query ignores the key so it can
  /// bubble — [CarbonExpandableSearch] collapses on it, like upstream.
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape &&
        _controller.text.isNotEmpty) {
      _clear();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    // The ancestor Focus sees keys before the EditableText's own
    // Shortcuts/Actions, so Escape is intercepted here (the combo box
    // uses the same mechanism).
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: _onKey,
      child: _CarbonSearchField(
        controller: _controller,
        focusNode: _focus,
        placeholder: widget.placeholder,
        labelText: widget.labelText,
        size: widget.size,
        disabled: widget.disabled,
        fluid: _fluid,
        autofocus: widget.autofocus,
        onChanged: widget.onChanged,
        onClear: _clear,
        closeButtonLabel: widget.closeButtonLabel,
      ),
    );
  }
}

/// The shared search field surface (magnifier + editable + clear).
class _CarbonSearchField extends StatelessWidget {
  const _CarbonSearchField({
    required this.controller,
    required this.focusNode,
    required this.placeholder,
    required this.labelText,
    required this.size,
    required this.disabled,
    required this.fluid,
    required this.autofocus,
    required this.onChanged,
    required this.onClear,
    required this.closeButtonLabel,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String placeholder;
  final String labelText;
  final CarbonFieldSize size;
  final bool disabled;
  final bool fluid;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final VoidCallback onClear;
  final String closeButtonLabel;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    final double h = size.height;
    final bool hasContent = controller.text.isNotEmpty;

    final Widget magnifier = SizedBox(
      width: h,
      height: h,
      child: Center(
        child: CarbonIcon(
          CarbonIcons.search,
          size: 16,
          color: disabled ? theme.iconDisabled : theme.iconSecondary,
        ),
      ),
    );

    final Widget editable = MergeSemantics(
      child: Semantics(
        label: labelText,
        textField: true,
        child: Stack(
          alignment: AlignmentDirectional.centerStart,
          children: <Widget>[
            if (!hasContent)
              ExcludeSemantics(
                child: IgnorePointer(
                  child: Text(
                    placeholder,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CarbonTypeStyles.bodyCompact01.copyWith(
                      color: theme.textPlaceholder,
                    ),
                  ),
                ),
              ),
            EditableText(
              controller: controller,
              focusNode: focusNode,
              readOnly: disabled,
              autofocus: autofocus,
              onChanged: onChanged,
              style: CarbonTypeStyles.bodyCompact01.copyWith(
                color: disabled ? theme.textDisabled : theme.textPrimary,
              ),
              cursorColor: theme.focus,
              backgroundCursorColor: theme.textPlaceholder,
              selectionColor: theme.focus.withValues(alpha: 0.2),
              cursorWidth: 1,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );

    final Widget clear = AnimatedOpacity(
      duration: CarbonDuration.fast01,
      opacity: hasContent ? 1 : 0,
      child: IgnorePointer(
        ignoring: !hasContent,
        child: Semantics(
          button: true,
          label: closeButtonLabel,
          child: CarbonInteraction(
            enabled: hasContent && !disabled,
            onPressed: onClear,
            builder: (BuildContext context, Set<WidgetState> states) {
              final bool hovered = states.contains(WidgetState.hovered);
              return ColoredBox(
                color: hovered ? layer.fieldHover : const Color(0x00000000),
                child: SizedBox(
                  width: h,
                  height: h,
                  child: Center(
                    child: CarbonIcon(
                      CarbonIcons.close,
                      size: 16,
                      color: disabled ? theme.iconDisabled : theme.iconPrimary,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    final Widget searchRow = Row(
      children: <Widget>[
        magnifier,
        Expanded(child: editable),
        clear,
      ],
    );

    Widget box = DecoratedBox(
      decoration: BoxDecoration(
        color: layer.field,
        border: Border(
          bottom: BorderSide(
            color: disabled ? const Color(0x00000000) : theme.borderStrong01,
          ),
        ),
      ),
      child: fluid
          // The fluid treatment puts the label inside a 64px box above the
          // search row (the magnifier stays leading — Carbon moves it trailing
          // in fluid; a deliberate simplification for a coherent widget).
          ? SizedBox(
              height: 64,
              child: Stack(
                children: <Widget>[
                  PositionedDirectional(
                    top: 13,
                    start: CarbonField.paddingInline,
                    child: ExcludeSemantics(
                      child: Text(
                        labelText,
                        style: CarbonTypeStyles.label01.copyWith(
                          color: disabled
                              ? theme.textDisabled
                              : theme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    bottom: 0,
                    start: 0,
                    end: 0,
                    child: SizedBox(height: h, child: searchRow),
                  ),
                ],
              ),
            )
          : SizedBox(height: h, child: searchRow),
    );
    if (focusNode.hasFocus) {
      box = CarbonFocusRing(visible: true, child: box);
    }
    return Semantics(container: true, child: box);
  }
}

/// A search that collapses to a single magnifier button and expands to the
/// full field on tap/focus, collapsing again on blur when empty.
class CarbonExpandableSearch extends StatefulWidget {
  /// Creates an expandable search.
  const CarbonExpandableSearch({
    super.key,
    this.labelText = 'Search',
    this.controller,
    this.onChanged,
    this.onClear,
    this.placeholder = 'Search',
    this.size = CarbonFieldSize.md,
    this.disabled = false,
    this.expandLabel = 'Expand search',
    this.closeButtonLabel = 'Clear search input',
  });

  /// The accessible label.
  final String labelText;

  /// An external controller.
  final TextEditingController? controller;

  /// Called when the query changes.
  final ValueChanged<String>? onChanged;

  /// Called when cleared.
  final VoidCallback? onClear;

  /// Placeholder shown when expanded.
  final String placeholder;

  /// The field size.
  final CarbonFieldSize size;

  /// Whether disabled.
  final bool disabled;

  /// The collapsed magnifier button's accessible label.
  final String expandLabel;

  /// The clear button's accessible label.
  final String closeButtonLabel;

  @override
  State<CarbonExpandableSearch> createState() => _CarbonExpandableSearchState();
}

class _CarbonExpandableSearchState extends State<CarbonExpandableSearch> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();
  final FocusNode _focus = FocusNode();
  final FocusNode _buttonFocus = FocusNode(
    debugLabel: 'CarbonExpandableSearch.button',
  );
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focus.dispose();
    _buttonFocus.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    // Collapse when focus leaves and the field is empty.
    if (!_focus.hasFocus && _controller.text.isEmpty) {
      setState(() => _expanded = false);
    }
  }

  void _expand() {
    setState(() => _expanded = true);
    _focus.requestFocus();
  }

  /// Escape on an expanded empty search collapses it and hands focus back
  /// to the magnifier button (react `ExpandableSearch.tsx` handleKeyDown;
  /// `Search.tsx` focuses the expand button). A non-empty query never
  /// reaches this handler — the inner [CarbonSearch] clears it instead.
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape &&
        _controller.text.isEmpty) {
      setState(() => _expanded = false);
      // The button mounts on the next frame, replacing the field.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _buttonFocus.requestFocus();
      });
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    final double h = widget.size.height;

    if (!_expanded) {
      return Semantics(
        button: true,
        label: widget.expandLabel,
        child: CarbonInteraction(
          enabled: !widget.disabled,
          focusNode: _buttonFocus,
          onPressed: _expand,
          builder: (BuildContext context, Set<WidgetState> states) {
            final bool hovered = states.contains(WidgetState.hovered);
            return CarbonFocusRing(
              visible: states.contains(WidgetState.focused),
              child: ColoredBox(
                color: hovered ? layer.fieldHover : const Color(0x00000000),
                child: SizedBox(
                  width: h,
                  height: h,
                  child: Center(
                    child: CarbonIcon(
                      CarbonIcons.search,
                      size: 16,
                      color: widget.disabled
                          ? theme.iconDisabled
                          : theme.iconSecondary,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: _onKey,
      child: CarbonSearch(
        labelText: widget.labelText,
        controller: _controller,
        focusNode: _focus,
        placeholder: widget.placeholder,
        size: widget.size,
        disabled: widget.disabled,
        autofocus: true,
        onChanged: widget.onChanged,
        onClear: widget.onClear,
        closeButtonLabel: widget.closeButtonLabel,
      ),
    );
  }
}
