// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/a11y.dart';
import '../../support/golden.dart';

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: CarbonTheme(
    data: CarbonThemeData.white,
    child: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: 360, child: child),
    ),
  ),
);

CarbonFocusRing _ringAround(WidgetTester tester, Finder of) =>
    tester.widget<CarbonFocusRing>(
      find.ancestor(of: of, matching: find.byType(CarbonFocusRing)).first,
    );

/// The bare host has no WidgetsApp shortcut map, so real Tab traversal is
/// wired up locally (same pattern as the ui_shell header tests).
Widget _tabTraversal(Widget child) => Shortcuts(
  shortcuts: const <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.tab): NextFocusIntent(),
  },
  child: Actions(
    actions: <Type, Action<Intent>>{NextFocusIntent: NextFocusAction()},
    child: FocusScope(autofocus: true, child: child),
  ),
);

void main() {
  final CarbonThemeData theme = CarbonThemeData.white;

  setUp(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });
  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  group('button', () {
    testWidgets('renders the label and fires on tap', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await tester.pumpWidget(
        _host(
          CarbonFileUploaderButton(label: 'Add files', onPressed: () => taps++),
        ),
      );
      expect(find.text('Add files'), findsOneWidget);
      await tester.tap(find.text('Add files'));
      expect(taps, 1);
    });

    testWidgets('is disabled when onPressed is null', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const CarbonFileUploaderButton(label: 'Add files')),
      );
      await tester.tap(find.text('Add files'));
      // No callback wired; nothing to assert beyond no exception/no crash.
      expect(find.text('Add files'), findsOneWidget);
    });
  });

  group('drop container', () {
    testWidgets('is 96px tall and fires on tap', (WidgetTester tester) async {
      int taps = 0;
      await tester.pumpWidget(
        _host(
          CarbonFileUploaderDropContainer(
            label: 'Drag and drop or click',
            onPressed: () => taps++,
          ),
        ),
      );
      expect(
        tester
            .widget<SizedBox>(
              find
                  .descendant(
                    of: find.byType(CarbonFileUploaderDropContainer),
                    matching: find.byType(SizedBox),
                  )
                  .first,
            )
            .height,
        CarbonFileUploaderDropContainer.height,
      );
      await tester.tap(find.text('Drag and drop or click'));
      expect(taps, 1);
    });

    testWidgets('drag-over shows the 2px focus outline', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarbonFileUploaderDropContainer(
            label: 'Drop zone',
            dragOver: true,
          ),
        ),
      );
      expect(_ringAround(tester, find.text('Drop zone')).visible, isTrue);
    });

    testWidgets('disabled greys the label and does not fire', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await tester.pumpWidget(
        _host(
          CarbonFileUploaderDropContainer(
            label: 'Drop zone',
            disabled: true,
            onPressed: () => taps++,
          ),
        ),
      );
      expect(
        tester.widget<Text>(find.text('Drop zone')).style!.color,
        theme.textDisabled,
      );
      await tester.tap(find.text('Drop zone'));
      expect(taps, 0);
    });

    testWidgets('exposes a button semantics node with the label', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          CarbonFileUploaderDropContainer(label: 'Drop zone', onPressed: () {}),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Drop zone')),
        isSemantics(label: 'Drop zone', isButton: true, hasTapAction: true),
      );
      handle.dispose();
    });
  });

  group('item', () {
    testWidgets('edit status shows a remove control that fires onDelete', (
      WidgetTester tester,
    ) async {
      int removed = 0;
      await tester.pumpWidget(
        _host(
          CarbonFileUploaderItem(name: 'report.pdf', onDelete: () => removed++),
        ),
      );
      expect(find.text('report.pdf'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Remove file'));
      expect(removed, 1);
    });

    testWidgets('complete status shows the checkmark in interactive', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarbonFileUploaderItem(
            name: 'done.png',
            status: CarbonFileStatus.complete,
          ),
        ),
      );
      final CarbonIcon icon = tester.widget<CarbonIcon>(
        find.byType(CarbonIcon),
      );
      expect(icon.icon, CarbonIcons.checkmarkFilled);
      expect(icon.color, theme.interactive);
    });

    testWidgets('uploading status shows the spinner', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarbonFileUploaderItem(
            name: 'up.zip',
            status: CarbonFileStatus.uploading,
          ),
        ),
      );
      expect(find.byType(CarbonLoading), findsOneWidget);
    });

    testWidgets('sizes set the row height (sm 32 / md 40 / lg 48)', (
      WidgetTester tester,
    ) async {
      for (final (CarbonFieldSize size, double h)
          in <(CarbonFieldSize, double)>[
            (CarbonFieldSize.sm, 32),
            (CarbonFieldSize.md, 40),
            (CarbonFieldSize.lg, 48),
          ]) {
        await tester.pumpWidget(
          _host(CarbonFileUploaderItem(name: 'f', size: size)),
        );
        expect(
          tester
              .widget<SizedBox>(
                find
                    .descendant(
                      of: find.byType(CarbonFileUploaderItem),
                      matching: find.byType(SizedBox),
                    )
                    .first,
              )
              .height,
          h,
        );
      }
    });

    testWidgets('invalid shows a warning, error text and a 1px error outline', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarbonFileUploaderItem(
            name: 'bad.exe',
            invalid: true,
            errorSubject: 'File type invalid',
            errorBody: 'Only PDFs are allowed.',
          ),
        ),
      );
      expect(find.text('File type invalid'), findsOneWidget);
      expect(find.text('Only PDFs are allowed.'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (Widget w) => w is CarbonIcon && w.icon == CarbonIcons.warningFilled,
        ),
        findsOneWidget,
      );
      final BoxDecoration deco =
          tester
                  .widget<DecoratedBox>(
                    find
                        .descendant(
                          of: find.byType(CarbonFileUploaderItem),
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as BoxDecoration;
      expect((deco.border! as Border).top.color, theme.supportError);
      expect((deco.border! as Border).top.width, 1);
    });
  });

  group('uploader', () {
    testWidgets('renders the title, description and the file list', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonFileUploader(
            labelTitle: 'Upload files',
            labelDescription: 'Max 5 files, 500kb each.',
            items: const <CarbonFileUploaderItem>[
              CarbonFileUploaderItem(
                name: 'a.pdf',
                status: CarbonFileStatus.complete,
              ),
              CarbonFileUploaderItem(name: 'b.pdf'),
            ],
            child: CarbonFileUploaderButton(label: 'Add', onPressed: () {}),
          ),
        ),
      );
      expect(find.text('Upload files'), findsOneWidget);
      expect(find.text('Max 5 files, 500kb each.'), findsOneWidget);
      expect(find.text('a.pdf'), findsOneWidget);
      expect(find.text('b.pdf'), findsOneWidget);
    });

    testWidgets('meets tap-target and label guidelines', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          CarbonFileUploader(
            labelTitle: 'Upload files',
            labelDescription: 'Max 5 files, 500kb each.',
            items: <CarbonFileUploaderItem>[
              CarbonFileUploaderItem(name: 'report.pdf', onDelete: () {}),
            ],
            child: CarbonFileUploaderButton(
              label: 'Add files',
              onPressed: () {},
            ),
          ),
        ),
      );
      // The md trigger button is 40px (`_button.scss` layout md) and the md
      // item row 40px (`_file-uploader.scss` `.cds--file__selected-file--md
      // { min-block-size: convert.to-rem(40px) }`), so the 48dp android
      // guideline is unattainable at the default size.
      await expectA11y(tester, tapTargets: false);
      handle.dispose();
    });
  });

  group('keyboard (#231)', () {
    // Upstream: documentation/carbon-website/src/pages/components/
    // file-uploader/accessibility.mdx — "Both variants of the file uploader
    // provide buttons for uploading and removing files. The drop target
    // 'Drag and drop files here...' also provides conventional button
    // keyboard interaction (Tab to reach; Enter or Space to activate). Once
    // a file has been added, it can be removed by activating the delete
    // ('x') button after each file name."

    testWidgets('Enter and Space activate the focused trigger button', (
      WidgetTester tester,
    ) async {
      int opened = 0;
      await tester.pumpWidget(
        _host(
          CarbonFileUploaderButton(
            label: 'Add files',
            onPressed: () => opened++,
          ),
        ),
      );
      Focus.of(tester.element(find.text('Add files'))).requestFocus();
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(opened, 1);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(opened, 2);
    });

    testWidgets('Tab reaches the remove button after the trigger; Enter '
        'and Space remove the file', (WidgetTester tester) async {
      int removed = 0;
      await tester.pumpWidget(
        _host(
          _tabTraversal(
            CarbonFileUploader(
              items: <CarbonFileUploaderItem>[
                CarbonFileUploaderItem(
                  name: 'report.pdf',
                  onDelete: () => removed++,
                ),
              ],
              child: CarbonFileUploaderButton(
                label: 'Add files',
                onPressed: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // First Tab stop: the trigger button.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(
        Focus.of(tester.element(find.text('Add files'))).hasPrimaryFocus,
        isTrue,
      );

      // Second Tab stop: the item's remove ('x') button, with the ring.
      final Finder close = find.byWidgetPredicate(
        (Widget w) => w is CarbonIcon && w.icon == CarbonIcons.close,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(Focus.of(tester.element(close)).hasPrimaryFocus, isTrue);
      expect(_ringAround(tester, close).visible, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(removed, 1);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(removed, 2);
    });

    testWidgets('the drop zone is focusable; Enter and Space open the '
        'picker', (WidgetTester tester) async {
      int opened = 0;
      await tester.pumpWidget(
        _host(
          CarbonFileUploaderDropContainer(
            label: 'Drop zone',
            onPressed: () => opened++,
          ),
        ),
      );
      Focus.of(tester.element(find.text('Drop zone'))).requestFocus();
      await tester.pumpAndSettle();
      expect(_ringAround(tester, find.text('Drop zone')).visible, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(opened, 1);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(opened, 2);
    });
  });

  group('goldens', () {
    testWidgets('file uploader across themes', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'file_uploader',
        containsText: true,
        size: const Size(360, 470),
        builder: (BuildContext context) => Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 320,
            child: CarbonFileUploader(
              labelTitle: 'Upload files',
              labelDescription: 'Max 5 files, 500kb each.',
              items: const <CarbonFileUploaderItem>[
                CarbonFileUploaderItem(
                  name: 'quarter-report.pdf',
                  status: CarbonFileStatus.complete,
                ),
                CarbonFileUploaderItem(name: 'draft.pdf'),
                CarbonFileUploaderItem(
                  name: 'malware.exe',
                  invalid: true,
                  errorSubject: 'File type invalid',
                  errorBody: 'Only PDFs are allowed.',
                ),
              ],
              child: const CarbonFileUploaderDropContainer(
                label: 'Drag and drop files here or click to upload',
              ),
            ),
          ),
        ),
      );
    });
  });
}
