// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'dart:async';

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:loggy/loggy.dart' as loggy_lib;

import 'otel_loggy_suppression.dart';

/// A `package:loggy` [LogPrinter] that mirrors every event into the
/// OpenTelemetry logs pipeline.
///
/// Install it as the active printer when initializing Loggy:
///
/// ```dart
/// Loggy.initLoggy(logPrinter: OTelLoggyPrinter());
/// logInfo('user signed in');
/// ```
///
/// Or combine it with Loggy's built-in pretty printer:
///
/// ```dart
/// Loggy.initLoggy(
///   logPrinter: const MultiPrinter([PrettyPrinter(), OTelLoggyPrinter()]),
/// );
/// ```
///
/// Each `LogRecord` becomes one OTel log record:
/// - `body` — `record.message.toString()`
/// - `severity_number` — mapped from `record.level` (debug → DEBUG,
///   info → INFO, warning → WARN, error → ERROR; everything else
///   falls back to INFO)
/// - `severity_text` — `record.level.name`
/// - `timestamp` — `record.time`
/// - attributes — `logger.name` (the loggy logger name) plus
///   `exception.*` when `record.error` / `record.stackTrace` are set
///
/// Records inherit `trace_id` / `span_id` from `Context.current` for
/// free via the OTel logger's `emit` path.
class OTelLoggyPrinter extends loggy_lib.LoggyPrinter {
  /// Creates the printer.
  ///
  /// - [loggerProvider] — defaults to `OTel.loggerProvider()` at
  ///   first use.
  /// - [loggerName] — instrumentation scope name. Defaults to
  ///   `package.loggy`.
  /// - [includeStackTrace] — when `false`, the stack trace is not
  ///   attached as an attribute. Defaults to `true`.
  const OTelLoggyPrinter({
    LoggerProvider? loggerProvider,
    String loggerName = 'package.loggy',
    bool includeStackTrace = true,
  })  : _provider = loggerProvider,
        _loggerName = loggerName,
        _includeStackTrace = includeStackTrace;

  final LoggerProvider? _provider;
  final String _loggerName;
  final bool _includeStackTrace;

  @override
  void onLog(loggy_lib.LogRecord record) {
    // Loggy delivers records via a StreamController; Stream listeners run
    // in the subscription zone (the zone where `Loggy.initLoggy` ran), not
    // the zone where `logInfo()` etc. were called. Re-enter the caller's
    // zone (captured on the record) so:
    //   - the zone-scoped suppression flag is visible
    //   - `Context.current` (and thus trace_id/span_id correlation) is
    //     the one the user expects.
    final zone = record.zone ?? Zone.current;
    zone.run(() => _emit(record));
  }

  void _emit(loggy_lib.LogRecord record) {
    if (loggyInstrumentationSuppressed()) return;
    final provider = _provider ?? OTel.loggerProvider();
    final logger = provider.getLogger(_loggerName);

    final attrs = <Attribute<Object>>[
      OTel.attributeString('logger.name', record.loggerName),
    ];
    if (record.error != null) {
      attrs
        ..add(OTel.attributeString(
          'exception.type',
          record.error.runtimeType.toString(),
        ))
        ..add(OTel.attributeString(
          'exception.message',
          record.error.toString(),
        ));
    }
    if (_includeStackTrace && record.stackTrace != null) {
      attrs.add(OTel.attributeString(
        'exception.stacktrace',
        record.stackTrace.toString(),
      ));
    }

    logger.emit(
      timeStamp: record.time,
      severityNumber: _mapLevel(record.level),
      severityText: record.level.name,
      body: record.message.toString(),
      attributes: OTel.attributes(attrs),
    );
  }
}

Severity _mapLevel(loggy_lib.LogLevel level) {
  if (level == loggy_lib.LogLevel.debug) return Severity.DEBUG;
  if (level == loggy_lib.LogLevel.info) return Severity.INFO;
  if (level == loggy_lib.LogLevel.warning) return Severity.WARN;
  if (level == loggy_lib.LogLevel.error) return Severity.ERROR;
  if (level == loggy_lib.LogLevel.all) return Severity.TRACE;
  if (level == loggy_lib.LogLevel.off) return Severity.UNSPECIFIED;
  return Severity.INFO;
}
