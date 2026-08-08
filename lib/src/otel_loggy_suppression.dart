// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'dart:async';

const Symbol _suppressKey = #otel_loggy_suppress;

/// Whether loggy→OTel mirroring is suppressed in the current [Zone].
///
/// `OTelLoggyPrinter` checks this before emitting; it returns `true`
/// inside [runWithoutLoggyInstrumentation] /
/// [runWithoutLoggyInstrumentationAsync] blocks.
bool loggyInstrumentationSuppressed() {
  return Zone.current[_suppressKey] == true;
}

/// Runs [body] with loggy→OTel mirroring suppressed.
///
/// Loggy still renders its own output; the records are simply not
/// exported to the OpenTelemetry logs pipeline.
T runWithoutLoggyInstrumentation<T>(T Function() body) {
  return runZoned(body, zoneValues: {_suppressKey: true});
}

/// Async variant of [runWithoutLoggyInstrumentation]: the suppression
/// flag stays set across `await` boundaries inside [body].
Future<T> runWithoutLoggyInstrumentationAsync<T>(
  Future<T> Function() body,
) {
  return runZoned(body, zoneValues: {_suppressKey: true});
}
