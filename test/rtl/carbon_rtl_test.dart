// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.
//
// RTL / bidi coverage (#221): a crash-guard sweep pumping component
// families under Directionality(rtl), behavioral locks for the
// direction-aware interactions (slider arrows and pointer mapping, menu
// submenu side and arrows, overflow-menu logical alignment, pagination
// chevrons), and RTL smoke goldens whose diffs enumerate mirrored
// geometry per family. The golden direction axis itself lives in
// test/support/golden.dart (`directions:`).

import 'package:carbide/carbide.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/golden.dart';

Widget _rtlHost(Widget child) => Directionality(
  textDirection: TextDirection.rtl,
  child: CarbonTheme(
    data: CarbonThemeData.white,
    child: Align(alignment: AlignmentDirectional.topStart, child: child),
  ),
);

void main() {
  group('RTL crash guard', () {
    // One representative per family; pumped under Directionality(rtl) and
    // asserted to build and lay out without exceptions.
    final Map<String, WidgetBuilder> specimens = <String, WidgetBuilder>{
      'button': (_) =>
          CarbonButton(label: 'Save', icon: CarbonIcons.add, onPressed: () {}),
      'text input': (_) => const SizedBox(
        width: 280,
        child: CarbonTextInput(
          labelText: 'Email',
          placeholder: 'you@example.com',
          helperText: 'Helper',
        ),
      ),
      'search': (_) =>
          const SizedBox(width: 280, child: CarbonSearch(placeholder: 'Find')),
      'checkbox': (_) => const CarbonCheckbox(label: 'Subscribe', value: true),
      'toggle': (_) =>
          const CarbonToggle(labelText: 'Notifications', toggled: true),
      'slider': (_) => SizedBox(
        width: 320,
        child: CarbonSlider(
          labelText: 'Amount',
          value: 60,
          min: 0,
          max: 100,
          onChanged: (num _) {},
        ),
      ),
      'tag': (_) => const CarbonTag(label: 'Beta', type: CarbonTagType.blue),
      'accordion': (_) => const SizedBox(
        width: 320,
        child: CarbonAccordion(
          children: <Widget>[
            CarbonAccordionItem(
              title: 'Section',
              initiallyOpen: true,
              child: Text('Body'),
            ),
          ],
        ),
      ),
      'breadcrumb': (_) => CarbonBreadcrumb(
        items: <CarbonBreadcrumbItem>[
          CarbonBreadcrumbItem(label: 'Home', onPressed: () {}),
          const CarbonBreadcrumbItem(label: 'Reports', isCurrentPage: true),
        ],
      ),
      'tabs (contained)': (_) => const SizedBox(
        width: 400,
        child: CarbonTabs(
          variant: CarbonTabVariant.contained,
          tabs: <CarbonTab>[
            CarbonTab(label: 'One'),
            CarbonTab(label: 'Two'),
          ],
          panels: <Widget>[Text('1'), Text('2')],
        ),
      ),
      'content switcher': (_) => CarbonContentSwitcher(
        selectedIndex: 1,
        onChanged: (int _) {},
        switches: const <CarbonSwitch>[
          CarbonSwitch(text: 'Day'),
          CarbonSwitch(text: 'Week'),
        ],
      ),
      'notification': (_) => SizedBox(
        width: 360,
        child: CarbonInlineNotification(
          kind: CarbonNotificationKind.success,
          title: 'Saved',
          subtitle: 'All changes stored.',
          onClose: () {},
        ),
      ),
      'progress bar': (_) => const SizedBox(
        width: 280,
        child: CarbonProgressBar(label: 'Uploading', value: 64),
      ),
      'progress indicator': (_) => const SizedBox(
        width: 480,
        child: CarbonProgressIndicator(
          currentIndex: 1,
          steps: <CarbonProgressStep>[
            CarbonProgressStep(label: 'Account'),
            CarbonProgressStep(label: 'Profile'),
            CarbonProgressStep(label: 'Confirm'),
          ],
        ),
      ),
      'pagination nav': (_) =>
          CarbonPaginationNav(totalItems: 8, page: 2, onChange: (int _) {}),
      'tree view': (_) => const SizedBox(
        width: 260,
        child: CarbonTreeView(
          label: 'Files',
          selectedId: 'a',
          initiallyExpandedIds: <Object>{'src'},
          nodes: <CarbonTreeNode>[
            CarbonTreeNode(
              id: 'src',
              label: 'src',
              children: <CarbonTreeNode>[
                CarbonTreeNode(id: 'a', label: 'main.dart'),
              ],
            ),
          ],
        ),
      ),
      'data table': (_) => const SizedBox(
        width: 420,
        child: CarbonDataTable(
          selection: CarbonTableSelection.multi,
          selectedRows: <int>{0},
          columns: <CarbonTableColumn>[
            CarbonTableColumn(title: 'Name'),
            CarbonTableColumn(title: 'Role'),
          ],
          rows: <CarbonTableRow>[
            CarbonTableRow(cells: <Widget>[Text('Ada'), Text('Admin')]),
            CarbonTableRow(cells: <Widget>[Text('Grace'), Text('Editor')]),
          ],
        ),
      ),
      'structured list': (_) => const SizedBox(
        width: 400,
        child: CarbonStructuredList(
          headers: <String>['Name', 'Type'],
          selectedIndex: 0,
          rows: <CarbonStructuredListRow>[
            CarbonStructuredListRow(
              cells: <Widget>[Text('Load'), Text('Routine')],
            ),
          ],
        ),
      ),
      'side nav': (_) => SizedBox(
        width: 256,
        height: 300,
        child: CarbonSideNav(
          expanded: true,
          items: <Widget>[
            CarbonSideNavLink(
              label: 'Overview',
              icon: CarbonIcons.dashboard,
              current: true,
              onPressed: () {},
            ),
            CarbonSideNavLink(
              label: 'Reports',
              icon: CarbonIcons.document,
              onPressed: () {},
            ),
          ],
        ),
      ),
    };

    for (final MapEntry<String, WidgetBuilder> entry in specimens.entries) {
      testWidgets('${entry.key} builds under Directionality(rtl)', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(_rtlHost(Builder(builder: entry.value)));
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('RTL behavior', () {
    testWidgets('slider: horizontal arrows follow the visual direction and '
        'the pointer maps mirrored', (WidgetTester tester) async {
      num value = 50;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) => _rtlHost(
            SizedBox(
              width: 400,
              child: CarbonSlider(
                labelText: 'Amount',
                value: value,
                min: 0,
                max: 100,
                onChanged: (num v) => setState(() => value = v),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Tapping the track centre keeps the value at 50 and focuses the
      // thumb, so the arrow keys below reach the thumb's key handler.
      final Finder track = find.byType(GestureDetector).first;
      await tester.tap(track);
      await tester.pump();
      expect(value, 50);
      // ArrowLeft increases in RTL (visually forward).
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(value, 51);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(value, 50);

      // A tap near the physical LEFT of the track maps to a HIGH value.
      final Rect rect = tester.getRect(track);
      await tester.tapAt(Offset(rect.left + 8, rect.center.dy));
      await tester.pump();
      expect(value, greaterThan(90));
    });

    testWidgets('menu: the submenu opens toward the start side and the '
        'arrows flip', (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.rtl,
          child: CarbonTheme(
            data: CarbonThemeData.white,
            child: Overlay(
              initialEntries: <OverlayEntry>[
                OverlayEntry(
                  builder: (BuildContext context) => Center(
                    child: SizedBox(
                      width: 220,
                      child: CarbonMenu(
                        children: const <Widget>[
                          CarbonMenuItem(
                            label: 'Share',
                            submenu: <Widget>[
                              CarbonMenuItem(label: 'Copy link'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      // Activating the parent item opens its submenu.
      await tester.tap(find.text('Share'));
      await tester.pump();
      expect(find.text('Copy link'), findsOneWidget);

      // The submenu sits on the physical LEFT of the parent menu.
      final double submenuRight = tester.getTopRight(find.text('Copy link')).dx;
      final double parentLeft = tester.getTopLeft(find.text('Share')).dx;
      expect(submenuRight, lessThanOrEqualTo(parentLeft + 1));

      // ArrowRight is the RTL collapse key; it closes the submenu and
      // returns focus to the parent item, where ArrowLeft re-expands.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(find.text('Copy link'), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(find.text('Copy link'), findsOneWidget);
    });

    testWidgets('overflow menu: logical end alignment resolves to the '
        'physical left in RTL', (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.rtl,
          child: CarbonTheme(
            data: CarbonThemeData.white,
            child: Overlay(
              initialEntries: <OverlayEntry>[
                OverlayEntry(
                  builder: (BuildContext context) => const Center(
                    child: CarbonOverflowMenu(
                      items: <Widget>[CarbonMenuItem(label: 'Edit')],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byType(CarbonOverflowMenu));
      await tester.pump();

      // menuAlignment: end (the default) means the menu's END edge lines
      // up with the trigger's END edge — the physical left in RTL.
      final double menuLeft = tester.getTopLeft(find.byType(CarbonMenu)).dx;
      final double triggerLeft = tester
          .getTopLeft(find.byType(CarbonOverflowMenu))
          .dx;
      expect((menuLeft - triggerLeft).abs(), lessThanOrEqualTo(1));
    });

    testWidgets('pagination nav: the previous/next carets flip', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _rtlHost(
          CarbonPaginationNav(totalItems: 5, page: 2, onChange: (int _) {}),
        ),
      );
      await tester.pump();

      CarbonIconData iconOf(String label) => tester
          .widget<CarbonIcon>(
            find.descendant(
              of: find.bySemanticsLabel(label),
              matching: find.byType(CarbonIcon),
            ),
          )
          .icon;
      expect(iconOf('Previous page'), CarbonIcons.caretRight);
      expect(iconOf('Next page'), CarbonIcons.caretLeft);
    });
  });

  group('RTL smoke goldens', () {
    testWidgets('mirrored component families', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'rtl_smoke',
        containsText: true,
        size: const Size(560, 560),
        directions: const <TextDirection>{TextDirection.rtl},
        // Settles the progress-bar fill tween and the tree-view expansion
        // (no infinite animations on this canvas).
        afterPump: (WidgetTester tester) async {
          await tester.pumpAndSettle();
        },
        builder: (BuildContext context) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  CarbonButton(
                    label: 'Save',
                    icon: CarbonIcons.add,
                    onPressed: () {},
                  ),
                  const SizedBox(width: 16),
                  CarbonDismissibleTag(
                    label: 'Beta',
                    type: CarbonTagType.blue,
                    onClose: () {},
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const SizedBox(
                width: 288,
                child: CarbonTextInput(
                  labelText: 'Email',
                  placeholder: 'you@example.com',
                  helperText: 'Helper text',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 320,
                child: CarbonSlider(
                  labelText: 'Amount',
                  value: 75,
                  min: 0,
                  max: 100,
                  onChanged: (num _) {},
                ),
              ),
              const SizedBox(height: 16),
              const SizedBox(
                width: 288,
                child: CarbonProgressBar(label: 'Uploading', value: 64),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(
                    width: 220,
                    child: CarbonTreeView(
                      label: 'Files',
                      selectedId: 'a',
                      initiallyExpandedIds: <Object>{'src'},
                      nodes: <CarbonTreeNode>[
                        CarbonTreeNode(
                          id: 'src',
                          label: 'src',
                          children: <CarbonTreeNode>[
                            CarbonTreeNode(id: 'a', label: 'main.dart'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 240,
                    height: 120,
                    child: CarbonSideNav(
                      expanded: true,
                      items: <Widget>[
                        CarbonSideNavLink(
                          label: 'Overview',
                          icon: CarbonIcons.dashboard,
                          current: true,
                          onPressed: () {},
                        ),
                        CarbonSideNavLink(
                          label: 'Reports',
                          icon: CarbonIcons.document,
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const SizedBox(
                width: 480,
                child: CarbonDataTable(
                  selection: CarbonTableSelection.multi,
                  selectedRows: <int>{0},
                  columns: <CarbonTableColumn>[
                    CarbonTableColumn(title: 'Name'),
                    CarbonTableColumn(title: 'Role'),
                  ],
                  rows: <CarbonTableRow>[
                    CarbonTableRow(cells: <Widget>[Text('Ada'), Text('Admin')]),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });

    testWidgets('open popups: list box and popover caret', (
      WidgetTester tester,
    ) async {
      await expectThemeGoldens(
        tester,
        name: 'rtl_popups',
        containsText: true,
        size: const Size(620, 320),
        directions: const <TextDirection>{TextDirection.rtl},
        builder: (BuildContext context) => Overlay(
          initialEntries: <OverlayEntry>[
            OverlayEntry(
              builder: (BuildContext context) => Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      width: 180,
                      child: CarbonDropdown<String>(
                        titleText: 'Colour',
                        selectedItem: 'cyan',
                        onChanged: (String _) {},
                        items: const <CarbonDropdownItem<String>>[
                          CarbonDropdownItem<String>(
                            value: 'cyan',
                            label: 'Cyan',
                          ),
                          CarbonDropdownItem<String>(
                            value: 'teal',
                            label: 'Teal',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48),
                    CarbonPopover(
                      open: true,
                      align: CarbonPopoverAlignment.bottomStart,
                      content: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Popover'),
                      ),
                      child: CarbonButton(
                        label: 'Anchor',
                        size: CarbonButtonSize.sm,
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        afterPump: (WidgetTester tester) async {
          await tester.tap(find.text('Cyan').first);
          await tester.pumpAndSettle();
        },
      );
    });
  });
}
