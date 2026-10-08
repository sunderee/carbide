// Copyright 2026 Bizjak Tech OÜ

import 'dart:js_interop';
import 'dart:ui' show ViewFocusDirection, ViewFocusEvent, ViewFocusState;

import 'package:carbide/carbide.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/failure_diagnostics.dart';

const String _code = 'first line\nsecond line\nthird line\nfourth line';

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
    for (final TextDirection direction in TextDirection.values) {
      testWidgets(
        'native copy and expand focus ${theme.background} $direction',
        (WidgetTester tester) async {
          final SemanticsHandle semantics = tester.ensureSemantics();
          final List<String> copied = <String>[];
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            (MethodCall call) async {
              if (call.method == 'Clipboard.setData') {
                copied.add(
                  (call.arguments as Map<dynamic, dynamic>)['text'] as String,
                );
              }
              return null;
            },
          );
          try {
            await tester.pumpWidget(
              WidgetsApp(
                color: const Color(0xffffffff),
                onGenerateRoute: (_) => PageRouteBuilder<void>(
                  pageBuilder: (_, _, _) => CarbonTheme(
                    data: theme,
                    child: Directionality(
                      textDirection: direction,
                      child: Center(
                        child: SizedBox(
                          width: 500,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              CarbonButton(label: 'Before', onPressed: () {}),
                              const SizedBox(
                                width: 500,
                                child: CarbonCodeSnippet(
                                  code: _code,
                                  type: CarbonCodeSnippetType.multi,
                                  maxCollapsedRows: 2,
                                  copyLabel: 'Copy contract',
                                ),
                              ),
                              const CarbonCodeSnippet(
                                key: ValueKey<String>('inline'),
                                code: 'inline code',
                                type: CarbonCodeSnippetType.inline,
                                copyLabel: 'Copy inline',
                              ),
                              CarbonButton(label: 'After', onPressed: () {}),
                            ],
                          ),
                        ),
                      ),
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
            expect(_button('Copy contract').getAttribute('tabindex'), '0');
            _button('Copy contract').focus();
            await _settle(tester);
            final Finder copyRing = find.descendant(
              of: find.byType(CarbonCopy),
              matching: find.byType(CarbonFocusRing),
            );
            expect(Focus.of(tester.element(copyRing)).hasPrimaryFocus, isTrue);
            expect(
              _pointHits(_button('Show more')),
              isTrue,
              reason:
                  'the focused copy tooltip must not intercept the expander',
            );
            await tester.sendKeyEvent(
              LogicalKeyboardKey.space,
              physicalKey: PhysicalKeyboardKey.space,
            );
            await _settle(tester);
            expect(copied, <String>[_code]);
            expect(_document.activeElement == _button('Copied!'), isTrue);
            expect(
              _pointHits(_button('Show more')),
              isTrue,
              reason: 'copy feedback must leave other pointer targets operable',
            );

            _button('Show more').focus();
            await _settle(tester);
            await tester.sendKeyEvent(
              LogicalKeyboardKey.enter,
              physicalKey: PhysicalKeyboardKey.enter,
            );
            await _settle(tester);
            expect(find.text('Show less'), findsOneWidget);
            expect(_document.activeElement == _button('Show less'), isTrue);
            await tester.sendKeyEvent(
              LogicalKeyboardKey.space,
              physicalKey: PhysicalKeyboardKey.space,
            );
            await _settle(tester);
            expect(find.text('Show more'), findsOneWidget);

            _button('Copy inline: inline code').focus();
            await _settle(tester);
            final Finder inlineRing = find.descendant(
              of: find.byKey(const ValueKey<String>('inline')),
              matching: find.byType(CarbonFocusRing),
            );
            expect(
              Focus.of(tester.element(inlineRing)).hasPrimaryFocus,
              isTrue,
            );
            await tester.sendKeyEvent(
              LogicalKeyboardKey.enter,
              physicalKey: PhysicalKeyboardKey.enter,
            );
            await _settle(tester);
            expect(copied, <String>[_code, 'inline code']);
            expect(
              _document.activeElement == _button('Copy inline: inline code'),
              isTrue,
            );
            await tester.pumpWidget(const SizedBox.shrink());
          } finally {
            semantics.dispose();
            tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
              SystemChannels.platform,
              null,
            );
          }
        },
      );
    }
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
