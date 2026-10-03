// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/src/utils/owned_listenable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'internal creation, unchanged updates and disposal attach only once',
    () {
      final List<String> events = <String>[];
      int calls = 0;
      final _Notifier internal = _Notifier('internal', events);
      final OwnedListenable<_Notifier> owner = OwnedListenable<_Notifier>(
        create: (_) => internal,
        onChanged: () => calls++,
      );
      expect(owner.value, same(internal));
      expect(owner.update(null), isFalse);
      internal.notifyListeners();
      expect(calls, 1);
      owner.dispose();
      expect(events, <String>[
        'internal:add',
        'internal:remove',
        'internal:dispose',
      ]);
      expect(internal.disposals, 1);
    },
  );

  test(
    'internal to external detaches and disposes before attaching the new one',
    () {
      final List<String> events = <String>[];
      final _Notifier internal = _Notifier('internal', events);
      final _Notifier external = _Notifier('external', events);
      final OwnedListenable<_Notifier> owner = OwnedListenable<_Notifier>(
        create: (_) => internal,
        onChanged: () {},
      );
      expect(owner.update(external), isTrue);
      expect(events, <String>[
        'internal:add',
        'internal:remove',
        'internal:dispose',
        'external:add',
      ]);
      owner.dispose();
      expect(external.disposals, 0);
      expect(external.listening, isFalse);
      external.dispose();
    },
  );

  test('external A to B detaches A and listens to B once', () {
    final List<String> events = <String>[];
    final _Notifier a = _Notifier('a', events);
    final _Notifier b = _Notifier('b', events);
    int calls = 0;
    final OwnedListenable<_Notifier> owner = OwnedListenable<_Notifier>(
      external: a,
      create: (_) => throw StateError('no internal object expected'),
      onChanged: () => calls++,
    );
    expect(owner.update(a), isFalse);
    expect(owner.update(b), isTrue);
    a.notifyListeners();
    expect(calls, 0);
    b.notifyListeners();
    expect(calls, 1);
    expect(events, <String>['a:add', 'a:remove', 'b:add']);
    owner.dispose();
    expect(a.disposals, 0);
    expect(b.disposals, 0);
    a.dispose();
    b.dispose();
  });

  test(
    'external to internal seeds from outgoing object after detaching it',
    () {
      final List<String> events = <String>[];
      final _Notifier external = _Notifier('external', events)..number = 42;
      final OwnedListenable<_Notifier> owner = OwnedListenable<_Notifier>(
        external: external,
        create: (_Notifier? previous) {
          expect(previous, same(external));
          expect(previous!.listening, isFalse);
          expect(previous.disposals, 0);
          return _Notifier('internal', events)..number = previous.number;
        },
        onChanged: () {},
      );
      expect(owner.update(null), isTrue);
      final _Notifier internal = owner.value;
      expect(internal.number, 42);
      expect(owner.update(null), isFalse);
      owner.dispose();
      expect(internal.disposals, 1);
      expect(external.disposals, 0);
      external.dispose();
    },
  );

  test('hundreds of transitions keep one subscription and dispose each owned object once', () {
    final List<String> events = <String>[];
    final List<_Notifier> created = <_Notifier>[];
    final _Notifier a = _Notifier('a', events);
    final _Notifier b = _Notifier('b', events);
    int calls = 0;
    final OwnedListenable<_Notifier> owner = OwnedListenable<_Notifier>(
      create: (_) {
        final _Notifier next = _Notifier('owned-${created.length}', events);
        created.add(next);
        return next;
      },
      onChanged: () => calls++,
    );
    for (int i = 0; i < 100; i++) {
      owner.update(a);
      owner.update(b);
      owner.update(null);
      owner.update(null);
      owner.value.notifyListeners();
      a.notifyListeners();
      b.notifyListeners();
      expect(calls, i + 1);
      expect(a.listening, isFalse);
      expect(b.listening, isFalse);
    }
    owner.dispose();
    expect(created, hasLength(101));
    expect(created.every((_Notifier n) => n.disposals == 1), isTrue);
    expect(a.disposals, 0);
    expect(b.disposals, 0);
    a.dispose();
    b.dispose();
  });

  test('an owner with no listener still preserves disposal ownership', () {
    final List<String> events = <String>[];
    final _Notifier external = _Notifier('external', events);
    final OwnedListenable<_Notifier> owner = OwnedListenable<_Notifier>(
      external: external,
      create: (_) => _Notifier('internal', events),
    );
    owner.update(null);
    final _Notifier internal = owner.value;
    owner.dispose();
    expect(events, <String>['internal:dispose']);
    expect(internal.disposals, 1);
    expect(external.disposals, 0);
    external.dispose();
  });

  test('disposed owners reject rebinding and duplicate disposal', () {
    final OwnedListenable<_Notifier> owner = OwnedListenable<_Notifier>(
      create: (_) => _Notifier('internal', <String>[]),
    );
    owner.dispose();
    expect(() => owner.update(null), throwsAssertionError);
    expect(owner.dispose, throwsAssertionError);
  });

  test(
    'text handoff preserves selection and IME composition, not initial text',
    () {
      final TextEditingController external = TextEditingController.fromValue(
        const TextEditingValue(
          text: 'composing',
          selection: TextSelection(baseOffset: 1, extentOffset: 4),
          composing: TextRange(start: 0, end: 5),
        ),
      );
      final OwnedTextEditingController owner = OwnedTextEditingController(
        external: external,
        initialText: 'initial',
      );
      owner.update(null);
      expect(owner.value.value, external.value);
      expect(owner.value, isNot(same(external)));
      owner.dispose();
      external.addListener(() {});
      external.dispose();
    },
  );

  test(
    'text initial value is seeded once and survives an unchanged update',
    () {
      final OwnedTextEditingController owner = OwnedTextEditingController(
        initialText: 'initial',
      );
      expect(owner.value.text, 'initial');
      owner.value.text = 'draft';
      owner.update(null);
      expect(owner.value.text, 'draft');
      owner.dispose();
    },
  );

  testWidgets('focused handoff queues focus until replacement attachment', (
    WidgetTester tester,
  ) async {
    final OwnedFocusNode owner = OwnedFocusNode();
    addTearDown(owner.dispose);
    final _FocusNode external = _FocusNode();
    addTearDown(external.dispose);
    await tester.pumpWidget(
      Focus(focusNode: owner.value, child: const SizedBox()),
    );
    owner.value.requestFocus();
    await tester.pump();
    expect(owner.value.hasPrimaryFocus, isTrue);
    owner.update(external);
    expect(owner.selectAllOnFocus, isFalse);
    await tester.pumpWidget(
      Focus(focusNode: owner.value, child: const SizedBox()),
    );
    await tester.pump();
    expect(external.hasPrimaryFocus, isTrue);
    expect(owner.selectAllOnFocus, isNull);
    owner.update(null);
    expect(owner.selectAllOnFocus, isFalse);
    await tester.pumpWidget(
      Focus(focusNode: owner.value, child: const SizedBox()),
    );
    await tester.pump();
    expect(owner.value.hasPrimaryFocus, isTrue);
    expect(owner.selectAllOnFocus, isNull);
    expect(external.listening, isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('unfocused or nonfocusable handoff does not steal focus', (
    WidgetTester tester,
  ) async {
    final FocusNode other = FocusNode();
    final FocusNode blocked = FocusNode(canRequestFocus: false);
    final OwnedFocusNode owner = OwnedFocusNode();
    addTearDown(other.dispose);
    addTearDown(blocked.dispose);
    addTearDown(owner.dispose);
    Widget host() => FocusScope(
      child: Column(
        children: <Widget>[
          Focus(focusNode: other, child: const SizedBox()),
          Focus(
            focusNode: owner.value,
            canRequestFocus: owner.value.canRequestFocus,
            child: const SizedBox(),
          ),
        ],
      ),
    );
    await tester.pumpWidget(host());
    other.requestFocus();
    await tester.pump();
    owner.update(blocked);
    await tester.pumpWidget(host());
    await tester.pump();
    expect(other.hasPrimaryFocus, isTrue);
    owner.update(null);
    await tester.pumpWidget(host());
    owner.value.requestFocus();
    await tester.pump();
    expect(owner.value.hasPrimaryFocus, isTrue);
    owner.update(blocked);
    await tester.pumpWidget(host());
    await tester.pump();
    expect(blocked.hasFocus, isFalse);
    await tester.pumpWidget(const SizedBox());
  });
}

class _Notifier extends ChangeNotifier {
  _Notifier(this.name, this.events);
  final String name;
  final List<String> events;
  int number = 0;
  int disposals = 0;
  bool get listening => hasListeners;

  @override
  void addListener(VoidCallback listener) {
    events.add('$name:add');
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    events.add('$name:remove');
    super.removeListener(listener);
  }

  @override
  void dispose() {
    events.add('$name:dispose');
    disposals++;
    super.dispose();
  }
}

class _FocusNode extends FocusNode {
  bool get listening => hasListeners;
}
