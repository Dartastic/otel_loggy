# Changelog

## [0.3.0-wip]

### Changed

- Requires `dartastic_opentelemetry_api >=1.0.0-rc.4 <1.0.0-rc.5`.
- **Breaking:** depends on `dartastic_opentelemetry_api` only, no
  longer on the SDK. The application chooses and initializes the
  OpenTelemetry SDK. Parameters and fields typed with SDK classes
  now use the API types (`APITracer`, `APISpan`, `APILogger`, ...);
  SDK instances are still accepted wherever an API type is expected.

## [0.2.0] - 2026-08-10

### Changed

- Attribute keys are now typed constants: `exception.type` /
  `exception.message` / `exception.stacktrace` come from the registry
  `ExceptionAttributes` enum and `logger.name` from the new
  `LoggySemantics` enum. No raw string attribute keys remain (the
  on-wire keys are unchanged).
- Dependency floors raised to `dartastic_opentelemetry ^1.1.0-beta.12` and
  `dartastic_opentelemetry_api ^1.0.0-rc.1`. The previous floors declared
  compatibility with API versions that predate the semconv enums this
  package uses and could not actually resolve-and-compile.
- `loggy` floor raised to `^2.0.2`: 2.0.0 lacks the `LoggyPrinter` base
  class and 2.0.1's `logError` cannot carry an error/stackTrace, so the
  declared 2.0.0 lower bound never compiled.
- `repository` URL corrected to the canonical `Dartastic` org casing so
  pub.dev repository verification succeeds.

### Added

- `example/otel_loggy_example.dart` showing initialization, exception
  logging, and zone-scoped suppression.

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
