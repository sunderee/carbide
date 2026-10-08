// Copyright 2026 Bizjak Tech OÜ
import 'dart:js_interop';
import 'dart:ui' show ViewFocusDirection, ViewFocusEvent, ViewFocusState;

import 'package:carbide/carbide.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/failure_diagnostics.dart';

void main() {
  retainIntegrationFailureDetails(
    IntegrationTestWidgetsFlutterBinding.ensureInitialized(),
  );
  for (final CarbonThemeData theme in <CarbonThemeData>[
    CarbonThemeData.white,
    CarbonThemeData.gray10,
    CarbonThemeData.gray90,
    CarbonThemeData.gray100,
  ]) {
    testWidgets('popover preserves native trigger focus ${theme.background}', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      final FocusNode trigger = FocusNode();
      final FocusNode after = FocusNode();
      bool open = false;
      late StateSetter update;
      try {
        await tester.pumpWidget(
          WidgetsApp(
            color: const Color(0xffffffff),
            onGenerateRoute: (_) => PageRouteBuilder<void>(
              pageBuilder: (_, _, _) => CarbonTheme(
                data: theme,
                child: StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    update = setState;
                    return Center(
                      child: SizedBox(
                        width: 500,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            CarbonPopover(
                              open: open,
                              autoAlign: true,
                              onRequestClose: () =>
                                  setState(() => open = false),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  const Text('Apply these settings?'),
                                  CarbonButton(
                                    label: 'Apply settings',
                                    onPressed: () {},
                                  ),
                                ],
                              ),
                              child: CarbonButton(
                                label: 'Report settings',
                                focusNode: trigger,
                                onPressed: () {
                                  trigger.requestFocus();
                                  setState(() => open = !open);
                                },
                              ),
                            ),
                            CarbonButton(
                              label: 'After popover',
                              focusNode: after,
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
        await _settle(tester);
        tester.binding.handleViewFocusChanged(
          ViewFocusEvent(
            viewId: tester.view.viewId,
            state: ViewFocusState.focused,
            direction: ViewFocusDirection.undefined,
          ),
        );
        for (int cycle = 0; cycle < 3; cycle++) {
          trigger.requestFocus();
          _button('Report settings').focus();
          await _settle(tester);
          await tester.sendKeyEvent(
            LogicalKeyboardKey.enter,
            physicalKey: PhysicalKeyboardKey.enter,
          );
          await _settle(tester);
          expect(open, isTrue);
          expect(trigger.hasPrimaryFocus, isTrue);
          expect(_document.activeElement == _button('Report settings'), isTrue);
          expect(_pointHits(_button('Apply settings')), isTrue);
          await tester.sendKeyEvent(
            LogicalKeyboardKey.escape,
            physicalKey: PhysicalKeyboardKey.escape,
          );
          await _settle(tester);
          expect(open, isFalse);
          expect(trigger.hasPrimaryFocus, isTrue);
          expect(_document.activeElement == _button('Report settings'), isTrue);
        }
        update(() => open = true);
        await tester.pump();
        after.requestFocus();
        _button('After popover').focus();
        await _settle(tester);
        update(() => open = false);
        await _settle(tester);
        expect(after.hasPrimaryFocus, isTrue);
        expect(_document.activeElement == _button('After popover'), isTrue);
        await tester.pumpWidget(const SizedBox.shrink());
      } finally {
        semantics.dispose();
        trigger.dispose();
        after.dispose();
      }
    });
  }
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await Future<void>.delayed(const Duration(milliseconds: 80));
  await tester.pumpAndSettle();
}

_Element _button(String label) {
  final _NodeList nodes = _document.querySelectorAll(
    'flt-semantics[role="button"]',
  );
  for (int i = 0; i < nodes.length; i++) {
    final _Element element = nodes.item(i)!;
    if (element.getAttribute('aria-label') == label ||
        element.textContent?.trim() == label) {
      return element;
    }
  }
  throw StateError('Missing $label');
}

bool _pointHits(_Element target) {
  final _Rect rect = target.getBoundingClientRect();
  final _Element? hit = _document.elementFromPoint(
    rect.left + rect.width / 2,
    rect.top + rect.height / 2,
  );
  return hit != null && target.contains(hit);
}

@JS('document')
external _Document get _document;

extension type _Document(JSObject _) implements JSObject {
  external _NodeList querySelectorAll(String selector);
  external _Element? get activeElement;
  external _Element? elementFromPoint(double x, double y);
}

extension type _NodeList(JSObject _) implements JSObject {
  external int get length;
  external _Element? item(int index);
}

extension type _Element(JSObject _) implements JSObject {
  external String? get textContent;
  external String? getAttribute(String name);
  external void focus();
  external bool contains(_Element element);
  external _Rect getBoundingClientRect();
}

extension type _Rect(JSObject _) implements JSObject {
  external double get left;
  external double get top;
  external double get width;
  external double get height;
}
