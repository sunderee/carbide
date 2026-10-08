// Copyright 2026 Bizjak Tech OÜ
// Licensed under the Apache License, Version 2.0; see LICENSE.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'support/freshness.dart';

void main() {
  const String commit = '44f90d8d6b24889af06cee1422ceb37f58e40bed';
  final Map<String, dynamic> pin = <String, dynamic>{
    'carbonCommit': commit,
    'carbonReactVersion': '1.118.0',
    'maxCaptureMinorLag': 1,
  };
  Map<String, dynamic> fixture() => <String, dynamic>{
    'referenceReview': <String, dynamic>{
      'carbonCommit': commit,
      'carbonReactVersion': '1.118.0',
      'reviewedAt': '2026-10-08',
    },
    'carbonReactVersion': '1.118.0',
    'captures': <dynamic>[
      <String, dynamic>{
        'carbonReactVersion': '1.118.0',
        'capturedAt': '2026-10-07',
        'versionBasis': 'Observed deployment version',
        'components': <String>['button'],
      },
      <String, dynamic>{
        'carbonReactVersion': '1.117.0',
        'capturedAt': '2026-10-02',
        'versionBasis': 'Retained versioned animation phase',
        'components': <String>['loading'],
      },
    ],
  };
  void verify(
    Map<String, dynamic> manifest, {
    Map<String, dynamic>? referencePin,
    String gitlink = commit,
  }) => verifyReferenceFreshness(
    pin: referencePin ?? pin,
    manifest: manifest,
    gitlink: gitlink,
    components: <String>{'button', 'loading'},
  );

  test('all batches are checked without a reference checkout', () {
    verify(fixture());
  });
  test('gitlink bump without a pin and reference review fails', () {
    expect(
      () => verify(
        fixture(),
        gitlink: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      ),
      throwsStateError,
    );
  });
  test('updating the pin alone cannot bless old references', () {
    final Map<String, dynamic> changed = <String, dynamic>{
      ...pin,
      'carbonCommit': 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
    };
    expect(
      () => verify(
        fixture(),
        referencePin: changed,
        gitlink: changed['carbonCommit'] as String,
      ),
      throwsStateError,
    );
  });
  test('a fresh newest batch cannot hide an older stale batch', () {
    final Map<String, dynamic> data = fixture();
    (data['captures'] as List<dynamic>).last['carbonReactVersion'] = '1.116.0';
    expect(() => verify(data), throwsStateError);
  });
  test('every capture requires a non-null version', () {
    final Map<String, dynamic> data = fixture();
    (data['captures'] as List<dynamic>).first['carbonReactVersion'] = null;
    expect(() => verify(data), throwsStateError);
  });
  test('missing and duplicate component provenance fail', () {
    final Map<String, dynamic> data = fixture();
    (data['captures'] as List<dynamic>).removeLast();
    expect(() => verify(data), throwsStateError);
    data['captures'] = <dynamic>[
      ...(fixture()['captures'] as List<dynamic>),
      (fixture()['captures'] as List<dynamic>).first,
    ];
    expect(() => verify(data), throwsStateError);
  });
  test('major changes, ahead-of-pin captures and unsupported windows fail', () {
    for (final String version in <String>['2.118.0', '1.119.0']) {
      final Map<String, dynamic> data = fixture();
      (data['captures'] as List<dynamic>).first['carbonReactVersion'] = version;
      expect(() => verify(data), throwsStateError);
    }
    expect(
      () => verify(
        fixture(),
        referencePin: <String, dynamic>{...pin, 'maxCaptureMinorLag': 2},
      ),
      throwsStateError,
    );
  });
  test('committed provenance survives a JSON round trip', () {
    verify(jsonDecode(jsonEncode(fixture())) as Map<String, dynamic>);
  });
}
