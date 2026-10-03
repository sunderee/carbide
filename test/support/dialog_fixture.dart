// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Flutter web compilation scopes sources to this package's test directory.
// The gallery keeps the equivalent fixture inside its integration_test root.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';

/// The independently tested overlay contracts.
enum DialogKind { modal, dialog, nonModalDialog }

/// A focus traversal host matching the native web test fixture.
Widget dialogTestApp({
  required GlobalKey<DialogFixtureState> fixtureKey,
  required DialogKind kind,
  bool danger = false,
  bool passive = false,
  CarbonThemeData? theme,
  TextDirection direction = TextDirection.ltr,
}) => WidgetsApp(
  color: const Color(0xffffffff),
  builder: (BuildContext context, Widget? child) => Navigator(
    // Bound this test page to its Flutter view, including on web. The
    // assertions concern the background controls surrounding the overlay.
    routeTraversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
    onGenerateRoute: (RouteSettings settings) => PageRouteBuilder<void>(
      settings: settings,
      pageBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) => Directionality(
            textDirection: direction,
            child: CarbonTheme(
              data: theme ?? CarbonThemeData.white,
              child: DialogFixture(
                key: fixtureKey,
                kind: kind,
                danger: danger,
                passive: passive,
              ),
            ),
          ),
    ),
  ),
);

/// Background controls bracket the overlay; two controls occupy its body.
class DialogFixture extends StatefulWidget {
  const DialogFixture({
    required this.kind,
    super.key,
    this.danger = false,
    this.passive = false,
  });

  final DialogKind kind;
  final bool danger;
  final bool passive;

  @override
  State<DialogFixture> createState() => DialogFixtureState();
}

class DialogFixtureState extends State<DialogFixture> {
  final FocusNode before = FocusNode(debugLabel: 'Launcher');
  final FocusNode after = FocusNode(debugLabel: 'After');
  final FocusNode first = FocusNode(debugLabel: 'First inside');
  final FocusNode second = FocusNode(debugLabel: 'Second inside');
  bool open = false;
  bool? modalOverride;
  bool showLauncher = true;
  bool _launcherDisposed = false;
  int closes = 0;
  int outsidePresses = 0;
  int primaryPresses = 0;
  int insidePresses = 0;

  void setModal(bool modal) => setState(() => modalOverride = modal);

  void show() => setState(() => open = true);
  void hide() => setState(() => open = false);
  void close() => setState(() {
    closes++;
    open = false;
  });

  void removeLauncher() {
    setState(() => showLauncher = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_launcherDisposed) {
        before.dispose();
        _launcherDisposed = true;
      }
    });
  }

  @override
  void dispose() {
    if (!_launcherDisposed) before.dispose();
    after.dispose();
    first.dispose();
    second.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('Read the details before continuing.'),
        CarbonButton(
          label: 'First inside',
          focusNode: first,
          onPressed: () => insidePresses++,
        ),
        CarbonButton(
          label: 'Second inside',
          focusNode: second,
          onPressed: () => insidePresses++,
        ),
      ],
    );
    return Stack(
      children: <Widget>[
        Align(
          alignment: Alignment.topLeft,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (showLauncher)
                CarbonButton(
                  label: 'Launcher',
                  focusNode: before,
                  autofocus: true,
                  onPressed: show,
                ),
              CarbonButton(
                label: 'After',
                focusNode: after,
                onPressed: () => outsidePresses++,
              ),
            ],
          ),
        ),
        if (widget.kind == DialogKind.modal)
          CarbonModal(
            open: open,
            title: 'Review changes',
            onClose: close,
            danger: widget.danger,
            passiveModal: widget.passive,
            secondaryButton: CarbonModalAction(
              label: 'Cancel',
              onPressed: close,
            ),
            primaryButton: CarbonModalAction(
              label: widget.danger ? 'Delete' : 'Save',
              onPressed: () => primaryPresses++,
            ),
            child: body,
          )
        else
          CarbonDialog(
            open: open,
            modal: modalOverride ?? widget.kind == DialogKind.dialog,
            onRequestClose: close,
            children: <Widget>[
              CarbonDialogHeader(
                controls: CarbonDialogControls(
                  children: <Widget>[CarbonDialogCloseButton(onPressed: close)],
                ),
                children: const <Widget>[CarbonDialogTitle('Review changes')],
              ),
              CarbonDialogBody(child: body),
              if (!widget.passive)
                CarbonDialogFooter(
                  children: <Widget>[
                    CarbonButton(
                      label: 'Cancel',
                      kind: CarbonButtonKind.secondary,
                      size: CarbonButtonSize.xl,
                      autofocus: widget.danger,
                      onPressed: close,
                    ),
                    CarbonButton(
                      label: widget.danger ? 'Delete' : 'Save',
                      kind: widget.danger
                          ? CarbonButtonKind.danger
                          : CarbonButtonKind.primary,
                      size: CarbonButtonSize.xl,
                      onPressed: () => primaryPresses++,
                    ),
                  ],
                ),
            ],
          ),
      ],
    );
  }
}
