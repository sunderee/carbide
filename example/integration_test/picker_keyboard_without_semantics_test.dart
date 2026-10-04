// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the
// Apache License, Version 2.0. See the LICENSE file in the project root.

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'picker_keyboard_contract_test.dart' as contract;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized().framePolicy =
      LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  contract.testSharedEditingHostPickerPolicy();
}
