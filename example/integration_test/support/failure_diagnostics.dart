// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the
// Apache License, Version 2.0. See the LICENSE file in the project root.

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/common.dart';
import 'package:integration_test/integration_test.dart';

// FlutterErrorDetails.toString() omits diagnostics in release builds. Keep the
// actual exception and stack in the driver's failure response in every mode.
void retainIntegrationFailureDetails(
  IntegrationTestWidgetsFlutterBinding binding,
) {
  final TestExceptionReporter previousReporter = reportTestException;
  reportTestException = (details, description) {
    previousReporter(details, description);
    binding.results[description] = Failure(
      description,
      '${details.exceptionAsString()}\n${details.stack ?? ''}',
    );
  };
}
