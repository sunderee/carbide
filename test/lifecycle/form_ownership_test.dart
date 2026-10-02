// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/overlay_entries.dart';

typedef _FieldBuilder = Widget Function(
  TextEditingController? controller,
  FocusNode? focus,
);

final Map<String, _FieldBuilder> _textFields = <String, _FieldBuilder>{
  'text input': (TextEditingController? c, FocusNode? f) => CarbonTextInput(
    labelText: 'Field',
    controller: c,
    focusNode: f,
    placeholder: 'Hint',
  ),
  'password': (TextEditingController? c, FocusNode? f) => CarbonPasswordInput(
    labelText: 'Field',
    controller: c,
    focusNode: f,
    placeholder: 'Hint',
  ),
  'text area': (TextEditingController? c, FocusNode? f) => CarbonTextArea(
    labelText: 'Field',
    controller: c,
    focusNode: f,
    placeholder: 'Hint',
    enableCounter: true,
    maxCount: 20,
  ),
  'search': (TextEditingController? c, FocusNode? f) =>
      CarbonSearch(controller: c, focusNode: f, placeholder: 'Hint'),
  'time picker': (TextEditingController? c, FocusNode? f) => CarbonTimePicker(
    labelText: 'Field',
    controller: c,
    focusNode: f,
    placeholder: 'Hint',
  ),
  'expandable search': (TextEditingController? c, FocusNode? f) =>
      CarbonExpandableSearch(controller: c, placeholder: 'Hint'),
};

final Map<String, _FieldBuilder> _focusFields = <String, _FieldBuilder>{
  for (final MapEntry<String, _FieldBuilder> field in _textFields.entries)
    if (field.key != 'expandable search') field.key: field.value,
  'number input': (TextEditingController? c, FocusNode? f) => CarbonNumberInput(
    labelText: 'Field',
    focusNode: f,
    value: 2,
    onChanged: (_) {},
  ),
  'select': (TextEditingController? c, FocusNode? f) => CarbonSelect<String>(
    labelText: 'Field',
    focusNode: f,
    items: const <CarbonSelectItem<String>>[
      CarbonSelectItem<String>(value: 'a', label: 'Apple'),
    ],
    onChanged: (_) {},
  ),
  'dropdown': (TextEditingController? c, FocusNode? f) =>
      CarbonDropdown<String>(
        titleText: 'Field',
        focusNode: f,
        items: const <CarbonDropdownItem<String>>[
          CarbonDropdownItem<String>(value: 'a', label: 'Apple'),
        ],
        onChanged: (_) {},
      ),
  'combo box': (TextEditingController? c, FocusNode? f) =>
      CarbonComboBox<String>(
        titleText: 'Field',
        focusNode: f,
        items: const <CarbonComboBoxItem<String>>[
          CarbonComboBoxItem<String>(value: 'a', label: 'Apple'),
        ],
        onChanged: (_) {},
      ),
  'multi-select': (TextEditingController? c, FocusNode? f) =>
      CarbonMultiSelect<String>(
        titleText: 'Field',
        label: 'Choose',
        focusNode: f,
        items: const <CarbonMultiSelectItem<String>>[
          CarbonMultiSelectItem<String>(value: 'a', label: 'Apple'),
        ],
        onChanged: (_) {},
      ),
};

