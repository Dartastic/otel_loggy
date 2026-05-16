# Changelog

## [0.1.0-beta.1-wip]

### Added

- `OTelLoggyPrinter` — a `package:loggy` `LoggyPrinter` that mirrors
  every record into the OpenTelemetry logs pipeline.
- Severity mapping (debug → DEBUG, info → INFO, warning → WARN,
  error → ERROR; all → TRACE; everything else → INFO).
- `logger.name` attribute on every record; `exception.type` /
  `exception.message` / `exception.stacktrace` when `record.error` /
  `record.stackTrace` are set.
- Zone-trap fix: the printer re-enters `record.zone` before emit so
  zone-scoped suppression works and the active span's
  `trace_id` / `span_id` are correlated correctly.
- `runWithoutLoggyInstrumentation()` zone helper.
