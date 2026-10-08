// Copyright 2026 Bizjak Tech OÜ
import 'package:carbide/carbide.dart';
import 'package:carbide_gallery/src/catalog.dart';
import 'package:carbide_gallery/src/demo_scaffold.dart';
import 'package:carbide_gallery/src/registry.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const List<String> _pages = <String>[
  'form',
  'button-set',
  'menu',
  'popover',
  'table-toolbar',
  'ui-shell',
  'layers-and-breakpoints',
  'fluid-pickers',
];
GalleryEntry _entry(String slug) =>
    allEntries(kCatalog).singleWhere((GalleryEntry e) => e.slug == slug);
Future<void> _open(
  WidgetTester tester,
  String slug, {
  double width = 360,
  CarbonThemeData? theme,
}) async {
  tester.view.physicalSize = Size(width, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    WidgetsApp(
      key: ValueKey<String>(slug),
      color: const Color(0xffffffff),
      onGenerateRoute: (_) => PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => CarbonTheme(
          data: theme ?? CarbonThemeData.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _entry(slug).builder(),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

Finder get _preview => find.byKey(kDemoPreviewKey);
Finder _inPreview(Finder finder) =>
    find.descendant(of: _preview, matching: finder);
Future<void> _knob(WidgetTester tester, String label) async {
  final Finder knob = find.byWidgetPredicate(
    (Widget w) => w is CarbonToggle && w.labelText == label,
  );
  await tester.ensureVisible(knob);
  await tester.tap(
    find.descendant(of: knob, matching: find.byType(CarbonInteraction)),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final String slug in _pages) {
    for (final double width in <double>[320, 1200]) {
      for (final CarbonThemeData theme in <CarbonThemeData>[
        CarbonThemeData.white,
        CarbonThemeData.gray10,
        CarbonThemeData.gray90,
        CarbonThemeData.gray100,
      ]) {
        testWidgets('$slug fits $width ${theme.background}', (
          WidgetTester tester,
        ) async {
          await _open(tester, slug, width: width, theme: theme);
          expect(tester.takeException(), isNull);
          final Rect preview = tester.getRect(_preview);
          expect(preview.left, greaterThanOrEqualTo(0));
          expect(preview.right, lessThanOrEqualTo(width));
          final DemoScaffold demo = tester.widget<DemoScaffold>(
            find.byType(DemoScaffold),
          );
          expect(demo.code, contains('class '));
          await tester.pumpWidget(const SizedBox.shrink());
        });
      }
    }
  }
  testWidgets('form edits survive fluid scope and respect disabled actions', (
    WidgetTester tester,
  ) async {
    await _open(tester, 'form');
    final Finder editor = _inPreview(find.byType(EditableText));
    await tester.enterText(editor, 'Morgan');
    await _knob(tester, 'Fluid form');
    expect(tester.widget<EditableText>(editor).controller.text, 'Morgan');
    final CarbonTextInput field = tester.widget<CarbonTextInput>(
      _inPreview(find.byType(CarbonTextInput)),
    );
    expect(
      CarbonFluidForm.of(
        tester.element(_inPreview(find.byType(CarbonField)).first),
      ),
      isTrue,
    );
    expect(field.controller!.text, 'Morgan');
    await _knob(tester, 'Disabled');
    final CarbonButton save = tester.widget<CarbonButton>(
      _inPreview(find.byType(CarbonButton)),
    );
    expect(save.onPressed, isNull);
    expect(tester.takeException(), isNull);
  });
  testWidgets('fluid picker knob changes the actual field chrome', (
    WidgetTester tester,
  ) async {
    await _open(tester, 'fluid-pickers');
    expect(
      tester
          .widgetList<CarbonField>(_inPreview(find.byType(CarbonField)))
          .every((CarbonField f) => f.fluid),
      isTrue,
    );
    await _knob(tester, 'Fluid pickers');
    expect(
      tester
          .widgetList<CarbonField>(_inPreview(find.byType(CarbonField)))
          .every((CarbonField f) => !f.fluid),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('menu handles arrow keys, selection and action callbacks', (
    WidgetTester tester,
  ) async {
    await _open(tester, 'menu');
    await tester.tap(find.text('Open report'));
    await tester.pump();
    expect(find.text('Action: Opened report'), findsOneWidget);
    await tester.tap(find.text('Show archived'));
    await tester.pump();
    expect(
      tester
          .widget<CarbonMenuItemSelectable>(
            find.byType(CarbonMenuItemSelectable),
          )
          .selected,
      isTrue,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(
      tester
          .widget<CarbonMenuItemRadioGroup<String>>(
            find.byType(CarbonMenuItemRadioGroup<String>),
          )
          .value,
      'comfortable',
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('popover applies and dismisses with Escape', (
    WidgetTester tester,
  ) async {
    await _open(tester, 'popover');
    await tester.tap(find.text('Report settings'));
    await tester.pumpAndSettle();
    expect(find.text('Apply settings'), findsOneWidget);
    await tester.tap(find.text('Apply settings'));
    await tester.pumpAndSettle();
    expect(find.text('Applied: 1'), findsOneWidget);
    Focus.of(tester.element(find.text('Report settings'))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Apply settings'), findsNothing);
  });
  testWidgets(
    'shell skips to main and narrow navigation closes on selection and Escape',
    (WidgetTester tester) async {
      await _open(tester, 'ui-shell');
      final CarbonShellContent content = tester.widget<CarbonShellContent>(
        find.byType(CarbonShellContent),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(find.text('Skip to example content'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(content.focusNode!.hasPrimaryFocus, isTrue);
      await tester.tap(find.bySemanticsLabel('Example navigation'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CarbonHeaderMenuButton>(find.byType(CarbonHeaderMenuButton))
            .isOpen,
        isTrue,
      );
      await tester.tap(find.text('Reports').last);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CarbonHeaderMenuButton>(find.byType(CarbonHeaderMenuButton))
            .isOpen,
        isFalse,
      );
      await tester.tap(find.bySemanticsLabel('Example navigation'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CarbonHeaderMenuButton>(find.byType(CarbonHeaderMenuButton))
            .isOpen,
        isFalse,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'range slider copies both controlled values and table demonstrates empty/sticky/batch states',
    (WidgetTester tester) async {
      await _open(tester, 'slider');
      await _knob(tester, 'Two handles');
      expect(
        tester
            .widget<CarbonSlider>(_inPreview(find.byType(CarbonSlider)))
            .upperValue,
        80,
      );
      expect(
        tester.widget<DemoScaffold>(find.byType(DemoScaffold)).code,
        contains('num _upper = 80'),
      );
      await _open(tester, 'data-table', width: 1200);
      await _knob(tester, 'Sticky header');
      expect(
        tester.widget<CarbonDataTable>(find.byType(CarbonDataTable)).rows,
        hasLength(20),
      );
      await _knob(tester, 'Empty');
      expect(
        tester.widget<CarbonDataTable>(find.byType(CarbonDataTable)).rows,
        isEmpty,
      );
      expect(
        find.text('No load balancers. Add one to get started.'),
        findsOneWidget,
      );
      await _knob(tester, 'Empty');
      final CarbonDataTable table = tester.widget<CarbonDataTable>(
        find.byType(CarbonDataTable),
      );
      table.onSelectedRowIdsChanged!(<Object>{'Load balancer 1'});
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Export selected'));
      await tester.tap(find.text('Export selected'));
      await tester.pump();
      expect(find.text('Exports: 1'), findsOneWidget);
    },
  );
}