void main() {
  setUp(
    () => FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional,
  );
  tearDown(
    () => FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.automatic,
  );

  for (final MapEntry<String, _FieldBuilder> field in _textFields.entries) {
    testWidgets(
      '${field.key}: editable semantics stay enabled across rebinding',
      (WidgetTester tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();
        try {
          final TextEditingController a = TextEditingController(text: 'A');
          final TextEditingController b = TextEditingController(text: 'B');
          addTearDown(a.dispose);
          addTearDown(b.dispose);
          TextEditingController? external = a;
          late StateSetter update;
          await tester.pumpWidget(
            _host(
              StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  update = setState;
                  return field.value(external, null);
                },
              ),
            ),
          );
          if (field.key == 'expandable search') {
            await tester.tap(find.byType(CarbonInteraction).first);
            await tester.pumpAndSettle();
          }
          expect(
            tester.getSemantics(find.byType(EditableText).first),
            isSemantics(isEnabled: true),
          );
          update(() => external = b);
          await tester.pump();
          expect(
            tester.getSemantics(find.byType(EditableText).first),
            isSemantics(isEnabled: true),
          );
          update(() => external = null);
          await tester.pump();
          expect(
            tester.getSemantics(find.byType(EditableText).first),
            isSemantics(isEnabled: true),
          );
          await tester.pumpWidget(const SizedBox());
        } finally {
          handle.dispose();
        }
      },
    );
  }

  for (final MapEntry<String, _FieldBuilder> field in _textFields.entries) {
    testWidgets('${field.key}: all controller transitions preserve ownership', (
      WidgetTester tester,
    ) async {
      final _Controller a = _Controller(text: 'A');
      final _Controller b = _Controller(text: 'B');
      addTearDown(a.dispose);
      addTearDown(b.dispose);
      TextEditingController? external;
      late StateSetter update;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              update = setState;
              return field.value(external, null);
            },
          ),
        ),
      );
      if (field.key == 'expandable search') {
        await tester.tap(find.byType(CarbonInteraction).first);
        await tester.pumpAndSettle();
      }
      final TextEditingController initial = _editable(tester).controller;
      initial.value = const TextEditingValue(
        text: 'draft',
        selection: TextSelection(baseOffset: 1, extentOffset: 4),
      );
      await tester.pump();
      update(() => external = a);
      await tester.pump();
      expect(_editable(tester).controller, same(a));
      expect(() => initial.addListener(_noop), throwsFlutterError);
      update(() => external = b);
      await tester.pump();
      expect(_editable(tester).controller, same(b));
      expect(a.listening, isFalse);
      b.clear();
      await tester.pump();
      expect(find.text('Hint'), findsOneWidget);
      if (field.key == 'text area') expect(find.text('0/20'), findsOneWidget);
      a.text = 'obsolete';
      await tester.pump();
      expect(_editable(tester).controller.text, isEmpty);
      expect(find.text('Hint'), findsOneWidget);
      b.value = const TextEditingValue(
        text: 'kept',
        selection: TextSelection(baseOffset: 1, extentOffset: 3),
      );
      await tester.pump();
      final TextEditingValue outgoing = b.value;
      update(() => external = null);
      await tester.pump();
      final TextEditingController internal = _editable(tester).controller;
      expect(internal, isNot(same(b)));
      expect(internal.value, outgoing);
      expect(b.listening, isFalse);
      await tester.pumpWidget(const SizedBox());
      expect(() => internal.addListener(_noop), throwsFlutterError);
      expect(a.listening, isFalse);
      expect(b.listening, isFalse);
      a.addListener(_noop);
      a.removeListener(_noop);
      b.text = 'caller still owns me';
      expect(tester.takeException(), isNull);
    });
  }

  for (final MapEntry<String, _FieldBuilder> field in _textFields.entries) {
    testWidgets(
      '${field.key}: external mount and repeated swaps detach on teardown',
      (WidgetTester tester) async {
        final _Controller a = _Controller(text: 'A');
        final _Controller b = _Controller(text: 'B');
        addTearDown(a.dispose);
        addTearDown(b.dispose);
        TextEditingController? external = a;
        late StateSetter update;
        await tester.pumpWidget(
          _host(
            StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                update = setState;
                return field.value(external, null);
              },
            ),
          ),
        );
        if (field.key == 'expandable search') {
          await tester.tap(find.byType(CarbonInteraction).first);
          await tester.pumpAndSettle();
        }
        for (int i = 0; i < 12; i++) {
          final _Controller incoming = i.isEven ? a : b;
          update(() => external = incoming);
          await tester.pump();
          expect(_editable(tester).controller, same(incoming));
          update(() => external = null);
          await tester.pump();
          expect(_editable(tester).controller.text, incoming.text);
          expect(incoming.listening, isFalse);
          // An unchanged null-controller rebuild must keep the user's draft.
          final TextEditingController internal = _editable(tester).controller;
          internal.text = 'draft $i';
          update(() {});
          await tester.pump();
          expect(_editable(tester).controller, same(internal));
          expect(_editable(tester).controller.text, 'draft $i');
        }
        await tester.pumpWidget(const SizedBox());
        expect(a.listening, isFalse);
        expect(b.listening, isFalse);
        a.text = 'still alive';
        b.text = 'also alive';
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'expandable search swaps while collapsed and reads new text on blur',
    (WidgetTester tester) async {
      final _Controller a = _Controller(text: 'old query');
      final _Controller b = _Controller(text: 'new query');
      final FocusNode outside = FocusNode();
      addTearDown(a.dispose);
      addTearDown(b.dispose);
      addTearDown(outside.dispose);
      TextEditingController? external = a;
      late StateSetter update;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              update = setState;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  CarbonExpandableSearch(controller: external),
                  Focus(focusNode: outside, child: const Text('Outside')),
                ],
              );
            },
          ),
        ),
      );
      update(() => external = b);
      await tester.pump();
      expect(find.byType(EditableText), findsNothing);
      await tester.tap(find.byType(CarbonInteraction).first);
      await tester.pumpAndSettle();
      expect(_editable(tester).controller, same(b));
      expect(_editable(tester).focusNode.hasFocus, isTrue);
      // Old query becomes empty; the new non-empty one must prevent collapse.
      a.clear();
      outside.requestFocus();
      await tester.pumpAndSettle();
      expect(find.byType(EditableText), findsOneWidget);
      _editable(tester).focusNode.requestFocus();
      await tester.pump();
      b.clear();
      outside.requestFocus();
      await tester.pumpAndSettle();
      expect(find.byType(EditableText), findsNothing);
      await tester.tap(find.byType(CarbonInteraction).first);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(EditableText), findsNothing);
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        'CarbonExpandableSearch.button',
      );
      await tester.pumpWidget(const SizedBox());
      expect(a.listening, isFalse);
      expect(b.listening, isFalse);
    },
  );

  testWidgets('expandable search teardown cancels queued Escape focus return', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_host(const CarbonExpandableSearch()));
    await tester.tap(find.byType(CarbonInteraction).first);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    // Unmount before the post-frame callback can focus the magnifier.
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  for (final MapEntry<String, _FieldBuilder> field in _textFields.entries) {
    testWidgets(
      '${field.key}: live editor survives content and owner changes',
      (WidgetTester tester) async {
        // Rebinding continues editing, including on desktop where fresh focus
        // normally selects all text.
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        try {
          final TextEditingController controller = TextEditingController(
            text: 'draft',
          );
          final FocusNode focus = FocusNode();
          addTearDown(controller.dispose);
          addTearDown(focus.dispose);
          bool external = true;
          late StateSetter update;
          await tester.pumpWidget(
            _host(
              StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  update = setState;
                  return field.value(
                    external ? controller : null,
                    external ? focus : null,
                  );
                },
              ),
            ),
          );
          if (field.key == 'expandable search') {
            await tester.tap(find.byType(CarbonInteraction).first);
          } else {
            focus.requestFocus();
          }
          await tester.pumpAndSettle();
          final EditableTextState editor = tester.state<EditableTextState>(
            find.byType(EditableText).first,
          );
          controller.clear();
          await tester.pumpAndSettle();
          expect(
            tester.state<EditableTextState>(find.byType(EditableText).first),
            same(editor),
          );
          expect(_editable(tester).focusNode.hasFocus, isTrue);
          controller.value = const TextEditingValue(
            text: 'draft',
            selection: TextSelection(baseOffset: 1, extentOffset: 3),
            composing: TextRange(start: 1, end: 4),
          );
          await tester.pump();
          final TextEditingValue outgoing = controller.value;
          update(() => external = false);
          await tester.pumpAndSettle();
          expect(
            tester.state<EditableTextState>(find.byType(EditableText).first),
            same(editor),
          );
          expect(_editable(tester).focusNode.hasFocus, isTrue);
          expect(_editable(tester).controller.value, outgoing);
          final FocusNode internalFocus = _editable(tester).focusNode;
          internalFocus.unfocus();
          await tester.pumpAndSettle();
          internalFocus.requestFocus();
          await tester.pumpAndSettle();
          if (field.key != 'text area') {
            expect(
              _editable(tester).controller.selection,
              const TextSelection(baseOffset: 0, extentOffset: 5),
            );
          }
          await tester.pumpWidget(const SizedBox());
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );
  }

  for (final bool fluid in <bool>[false, true]) {
    for (final MapEntry<String, _FieldBuilder> field in _focusFields.entries) {
      if (<String>['select', 'dropdown', 'multi-select'].contains(field.key)) {
        continue;
      }
      testWidgets(
        '${field.key}: fluid=$fluid editor state survives focus changes',
        (WidgetTester tester) async {
          final FocusNode focus = FocusNode();
          final FocusNode outside = FocusNode();
          addTearDown(focus.dispose);
          addTearDown(outside.dispose);
          final Widget child = Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              field.value(null, focus),
              Focus(focusNode: outside, child: const Text('Outside')),
            ],
          );
          await tester.pumpWidget(
            _host(fluid ? CarbonFluidForm(child: child) : child),
          );
          final EditableTextState editor = tester.state<EditableTextState>(
            find.byType(EditableText).first,
          );
          focus.requestFocus();
          await tester.pumpAndSettle();
          expect(
            tester.state<EditableTextState>(find.byType(EditableText).first),
            same(editor),
          );
          outside.requestFocus();
          await tester.pumpAndSettle();
          expect(
            tester.state<EditableTextState>(find.byType(EditableText).first),
            same(editor),
          );
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }

  for (final MapEntry<String, _FieldBuilder> field in _focusFields.entries) {
    testWidgets('${field.key}: focus migrates and old nodes detach', (
      WidgetTester tester,
    ) async {
      final _FocusNode a = _FocusNode(debugLabel: 'caller A');
      final _FocusNode b = _FocusNode(debugLabel: 'caller B');
      addTearDown(a.dispose);
      addTearDown(b.dispose);
      FocusNode? external;
      late StateSetter update;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              update = setState;
              return field.value(null, external);
            },
          ),
        ),
      );
      final FocusNode initial = _fieldFocus(tester, field.key);
      initial.requestFocus();
      await tester.pumpAndSettle();
      expect(initial.hasFocus, isTrue);
      update(() => external = a);
      await tester.pumpAndSettle();
      expect(a.hasFocus, isTrue);
      expect(() => initial.addListener(_noop), throwsFlutterError);
      update(() => external = b);
      await tester.pumpAndSettle();
      expect(b.hasFocus, isTrue);
      expect(a.listening, isFalse);
      expect(_hasFocusRing(tester), isTrue);
      a.requestFocus();
      await tester.pump();
      expect(b.hasFocus, isTrue);
      update(() => external = null);
      await tester.pumpAndSettle();
      final FocusNode internal = _fieldFocus(tester, field.key);
      expect(internal.hasFocus, isTrue);
      expect(internal, isNot(same(b)));
      expect(b.listening, isFalse);
      internal.unfocus();
      await tester.pumpAndSettle();
      b.requestFocus();
      await tester.pump();
      expect(internal.hasFocus, isFalse);
      expect(_hasFocusRing(tester), isFalse);
      await tester.pumpWidget(const SizedBox());
      expect(() => internal.addListener(_noop), throwsFlutterError);
      a.addListener(_noop);
      a.removeListener(_noop);
      b.addListener(_noop);
      b.removeListener(_noop);
      expect(a.listening, isFalse);
      expect(b.listening, isFalse);
      expect(tester.takeException(), isNull);
    });
  }
}

