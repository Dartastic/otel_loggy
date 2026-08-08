// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

// Both the OTel SDK and loggy define a `LogLevel`; hide the SDK's.
import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart'
    hide LogLevel;
import 'package:loggy/loggy.dart';
import 'package:otel_loggy/otel_loggy.dart';

Future<void> main() async {
  // Initialize the OTel SDK (exports OTLP/HTTP to localhost:4318 by
  // default; configure via OTEL_EXPORTER_OTLP_* environment variables).
  await OTel.initialize(serviceName: 'otel-loggy-example');

  // Install the bridge as Loggy's printer. Every Loggy record is
  // mirrored into the OTel logs pipeline, inheriting trace_id/span_id
  // from the active span.
  Loggy.initLoggy(
    logPrinter: const OTelLoggyPrinter(),
    logOptions: const LogOptions(LogLevel.all),
  );

  logInfo('user signed in');

  try {
    throw StateError('out of stock');
  } catch (e, st) {
    // exception.type / exception.message / exception.stacktrace
    // attributes are attached to the exported record.
    logError('checkout failed', e, st);
  }

  // Zone-scoped suppression: rendered by Loggy, not exported to OTel.
  runWithoutLoggyInstrumentation(() {
    logDebug('local-only noise');
  });

  await OTel.shutdown();
}
