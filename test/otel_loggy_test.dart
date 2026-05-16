// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:loggy/loggy.dart'
    show LogOptions, Loggy, logDebug, logError, logInfo, logWarning;
import 'package:loggy/loggy.dart' as loggy_lib;
import 'package:otel_loggy/otel_loggy.dart';
import 'package:test/test.dart';

class _MemoryLogExporter implements LogRecordExporter {
  final List<LogRecord> records = [];
  bool _shutdown = false;

  @override
  Future<ExportResult> export(List<LogRecord> r) async {
    if (_shutdown) return ExportResult.failure;
    records.addAll(r);
    return ExportResult.success;
  }

  @override
  Future<void> forceFlush() async {}

  @override
  Future<void> shutdown() async {
    _shutdown = true;
  }
}

void main() {
  group('OTelLoggyPrinter', () {
    late _MemoryLogExporter exporter;

    setUp(() async {
      await OTel.reset();
      exporter = _MemoryLogExporter();
      await OTel.initialize(
        serviceName: 'otel_loggy-test',
        detectPlatformResources: false,
        logRecordProcessor: SimpleLogRecordProcessor(exporter),
      );
      Loggy.initLoggy(
        logPrinter: const OTelLoggyPrinter(),
        logOptions: const LogOptions(loggy_lib.LogLevel.all),
      );
    });

    tearDown(() async {
      await OTel.shutdown();
      await OTel.reset();
    });

    test('mirrors logInfo() into the OTel pipeline', () async {
      logInfo('user signed in');
      await OTel.loggerProvider().forceFlush();
      expect(exporter.records, hasLength(1));
      final rec = exporter.records.first;
      expect(rec.body.toString(), contains('user signed in'));
      expect(rec.severityNumber, Severity.INFO);
    });

    test('maps levels: debug, info, warning, error', () async {
      logDebug('d');
      logInfo('i');
      logWarning('w');
      logError('e');
      await OTel.loggerProvider().forceFlush();
      final sevs = exporter.records.map((r) => r.severityNumber).toSet();
      expect(
        sevs,
        containsAll(<Severity>[
          Severity.DEBUG,
          Severity.INFO,
          Severity.WARN,
          Severity.ERROR,
        ]),
      );
    });

    test('records exception attributes on logError with error+stack', () async {
      try {
        throw StateError('boom');
      } catch (e, st) {
        logError('caught it', e, st);
      }
      await OTel.loggerProvider().forceFlush();
      expect(exporter.records, isNotEmpty);
      final rec = exporter.records.last;
      final attrMap = {
        for (final a in rec.attributes!.toList()) a.key: a.value,
      };
      expect(attrMap['exception.type'], 'StateError');
      expect(attrMap['exception.message'], contains('boom'));
    });

    test('respects zone-scoped suppression', () async {
      runWithoutLoggyInstrumentation(() {
        logInfo('should not appear');
      });
      await OTel.loggerProvider().forceFlush();
      expect(exporter.records, isEmpty);
    });
  });
}