EditableText _editable(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText).first);

FocusNode _fieldFocus(WidgetTester tester, String name) {
  if (<String>['select', 'dropdown', 'multi-select'].contains(name)) {
    final Finder chrome = name == 'select'
        ? find.byType(CarbonField).first
        : find.byType(CarbonListBox).first;
    return tester
        .widget<Focus>(
          find.ancestor(of: chrome, matching: find.byType(Focus)).first,
        )
        .focusNode!;
  }
  return _editable(tester).focusNode;
}

bool _hasFocusRing(WidgetTester tester) {
  if (find.byType(EditableText).evaluate().isNotEmpty) {
    return tester
        .widgetList<CarbonFocusRing>(
          find.ancestor(
            of: find.byType(EditableText).first,
            matching: find.byType(CarbonFocusRing),
          ),
        )
        .any((CarbonFocusRing ring) => ring.visible);
  }
  final Finder rings = find.byType(CarbonListBox).evaluate().isNotEmpty
      ? find.descendant(
          of: find.byType(CarbonListBox).first,
          matching: find.byType(CarbonFocusRing),
        )
      : find.byType(CarbonFocusRing);
  return tester
      .widgetList<CarbonFocusRing>(rings)
      .any((CarbonFocusRing ring) => ring.visible);
}

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: CarbonTheme(
    data: CarbonThemeData.white,
    child: Overlay(
      initialEntries: <OverlayEntry>[
        managedOverlayEntry(
          builder: (BuildContext context) =>
              Center(child: SizedBox(width: 360, child: child)),
        ),
      ],
    ),
  ),
);

void _noop() {}

class _Controller extends TextEditingController {
  _Controller({super.text});
  bool get listening => hasListeners;
}

class _FocusNode extends FocusNode {
  _FocusNode({super.debugLabel});
  bool get listening => hasListeners;
}
